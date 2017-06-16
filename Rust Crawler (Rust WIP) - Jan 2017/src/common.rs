use std::fmt;

use url::Url;

#[derive(PartialEq, Eq, Hash, Clone)]
pub struct Email {
    pub name: String,
    pub domain: String,
}

impl Email {
    pub fn new(string: &str) -> Option<Email> {
        if string.contains('@') {
            let mut arr =  string.split('@');
            let name = String::from(arr.next().unwrap());
            let domain = String::from(arr.next().unwrap());
            return Option::Some(Email { name: name, domain: domain});
        }
        return Option::None;
    }
}

impl fmt::Display for Email {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}@{}", self.name, self.domain)
    }
}

pub enum RunnerMessage {
    Job(Url),
    NoJobReady
}

pub enum RunnerResponse {
    Downloading(f32),
    Downloaded,
    Link(Url),
    Email(Email),
    Ready,
}
