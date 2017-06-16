#!/usr/bin/env ruby

require "lib/helpers.rb"
chr = :v

thr = Thread.new do
  loop do
    puts chr.to_s + "\r"
    sleep 0.5
  end
  
end

loop do
  e = readch
  puts "c#{e}"
  chr = e
end
