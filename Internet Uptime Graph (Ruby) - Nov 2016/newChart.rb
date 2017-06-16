#!/usr/bin/env ruby
require 'daru'
require 'nyaplot'
require_relative 'chartParser'

# pingData = PingData.new
# pingData.parseData()
# data = pingData.rawData

df = Daru::DataFrame.from_csv 'ping.csv', col_sep: ","
df.timestamp.recode! { |ts| Time.at(ts.to_i).to_datetime }
df.ping.recode! { |t| t.to_f }

# df = Daru::DataFrame.new({ping: data.map {|v| v == :fail ? -10 : v == :no_data ? 0 : v }}, name: :normal)
#
# df.plot type: :bar do |plt|
# 	plt.width 1120
# 	plt.height 500
# 	plt.legend true
# end