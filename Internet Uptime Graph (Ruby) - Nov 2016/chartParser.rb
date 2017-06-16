require 'csv'


class PingData
	
	attr_accessor :rawData
	
	def initialize()
		
	end
	
	def parseData(fileName = "ping.csv")
		
		@lastTimeCode = nil
		
		`wc -l #{fileName}` =~ /(\d+)/
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
		
		CSV.foreach(fileName) do |row|
			if(index != 0)
				parse(index, row[0].to_i, float_or_nil(row[1]))
			end
			index += 1
		end
		
		done = true
		progressThread.join
	end
	
	private
	
	def parse(index, timeCode, ping)
		if(ping == nil)
			return
		end
		if(@lastTimeCode == nil)
			@lastTimeCode = timeCode
		end
		if(timeCode >= @lastTimeCode)
			if(@lastTimeCode+1 < timeCode)
				(@lastTimeCode+1...timeCode).each do |code|
					add :no_data
				end
			end
			if(ping < 0)
				add :fail
			else
				add ping
			end
		end
	end
	
	def add(val)
		if(@i >= @rawData.length)
			@rawData[@i+100] = nil
		end
		@rawData[@i] = val
		@i += 1
	end
	
	def float_or_nil(string)
		Float(string || '')
	rescue ArgumentError
		nil
	end
	
	def a(str)
		print "\033[#{str}"
	end
end