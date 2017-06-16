extern crate url;
extern crate termion;

use common::*;

use std::io::{Stdin, Stdout, stdin, stdout, Write};
use std::iter;
use std::ops::IndexMut;

//use std::fmt;
//use std::thread;
//use std::env;
//use std::io::prelude::*;
//use std::io::BufReader;
//use std::fs::{File, OpenOptions};
//use std::path::Path;
//use std::sync::mpsc;
//use std::error::Error;
//use std::collections::{VecDeque, HashMap, HashSet}; 

use url::Url;
use std::panic;
use std::collections::HashMap;

use termion::color;
use termion::raw::{IntoRawMode, RawTerminal};
use termion::terminal_size;
use termion::cursor::Goto;

const THREAD_LINE_HEIGHT: u32= 2;


const STAT_KEY_WIDTH: u16 = 16;
const STAT_KEY_VAL_BUFFER: u16 = 2;
const STAT_VAL_WIDTH: u16 = 8;
const STAT_BUFFER: u16 = 2;
const STAT_TOTAL: u16 = STAT_KEY_WIDTH + STAT_KEY_VAL_BUFFER + STAT_VAL_WIDTH + STAT_BUFFER;

const THREAD_DIGIT_LEN: u16 = 6;

pub struct Stat {
    name: String,
    pub num: u32
}

pub struct TermUI {
    threads: Vec<ThreadUI>,
    stats: Vec<Stat>,
    stat_table: HashMap<String, usize>,

    pub stdin: Stdin,
    pub stdout: Vec<u8>,
    pub real_stdout: RawTerminal<Stdout>,

    w: u16,
    h: u16,
}

impl TermUI {
    pub fn new(count: u32, stats: &[&str]) -> TermUI {
        let mut ui = TermUI {
            threads: vec![],
            stats: vec![],
            stat_table: HashMap::new(),

            stdin: stdin(),
            real_stdout: stdout().into_raw_mode().unwrap(),
            stdout: vec![],

            w: 0, h: 0,
        };
        ui.update_size();

        for i in 0..count {
            ui.threads.push(ThreadUI {
                status: "---".to_string(),
                url: "===".to_string(),
                link_count: 0 
            });
        }

        for (i, s) in stats.iter().enumerate() {
            ui.stat_table.insert(s.to_string(), i);
            ui.stats.push(Stat {
                name: s.to_string(),
                num: 0
            });
        }

        return ui;
    }

    fn update_size(&mut self) {
        let size = terminal_size().unwrap();
        self.w = size.0;
        self.h = size.1;
    }

    pub fn stat(&mut self, name: &str) -> &mut Stat {
        let index = *self.stat_table.get(&name.to_owned()).unwrap() as usize;
        return self.stats.index_mut(index);
    }

    pub fn cleanup(&self) {
        write!(stdout().into_raw_mode().unwrap(), "{}{}{}", termion::cursor::Show, color::Fg(color::Reset), color::Bg(color::Reset)).unwrap();
    }

    pub fn redraw(&mut self) {
        panic::set_hook(Box::new(|_| {
            write!(stdout().into_raw_mode().unwrap(), "{}{}{}", termion::cursor::Show, color::Fg(color::Reset), color::Bg(color::Reset)).unwrap();
        }));

        self.update_size();

        write!(self.stdout, "{}{}{}", Goto(1, 1), termion::clear::All, termion::cursor::Hide).unwrap();

        for i in 0..self.threads.len() {
            self.update(i as u32)
        }
    }

    pub fn get_thread(&mut self, i: u32) -> &mut ThreadUI {
        return &mut self.threads[i as usize];
    }

    pub fn update(&mut self, i: u32) {
        self.update_stats();
        self.threads[i as usize].redraw(i*THREAD_LINE_HEIGHT+1 + self.stat_height() as u32, self.w, &mut self.stdout);
        write!(self.stdout, "{}", Goto(1, self.h));
    }

    pub fn flip(&mut self) {
        self.real_stdout.write(&self.stdout[..]);
        self.stdout.truncate(0);
        write!(self.real_stdout, "{}\n", Goto(0, self.h-1));
    }


    fn update_stats(&mut self) {
        let horizontal_fit = self.w / STAT_TOTAL;
        write!(self.stdout, "{}", Goto(1, 1));
        for i in 0..self.stats.len() {
            let ref s = self.stats[i];
            if (i as u16+1) % horizontal_fit == 0 {
                write!(self.stdout, "\r\n").unwrap();
            }
            write!(self.stdout, " {kC}{k: >0$}{rC}  {vC}{v: <1$}{rC} ", STAT_KEY_WIDTH as usize, STAT_VAL_WIDTH as usize,
                   rC = color::Fg(color::Reset), kC = color::Fg(color::Blue), vC = color::Fg(color::Red),
                   k = s.name, v = s.num
                  ).unwrap();
        }
    }

    fn stat_height(&self) -> u16 {
        let horizontal_fit = self.w / STAT_TOTAL;
        return (self.stats.len() as u16 + horizontal_fit-1) / horizontal_fit;
    }

    pub fn status_width(&self) -> u16 {
        self.w - 4
    }
}

pub struct ThreadUI {
    pub status: String,
    pub url: String,
    pub link_count: u32,
}

impl ThreadUI {
    fn redraw(&self, row: u32, w: u16, stdout: &mut Write) {
        write!(stdout, "{}{}{}{}", Goto(0, row as u16), termion::clear::CurrentLine, Goto(0, (row+1) as u16), termion::clear::CurrentLine).unwrap();

        let urllen: usize = (w - THREAD_DIGIT_LEN - 1) as usize;
        
        let urlspaces: String = iter::repeat(" ").take(urllen).collect();
        let digitspaces: String = iter::repeat(" ").take(THREAD_DIGIT_LEN as usize).collect();


        write!(stdout, "{}{}{}{}", Goto(2, row as u16), color::Bg(color::Black), color::Fg(color::Cyan), urlspaces).unwrap();
        write!(stdout, "{}{}", Goto(2, row as u16), self.url).unwrap();

        write!(stdout, "{}{}{}{}", Goto(w-THREAD_DIGIT_LEN, row as u16), color::Bg(color::Black), color::Fg(color::Red), urlspaces).unwrap();
        write!(stdout, "{}{}", Goto(w-THREAD_DIGIT_LEN, row as u16), self.link_count).unwrap();
        
        write!(stdout, "{}{}", color::Fg(color::Reset), color::Bg(color::Reset));
        write!(stdout, "{}{}", Goto(4, (row+1) as u16), self.status).unwrap();
        
    }

    pub fn status(&mut self, s: &str) {
        self.status = s.to_owned();
    }
}
