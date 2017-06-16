#!/usr/bin/env ruby

require 'net/http'
require 'open-uri'
require 'uri'
require 'thread'
require 'set'

require 'timeout'
include Timeout

require 'curses'
include Curses

require 'rubygems'
require 'term/ansicolor'

$sock_mutex = Mutex.new

$error = nil

$quit = false

$sock = nil

$buf = ""

$messages = Set.new

def messages_recived?(*messages)
  begin
    message = timeout(0.2) {
      $sock_mutex.synchronize {
        message = $sock.recv(100)
      }
    }
    if !message.empty?
      $messages << message.gsub(/\s/,'_').to_sym
    end
  rescue Timeout::Error
  
  end

  messages.each do |message|
    if $messages.include? message
      $messages.delete message
      return true
    end
  end
  return false
end

def sputs(o)
  $sock_mutex.synchronize {
    $sock.write "#{o}\n"
  }
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
  sputs "scraping"
  
  begin

    open(crawl_url) { |f|
      f.each_line.with_index do |line,lineno|
        sputs "scraping line #{lineno+1}"
          urls.concat line.scan(url_regexp)
        emails.concat line.scan(email_regexp)
        phones.concat line.scan(phone_regexp)
      end
    }
  rescue StandardError => e
    senderror(e)
  end
  grepcommand = "grep -Fxqi %s %s"
  if emails.length > 0
    File.open("emails.txt",'a') do |f|
      emails.each do |email|
        exists = system('grep', '-Fxqi', email.chomp, 'emails.txt')
        if !exists
          f.puts email.chomp 
        end
          sputs "e: #{email.chomp.inspect}"
        #end
      end
    end
  end
  if phones.length > 0
    File.open("phones.txt",'a') do |f|
      phones.each do |phone|
        exists = system('grep', '-Fxqi', phone.chomp, 'phones.txt')
        if !exists
          f.puts phone 
          sputs "p: #{phone}"
        end
      end
    end
  end
  File.open("queue.txt",'a') do |f|
    i = 0
    urls.each do |url|
      i += 1
      exists = system('grep', '-Fxqi', url.chomp, 'queue.txt')
      if !exists
        f.puts url 
        sputs "u: #{url}"
      end
    end
  end

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
  sputs "checking headers"
  uri = URI(url)

  host = "#{uri.host}"

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
  sputs "done"
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
    sputs "crawling #{url}"

    if url == :error


    else
      exists = system(%Q{grep -Fxq "#{url.chomp}" visited.txt})
      crawl_thread = Thread.new do
        Thread.current.priority = 5
        if !exists
       
          resp = crawl(url.chomp)
          case resp
          when :not_text
            sputs "error: not text"

          when :timeout
            sputs "error: timeout"

          when :error
            senderror($error)

          end
    
          File.open("visited.txt",'a'){|f| f.puts std_url(url).chomp}
        else
          sputs "skipping: Already Crawled URL"
        end
      end
      
      loop do
        sleep(0.5)
        if !crawl_thread.alive?
          break
        end
        if messages_recived? :skip
          crawl_thread[:quit] = true
          sputs "skipping: User Skipped"
          crawl_thread.join(3)
          break
        end
        if messages_recived? :quit
          sputs "quitting: User Quit"
          # crawl_thread[:quit]
#           crawl_thread.join(3)
          exit
        end
      end
    end
    `perl -pi -e '$_ = "" if ( $. == 1 );' "queue.txt"`    
    if i == 100

      clean_files
    end
    
  end
end

def senderror(e)
  sputs "error: #{e.inspect}; trace: #{Marshal.dump(e.backtrace)}"
end

def clean_files

  `awk '!x[$0]++' queue.txt > queue.clean`

  `awk '!x[$0]++' emails.txt > emails.clean`
  
  `mv emails.clean emails.txt`
  `mv queue.clean queue.txt`
end

def start_crawler(socket,dir)
  $sock = socket
  Dir.chdir dir
  sputs "starting"
  crawl_loop()
end

if __FILE__ == $0
  start_crawler(STDOUT,File.dirname(File.expand_path(__FILE__)))
end
