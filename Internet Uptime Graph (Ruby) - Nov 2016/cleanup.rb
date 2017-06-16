#!/usr/bin/env ruby

require 'csv'

`cp ping.csv ping_backup.csv`
`rm pingclean.csv`
out = File.open("pingclean.csv", "w")

`wc -l ping.csv` =~ /(\d+)/
lineCount = $1.to_i
lineSpaces = lineCount.to_s.length

clearSpaces = " " * (5 + lineSpaces + 2)

print "#{clearSpaces} / #{lineCount}\r"

@rawData = Array.new(lineCount)
@i = 0

index = 0

done = false
progressThread = Thread.new {
	while !done do
		print "#{clearSpaces}\r |#{"%3i" % ((index*100)/lineCount)}% #{index}\r"
	end
}

lasttimecode = -1
lastline = ""
CSV.foreach('ping.csv') do |row|
	if(row[1] == nil)
		next
	end
	if(row[0] == lasttimecode)
		next
	end
	lasttimecode = row[0]
	out.puts "#{row[0]},#{row[1]}"
	index += 1
end

out.close

done = true
progressThread.join