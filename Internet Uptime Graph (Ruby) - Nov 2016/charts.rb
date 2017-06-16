#!/usr/bin/env ruby
require 'gruff'
require 'date'
require 'csv'
require 'optparse'

#      S/M  M/H  H/D
DAYS = 60 * 60 * 24

$options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: charts.rb [options]"

  opts.on("-j", "Do jump") do |v|
    $options[:jump] = true
  end
  
  opts.on("-s", "--start [TIME]", Integer, "Start day offset") do |v|
    $options[:start] = Time.now - v * DAYS
  end
  
  opts.on("-e", "--end [TIME]", Integer, "End day offset") do |v|
    $options[:end] = Time.now - v * DAYS
  end
  
  opts.on("--height [HEIGHT]", Integer, "Graph height") do |v|
    $options[:height] = v
  end
  
  opts.on("--width [WIDTH]", Integer, "Graph width") do |v|
    $options[:width] = v
  end
  
  opts.on("--pixeltime [TIME]", Integer, "Number of seconds per pixel. Incompatible with --width") do |v|
    $options[:pixel_time] = v
  end
  
  opts.on("--range [RANGE]", Integer, "Max ping value for graph") do |v|
    $options[:range] = v
  end
  
  opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
  end
end.parse!

CALCULATE_PIXELS = true

MAX_PING = $options[:range] || 500

MAX_JUMP = 100
MIN_JUMP = 5

@pixels = $options[:width] || 3000
@height = $options[:height] || 1000
@skip = $options[:pixel_time] || 60

@slope = 5

`wc -l ping.csv` =~ /(\d+)/
samples = $1.to_i
if($options[:pixel_time] != nil)
    @pixels = samples/@skip
else
    @skip = samples/@pixels
end
    

puts "#{samples} data points"

ping = []
dropped = []

avgSum = 0
avgCnt = 0

totalAvgSum = 0
totalAvgCnt = 0

success = 0
failure = 0

index = 0
lastTimeCode = nil
lastValue = nil

minTimeStamp = 100000000000
maxTimeStamp = 0

maxValue = 0

labels = {}

CSV.foreach("ping.csv") do |row|
    if(index == 0)
        index += 1
        next
    end
    timeStamp = row[0].to_i
    if(index == 1)
        minTimeStamp = timeStamp
    end
    if(lastTimeCode != nil && $options[:jump])
        if(lastTimeCode+MIN_JUMP < timeStamp-1)
            if(timeStamp-lastTimeCode > MAX_JUMP)
                lastTimeCode = timeStamp-MAX_JUMP
            end
            c = avgCnt
            (lastTimeCode+1...timeStamp).each do |i|
                if(c == @skip)
                    ping << nil
                    dropped << nil
                end
                c += 1
            end
            avgCnt = c
        end
    end
    if(avgCnt == @skip) 
        if(failure > success)
            ping << 0
            lastValue = nil
        else
            v = avgSum / @skip.to_f
            if(lastValue == nil)
                lastValue = v
            end
            # if(lastValue*@slope < v)
            #     v = lastValue*@slope
            # end
            if(lastValue/@slope > v)
                v = lastValue/@slope
            end
            time = Time.at(timeStamp).to_datetime
            if(time.min == 0 && time.sec == 0 && time.hour % 6 == 0)
                if(time.hour == 0)
                    labels[ping.size] = time.strftime("%b %e")
                else
                    labels[ping.size] = time.strftime("%l:00 %P")
                end
            end
            ping << v
            lastValue = v
        end
        dropped << (failure/@skip.to_f)
        avgCnt = 0
        avgSum = 0
        failure = 0
        success = 0
    end
    val = row[1].to_f
    if(val == -1)
        failure += 1
    else
        success += 1
    end
    
    avgSum += val
    avgCnt += 1
    
    totalAvgSum += val
    totalAvgCnt += 1
    
    lastTimeCode = row[0].to_i
    maxTimeStamp = lastTimeCode
    index += 1
end

def secondsDifference(minDateTime, maxDateTime)
    return ((maxDateTime - minDateTime)*24*60*60).to_i
end

def formatTimeDifference(_seconds)
    sec = _seconds % 60
    _minutes = _seconds / 60
    min = _minutes % 60
    _hours = _minutes / 60
    hour = _hours % 24
    days = _hours / 24
    v = []
    if(days > 0)
        v << days.to_s + 'Day' + (days == 1 ? "" : "s")
    end
    if(hour > 0)
        v << hour.to_s + 'Hour' + (hour == 1 ? "" : "s")
    end
    if(min > 0)
        v << min.to_s + 'Min' + (min == 1 ? "" : "s")
    end
    if(sec > 0)
        v << sec.to_s + 'Sec' + (sec == 1 ? "" : "s")
    end
    return v.join ', '
end

dropped.collect! {|v| v == nil || v <= 0.001 ? 0 : v}.collect! {|v| v * MAX_PING}
ping.collect! {|v| v == nil || v <= 0.001 ? 0 : v}

minDateTime = Time.at(minTimeStamp).to_datetime
maxDateTime = Time.at(maxTimeStamp).to_datetime

puts "Time range: #{formatTimeDifference(secondsDifference(minDateTime, maxDateTime))}"
puts "Pixel range: #{formatTimeDifference(secondsDifference(minDateTime, maxDateTime)/@pixels)}"

puts "Creating graph #{@pixels}x#{@height}"


g = Gruff::Area.new("#{@pixels}x#{@height}")

@g = g
@constCount = 0
@ping = ping

def constBar(const, color, buffer = 0)
    @g.data :"#{@constCount}", Array.new(@ping.size) {|i| i < buffer || i >= @ping.size-buffer ? 0 : const }, color
    @constCount += 1
end

g.hide_legend = true
g.hide_title = true
g.hide_line_markers = true
# g.left_margin = 0
# g.right_margin = 0
g.bottom_margin = 0
g.top_margin = -25

g.theme = {
  :background_colors => ['black', 'black', :top_bottom]
}

#g.title = 'Internet status'
g.font = 'Helvetica.ttf'

puts "Adding to graph"
constBar(MAX_PING + 1, "#cccccc", 1)
constBar(MAX_PING, "#000000")
g.data :Dropped, dropped, "#cc0000"
g.data :Ping, ping, "#0000cc"
constBar(-15, "#000000")

g.minimum_value = 0
g.maximum_value = MAX_PING
# g.y_axis_increment = 100

g.has_left_labels = false
g.labels = labels

puts "writing image"
g.write('internet.png')