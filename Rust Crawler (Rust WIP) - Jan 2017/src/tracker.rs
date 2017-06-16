extern crate rand;
extern crate hyper;
extern crate html5ever;
extern crate url;
extern crate regex;
extern crate rustc_serialize;
extern crate clap;


use common::*;

use std::fmt;
use std::thread;
use std::env;
use std::io::prelude::*;
use std::io::BufReader;
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

#[derive(RustcDecodable, RustcEncodable)]
struct TrackerSettings {
    absoluteNextIndex: usize,
}

pub struct Tracker {
    settings: TrackerSettings,
    path: String,

    queueSet: HashSet<Url>,
    queue: VecDeque<Url>,

    emailSet: HashSet<Email>,

    queueFile: File,
    emailsFile: File,

    queueToWrite: VecDeque<Url>,
    emailsToWrite: VecDeque<Email>,

    writeCounter: u16
}

impl Tracker {
    pub fn new(path: &str) -> Tracker {

        let mut t = Tracker {
            queueSet: HashSet::new(),
            queue: VecDeque::new(),

            emailSet: HashSet::new(),

            queueFile: OpenOptions::new().append(true).create(true).open(format!("{}/queue.txt", path)).unwrap(),
            emailsFile: OpenOptions::new().append(true).create(true).open(format!("{}/emails.txt", path)).unwrap(),

            emailsToWrite: VecDeque::new(),
            queueToWrite: VecDeque::new(),

            path: path.to_string(),
            writeCounter: 0,
            settings: TrackerSettings {
                absoluteNextIndex: 0
            }
        };

        let infoFile = OpenOptions::new().read(true).open(format!("{}/info.json", path));
        match infoFile {
            Ok(mut v) => {
                let mut data = String::new();
                v.read_to_string(&mut data);
                let mut jsonRes = rustc_serialize::json::decode(data.as_str());
                match jsonRes {
                    Ok(s) => {
                        t.settings = s;
                    },
                    _ => {}
                }
            },
            _ => {}
        }

        let emailFile = OpenOptions::new().read(true).open(format!("{}/emails.txt", path));
        match emailFile {
            Ok(mut v) => {
                let mut reader = BufReader::new(&v);

                for line in reader.lines() {
                    let l = line.unwrap();
                    match Email::new(l.trim()) {
                        Some(v) => { t.emailSet.insert(v); },
                        _ => {}
                    }
                }
            }
            _ => {}
        }

        let queueFile = OpenOptions::new().read(true).open(format!("{}/queue.txt", path));
        match queueFile {
            Ok(mut v) => {
                let mut reader = BufReader::new(&v);
                for (i, line) in reader.lines().enumerate() {
                    let l = line.unwrap();
                    match Url::parse(l.trim()) {
                        Ok(v) => {
                            t.queueSet.insert(v.clone());
                            if i >= t.settings.absoluteNextIndex {
                                t.queue.push_front(v);
                            }
                        },
                        _ => {}
                    }
                }
            }
            _ => {}
        }

        t.write();



        return t;
    }

    fn write(&mut self) {
        while self.queueToWrite.len() > 0 {
            self.queueFile.write(format!("{}\n", self.queueToWrite.pop_back().unwrap()).as_bytes());
        }
        self.queueFile.flush();

        while self.emailsToWrite.len() > 0 {
            self.emailsFile.write(format!("{}\n", self.emailsToWrite.pop_back().unwrap()).as_bytes());
        }
        self.emailsFile.flush();

        match rustc_serialize::json::encode(&self.settings) {
            Ok(v) => {
                let mut file = OpenOptions::new().write(true).create(true).open(format!("{}/info.json", self.path)).unwrap();
                file.write(v.as_bytes());
            },
            _ => {}
        }
    }

    pub fn default_urls(&mut self, arr: &[&str]) {
        if self.queueSet.len() == 0 {
            for u in arr {
                match Url::parse(u) {
                    Ok(v) => {
                        self.push(v);
                    },
                    _ => {}
                }
            }
        }
    }

    fn write_tick(&mut self) {
        if self.writeCounter == 0 {
            self.write();
            self.writeCounter = 20;
        }
        self.writeCounter = self.writeCounter - 1;
    }

    pub fn push(&mut self, url: Url) -> bool {
        if !self.is_unique(&url) {
            return false;
        }

        self.queueFile.write(format!("{}\n", url).as_bytes());
        self.queueFile.flush();
        self.queue.push_front(url.clone());
        self.queueSet.insert(url);

        self.write_tick();
        return true;
    }

    pub fn email(&mut self, email: Email) -> bool{
        if self.emailSet.contains(&email) {
            return false;
        }

        self.emailsToWrite.push_front(email.clone());
        self.emailSet.insert(email);
        self.write_tick();
        return false;
    }


    pub fn next_url(&mut self) -> Option<Url> {
        match self.queue.pop_back() {
            Some(v) => {
                self.settings.absoluteNextIndex = self.settings.absoluteNextIndex + 1;
                self.write_tick();
                return Option::Some(v.clone());
            },
            None => {
                return Option::None;
            }
        }
    }

    pub fn queue_size(&self) -> u32 {
        return self.queue.len() as u32;
    }

    pub fn email_count(&self) -> u32 {
        return self.emailSet.len() as u32;
    }

    pub fn visited_count(&self) -> u32 {
        return self.settings.absoluteNextIndex as u32;
    }

    pub fn is_unique(&self, url: &Url) -> bool {
        !self.queueSet.contains(url)
    }
}
