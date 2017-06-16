#!/usr/bin/env ruby
require 'gruff'
require './chartParser.rb'

data = PingData.new

data.parseData

dat = data.rawData.map {|v| v == :no_data || v == :fail ? -1 : v }

g = Gruff::Area.new("#{@pixels}x#{@height}")

g.font = 'Helvetica.ttf'

puts "Adding to graph"
g.data :data, dat, "#cc0000"

puts "writing image"
g.write('internet.png')