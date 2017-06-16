#!/usr/bin/env ruby

require 'benchmark'

LINE = 'https://www.google.com/MAPS/preview#!data=!1m8!1m3!1d3!2d12.328915!3d45.438936!2m2!1f182.15!2f102.2!4f75!2m7!1e1!2m2!1sGfc_6w1xADDeEukGpQSFHw!2e0!5m2!1sGfc_6w1xADDeEukGpQSFHw!2e0&amp'
FILE = 'queue.txt'

# def line_unique_grep(line,file)
#   exists = nil
#   time = Benchmark.measure do
#     exists = system('grep', '-Fxi', '-m 1', line.chomp, file)
#   end
#   puts "grep: #{time}"
#   return !exists
# end
# 
# def line_unique_rb(search,file)
#   exists = false
#   time = Benchmark.measure do
#     
#   end
#   puts "ruby: #{time}"
#   return true
# end
# puts "searching for #{LINE}\nin #{File.expand_path(FILE)}"
# puts
# line_unique_grep(LINE, FILE)
# line_unique_rb(LINE, FILE)

gp_exists = nil
rb_exists = nil

Benchmark.bmbm(10) do |x|
  x.report("grep:") do
    gp_exists = system('grep', '-Fx', '-m 1', LINE.chomp, FILE)
  end
  
  x.report("ruby:") do
    File.foreach(FILE) do |line|
      if line == LINE
        rb_exists = true
        break
      end
    end
  end
  
  x.report("ruby lc:") do
    File.foreach(FILE) do |line|
      if line.downcase == LINE.downcase
        rb_exists = true
        break
      end
    end
  end
  
end