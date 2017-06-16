use common::*;
use scrapers::{handle_href, handle_text};

extern crate hyper;

use std;
use std::thread;
use std::sync::mpsc;
use std::cell::Ref;
use std::io::Read;

use regex::Regex;

use hyper::client;
use hyper::client::response::Response;
use hyper::header::ContentLength;

use html5ever::parse_document;
use html5ever::{QualName, LocalName};
use html5ever::rcdom::{Document, Doctype, Text, Comment, Element, RcDom, Handle, Node, NodeEnum};
use html5ever::tendril::TendrilSink;

use url::Url;
use url::ParseError;


pub struct Scraper {
    tx: mpsc::Sender<RunnerMessage>,
    rx: mpsc::Receiver<RunnerResponse>
}

pub fn runner(rx: mpsc::Receiver<RunnerMessage>, tx: mpsc::Sender<RunnerResponse>) {
    let client = client::Client::new();
    loop {
        tx.send(RunnerResponse::Ready);
        let msg_result = rx.recv();
        if msg_result.is_ok() {
            let msg: RunnerMessage = msg_result.unwrap();
            match msg {
                RunnerMessage::Job(url) => handleJob(&client, url, &rx, &tx),
                RunnerMessage::NoJobReady => {
                    thread::sleep_ms(25);
                    tx.send(RunnerResponse::Ready).unwrap();
                }
            }
        }
    }
}

fn handleJob(client: &client::Client, url: Url, rx: &mpsc::Receiver<RunnerMessage>, tx: &mpsc::Sender<RunnerResponse>) {
    let mut res_result = client.get(url.as_str()).send();
    let mut res: Response;
    match res_result {
        Ok(v) => res = v,
        Err(_) => return,
    }
    if res.status.eq(&hyper::Ok) {

        let len_header = match res.headers.get() {
            Some(&ContentLength(l)) => l,
            _ => 0
        };
        let mut data: Vec<u8> = vec![];
        let mut buffer: [u8; 4096] = [0; 4096];

        tx.send(RunnerResponse::Downloading(0.0));

        loop {
            match res.read(&mut buffer) {
                Ok(0) => break,
                Ok(n) => {
                    data.extend(buffer.iter().take(n).cloned());
                    if len_header != 0 {
                        let v = data.len() as f32 / len_header as f32;
                        tx.send(RunnerResponse::Downloading(v));
                    }
                },
                Err(_) => return
            }
        }

        let s = String::from_utf8(data);
        match s {
            Ok(downloaded) => {
                match parse_document(RcDom::default(), Default::default()).from_utf8().read_from(&mut downloaded.as_bytes()) {
                    Ok(dom) => {
                        walk(url, dom.document, &tx);
                    },
                    Err(_) => {
                        handle_text(&tx, downloaded.as_str());
                    }
                }
            },
            Err(_) => {}
            
        }

    }
}

fn walk(baseUrl: Url, handle: Handle, tx: &mpsc::Sender<RunnerResponse>) {
    let node: Ref<Node> = handle.borrow();

    match node.node {
        NodeEnum::Element(ref name, _, ref attrs) => {
            if name.local == LocalName::from("a") {
                for attr in attrs.iter() {
                    if attr.name.local == LocalName::from("href") {
                        let link = format!("{}", attr.value);
                        handle_href(&baseUrl, tx, link.as_str());
                    }
                }
            }
        },
        NodeEnum::Text(ref text) => {
            handle_text(tx, text);
        },
        _ => {}
    }

    for child in node.children.iter() {
        walk(baseUrl.clone(), child.clone(), tx); 
    }
}

