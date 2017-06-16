#!/usr/bin/env ruby
require 'net/http'
require 'open-uri'
require 'uri'

require 'rubygems'
require 'term/ansicolor'


class Input_var
  def initialize
    @keys = []
  end
  
  def check(key)
    if @keys.include? key
      yield if block_given?
      @keys -= [key]
    else
      return false
    end
  end
end


class String
  include Term::ANSIColor
end

$error = nil

$pos = {
  :url => [1,1],
  :num_header => [3,1],
  :data_num => [4,1],
  :status => [2,1],
  :reset => [0,0],
  :exit => [5,0]
}

#require '../helpers.rb'
$quit = false

def set_trap
  $Input = Input_var.new

  input_thread = Thread.new do
    Thread.current.priority = -5
  end
  
  Thread.current.priority = 5  
end

def clear
  print "\e[2J"
end

def setpos(posname,clear=false)
  line,col = $pos[posname]
  print "\e[#{line};#{col}H"
  if clear
    print "\e[K"
  end
end

def flush()
  STDOUT.flush
end

def crawl(crawl_url)
  
  url_regexp = %r{
    \b(?:(?:https?|ftp|file)://|www\.|ftp\.)
    (?:\([-A-Z0-9+&@#/%=~_|$?!:,.]*\)|[-A-Z0-9+&@#/%=~_|$?!:,.])*
    (?:\([-A-Z0-9+&@#/%=~_|$?!:,.]*\)|[A-Z0-9+&@#/%=~_|$])
  }xi
  
  email_regexp = %r{
    [\w\-!$#%^*&+][\w\-.!$#%^*&+]*@[a-zA-Z0-9_.-]+\.[a-zA-Z]{2,6}
  }xi
  
  phone_regexp = %r{
    (?:\+?\d{1,2})[ -.](?:\d{3}|\(\d{3}\))[ -.](?:\d{3}|\(\d{3}\))[ -.](?:\d{4}|\(\d{4}\))
  }xi
  
  crawl_url = std_url crawl_url
    
  #puts "@@@#{crawl_url}@@@"
  ch = nil
  return ch unless (ch = check_headers crawl_url) == :success

  urls = []
  emails = []
  phones = []
  long_time = false
  thr = Thread.new do
    sleep 1
    long_time = true
    
    i = 0
    loop do
      print "."
      flush
      i += 1
      if i == 10
        print "\b"*10
        flush
        i = 0
      end
      sleep 0.5
    end
  end
  setpos(:status)
  print "downloading".green.bold
  flush
  prev_email_count = 0
  begin

    open(crawl_url) { |f|
      thr.kill
      setpos(:status,true)
      print 'done'.green.bold
      setpos(:num_header)
      print " urls\temails".green.bold
      f.each_line do |line|
          urls.concat line.scan(url_regexp)
        emails.concat line.scan(email_regexp)
        phones.concat line.scan(phone_regexp)
        setpos(:data_num)
        print " #{urls.length.to_s.green}\t#{emails.length > 0 ? emails.length.to_s.red.bold : 0}"
        if prev_email_count != emails.length
          print "\a"
        end
        prev_email_count = emails.length
        $Input.check(:ctrl_c)
      end
    }
  rescue StandardError => e
    #puts e
  ensure
    thr.kill if thr
  end

  File.open("queue.txt",'a') do |f|
    i = 0
    urls.each do |url|
      i += 1
      exists = system(%Q{grep -Fxq "#{url.chomp}" queue.txt})
      f.puts url if !exists
      setpos(:status,true)
      print "writing urls to queue...#{i}".red
      $Input.check(:ctrl_c)
    end
  end
  File.open("emails.txt",'a') do |f|
    emails.each do |email|
      exists = system(%Q{grep -Fxq "#{email.chomp}" emails.txt})
      f.puts email.chomp if !exists

    end
  end
  File.open("phones.txt",'a') do |f|
    phones.each do |phone|
      exists = system(%Q{grep -Fxq "#{phone.chomp}" phone.txt})
      f.puts phone if !exists

    end
  end
  setpos(:status,true)
  print 'done'
end

def std_url(url)
  begin
    uri = URI(url)
  rescue URI::InvalidURIError => e
    $error = e
    return :error
  end
  uri.fragment = nil
  uri.scheme = "http" unless uri.scheme
  return uri.to_s
end

def check_headers(url)
  uri = URI(url)

  host = "#{uri.host}"

 # print "Checking Headers..."
  flush
  http = Net::HTTP.start(host)
  http.read_timeout = 60

  uri.path = "/" if uri.path.empty?

  resp = http.head(uri.path)
  
  resp.each { |k, v| 
    if k == "content-type"
      if v =~ %r|text\/\w+|
     #   puts "checked"
        return :success
      else
       # puts "not text. skipping."
        return :not_text
      end
    end
  }

  http.finish

  rescue Timeout::Error => e
   # puts "server not responding"
    return :timeout
  rescue StandardError => e
   # puts "error: #{e.class}:#{e.message}"
    $error = e
    return :error
  return :success
end

def crawl_loop()
  i = 0
  loop do
    i += 1
    url = File.open("queue.txt",&:readline)
    url = std_url url
    if url == :error
      setpos(:status,true)
      print "ERROR: #{$error.class}:#{$error.message}...skipping"
    else
      exists = system(%Q{grep -Fxq "#{url.chomp}" visited.txt})
      if !exists
        setpos(:reset)
        print ("\e[K\n")*10
        setpos(:url,true)
        print_url = url.length >= 100 ? url[0..99] : url.dup
        print std_url print_url
        resp = crawl(url.chomp)
        case resp
        when :not_text
          setpos(:status,true)
          print "not text file...skipping".white.bold.on_red
        when :timeout
          setpos(:status,true)
          print "server not responding...skipping".white.bold.on_red
        when :error
          setpos(:status,true)
          print "ERROR: #{$error.class}:#{$error.message}...skipping"
        end
    
        File.open("visited.txt",'a'){|f| f.puts std_url(url).chomp}
      end
    end
    `perl -pi -e '$_ = "" if ( $. == 1 );' "queue.txt"`    
    if i == 100

      clean_files
    end
    
    $Input.check(:ctrl_c)
  end
end

def clean_files
  setpos(:status,true)
  print "removing duplicate queue entrys...".red
  `awk '!x[$0]++' queue.txt > queue.clean`
  print 'done'.green.bold
  
  setpos(:status,true)
  print "removing duplicate emails...".red
  `awk '!x[$0]++' emails.txt > emails.clean`
  print 'done'.green.bold
  
  `mv emails.clean emails.txt`
  `mv queue.clean queue.txt`
end

def start_crawler
  set_trap
  clear
  crawl_loop()
end

if __FILE__ == $0
  start_crawler()
end