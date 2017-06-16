use common::*;

use std::thread;
use std::sync::mpsc;
use std::cell::Ref;

use regex::Regex;

use hyper::client;
use hyper::client::response::Response;

use html5ever::parse_document;
use html5ever::{QualName, LocalName};
use html5ever::rcdom::{Document, Doctype, Text, Comment, Element, RcDom, Handle, Node, NodeEnum};
use html5ever::tendril::TendrilSink;

use url::Url;
use url::ParseError;

lazy_static! {
    pub static ref re: Regex = Regex::new(
        "(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|\"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\\\[\x01-\x09\x0b\x0c\x0e-\x7f])*\")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\\])"
        ).unwrap();
}

pub fn handle_href(baseUrl: &Url, tx: &mpsc::Sender<RunnerResponse>, href: &str) {
    let mut url = Url::parse(href);
    if url == Err(ParseError::RelativeUrlWithoutBase) {
        url = baseUrl.join(href);
    }

    let mut url = url.unwrap();
    url.set_fragment(Option::None);
    let scheme = url.scheme();
    if scheme == "http" || scheme == "https" {
        tx.send(RunnerResponse::Link(url.clone())).expect("wtf");
    }
    if scheme == "mailto" {
        let pth = String::from(url.path());
        if pth.contains('@') {
            let mut arr =  pth.split('@');
            let name = String::from(arr.next().unwrap());
            let domain = String::from(arr.next().unwrap());
            tx.send(RunnerResponse::Email(Email { name: name, domain: domain}));
        }
    }
}

pub fn handle_text(tx: &mpsc::Sender<RunnerResponse>, text: &str) {
    for cap in re.find_iter(text) {
        let pth = String::from(cap.as_str());
        if pth.contains('@') {
            let mut arr =  pth.split('@');
            let name = String::from(arr.next().unwrap());
            let domain = String::from(arr.next().unwrap());
            tx.send(RunnerResponse::Email(Email { name: name, domain: domain}));
        }
    }
}
