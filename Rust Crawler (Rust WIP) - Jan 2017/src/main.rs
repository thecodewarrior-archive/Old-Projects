extern crate rand;
extern crate hyper;
extern crate html5ever;
extern crate url;
extern crate regex;
extern crate rustc_serialize;
extern crate clap;
extern crate termion;
#[macro_use] extern crate lazy_static;


mod common;
mod scrapers;
mod scrape;
mod tracker;
mod term;

use common::*;
use term::TermUI;

use std::fmt;
use std::thread;
use std::env;
use std::iter;
use std::io::prelude::*;
use std::io::{BufReader, Stdin, stdin};
use std::fs::{File, OpenOptions};
use std::path::Path;
use std::sync::mpsc;
use std::error::Error;
use std::collections::{VecDeque, HashMap, HashSet}; 

use regex::Regex;

use hyper::client;
use hyper::client::response::Response;

use html5ever::parse_document;
use html5ever::{QualName, LocalName};
use html5ever::rcdom::{Document, Doctype, Text, Comment, Element, RcDom, Handle, Node, NodeEnum};
use html5ever::tendril::TendrilSink;

use url::Url;

use rustc_serialize::json::Json;

use termion::color;
use termion::async_stdin;

use clap::{Arg, App};

fn main() {
    run();
    /*let matches = App::new("My Super Program")
        .version("1.0")
        .author("Pierce Corcoran")
        .about("My first Rust program, a web crawler")
        .arg(Arg::with_name("dir")
             .value_name("DIR")
             .required(true)
             .index(1)
             .help("The directory for this instance of the program")
             )
        .arg(Arg::with_name("inits")
             .short("i")
             .long("init")
             .multiple(true)
             .takes_value(true)
             .help("The urls to seed the crawler with")
             )*/
}

struct ThreadData {
    tx: mpsc::Sender<RunnerMessage>,
    rx: mpsc::Receiver<RunnerResponse>,
    id: u32
}


fn run() {

    let mut stdin = async_stdin().bytes();
    const threadCount: u32 = 6;
    let mut threads: Vec<ThreadData> = vec![];
    println!("Initializing...");

    println!("Tracker");
    let mut list = tracker::Tracker::new("default");
    list.default_urls(&["https://en.wikipedia.org/wiki/Main_Page", "http://minecraftforum.net"]);
    print!("...");

    print!("UI");
    let mut ui = TermUI::new(threadCount, &["emails", "queue", "visited"]);
    print!("...");

    print!("Threads");
    for i in 0..threadCount {
        let (tx, thr_rx) = mpsc::channel();
        let (thr_tx, rx) = mpsc::channel();

        let t = thread::spawn(move || {
            scrape::runner(thr_rx, thr_tx);
        });

        threads.push(ThreadData {
            tx: tx,
            rx: rx,
            id: i
        });
    }
    print!("...");
    print!("\n\r");

    print!("Redrawing");
    ui.redraw();
    ui.flip();
    print!("...\n\r");

    let mut paused = false;

    'outer: loop {
        let b = stdin.next();
        match b {
            Some(Ok(c)) => {
                match c {
                    b'q' => break'outer,
                    b'p' => paused = !paused,
                    _ => {}
                }
            },
            _ => {}
        }

        ui.stdout.flush().unwrap();
        for thread in &threads {
            let result = thread.rx.try_recv();
            let ok = result.is_ok();
            if ok {
                let msg: RunnerResponse = result.unwrap();
                let status_width = ui.status_width();
                let thread_ui = ui.get_thread(thread.id);
                match msg {
                    RunnerResponse::Link(ln) => {
                        if list.push(ln) {
                            thread_ui.link_count = thread_ui.link_count + 1;
                        }
                    },
                    RunnerResponse::Email(em) => {
                        if list.email(em.clone()) {
                            thread_ui.status = format!("{}", em);
                        }
                    },
                    RunnerResponse::Ready => {
                        let url = list.next_url();
                        thread_ui.link_count = 0;
                        if paused {
                            thread_ui.status("Paused");
                            thread_ui.url = "N/A".to_owned();
                            thread.tx.send(RunnerMessage::NoJobReady);
                        } else if url.is_some() {
                            let unwrapped = url.unwrap();
                            thread_ui.status("Connecting");
                            thread_ui.url = format!("{}", unwrapped);
                            thread.tx.send(RunnerMessage::Job(unwrapped));
                        } else {
                            thread_ui.status("Idle");
                            thread_ui.url = "N/A".to_owned();
                            thread.tx.send(RunnerMessage::NoJobReady);
                        }
                    },
                    RunnerResponse::Downloaded => {
                        thread_ui.status("Parsing");
                    },
                    RunnerResponse::Downloading(f) => {
                        let prefix = "Downloading ";
                        let bar_len = status_width-prefix.len() as u16;
                        let bar_hashes: String = iter::repeat("#").take((bar_len as f32*f) as usize).collect();
                        let bar_hashes = format!("{hashC}{hashes}{dotC}", hashes = bar_hashes, hashC = color::Fg(color::Green), dotC = color::Fg(color::Red));

                        thread_ui.status = format!("{d}{p:.<0$}{r}",
                                                   bar_len as usize,
                                                   d = prefix,
                                                   p = bar_hashes,
                                                   r = color::Fg(color::Reset)
                                                   );
                    }
                }
            }
            if(ok) {
                ui.update(thread.id);
                ui.stat("queue").num = list.queue_size();
                ui.stat("emails").num = list.email_count();
                ui.stat("visited").num = list.visited_count();
                ui.flip();
            }
        }
    }

    ui.cleanup();
}

