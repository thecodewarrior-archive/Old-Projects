#!/usr/bin/env ruby

require 'pty'

cmd = "ping -c 100 8.8.8.8" 

timeRegex = /\d+ bytes from \d+\.\d+\.\d+\.\d+: icmp_seq=(\d+) ttl=\d+ time=(\d+\.\d+) ms/
timeoutRegex = /Request timeout for icmp_seq (\d+)/
noRouteString = /ping: sendto: No route to host/
skipnexttimeout = false


running = true

empty = !File.exist?("ping.csv")
File.open("ping.csv", "a") do |ping|
	if(empty)
		ping.write("timestamp,ping")
	end
	begin
		while(running)
			startingTime = Time.now.to_i
			isEnd = false
			PTY.spawn( cmd ) do |stdout, stdin, pid|
				begin
					stdout.each { |line|
						if(line.start_with?("---"))
							isEnd = true
						end
						if(!(isEnd || line =~ /^\s*$/ || line.start_with?("PING")))
							lastSeq = -1
							if(line =~ noRouteString)
								skipnexttimeout = true
							elsif(line =~ timeoutRegex)
								if(skipnexttimeout)
									skipnexttimeout = false
								else
									lastSeq = $1.to_i
									ping.write("\n#{startingTime + lastSeq},-1")
								end
							elsif(line =~ timeRegex)
								lastSeq = $1.to_i
								ping.write("\n#{startingTime + lastSeq},#{$2}")
							end
							# if(lastSeq > 100)
	# 							lastSeq = 0
	# 							stdout.close
	# 							stdin.close
	# 							Process.wait pid
	# 						end
							puts line
							ping.flush
						end
					}
				rescue Errno::EIO
					print "EIO? "
				rescue PTY::ChildExited
					print "child exit, "
				rescue IOError
					print "io ended, "
				end
			end
			puts "Restarting"
		end
	rescue PTY::ChildExited
		puts "Wut"
	end
end