#!/usr/bin/env ruby
$curdir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH <<  "#{$curdir}/lib"

Dir.chdir $curdir

require 'helpers.rb'
require 'save.rb'
require 'crawler/crawl_test.rb'


require 'curses'

require 'rubygems'
require 'term/ansicolor'

include Curses

class String
  include Term::ANSIColor
end

saves = []
Dir['./saves/*'].each do |s|
  save_info = /(\d+)_(.+)/.match(s)
  save = {:num => save_info[1].to_i, :name => save_info[2]}
  saves << save
end

init_screen
scr = stdscr()

savesel = 0
savemax = saves.max_by {|v| v[:num]}
# select save
loop do
  clear
  setpos(0,0) # clear screen and return to top left corner
  refresh
  
  puts "SELECT A SAVE OR SELECT \"NEW SAVE\"\r"
  
  message = "NEW SAVE\r"
  message = message.black.on_green if savesel == 0
  message = "#{savesel == 0 ? "➔ ".red.bold : "  " }#{message}"
  puts message
  
  saves.each do |save|
    message = "#{save[:num]}. #{save[:name]}\r"
    if savesel == save[:num]
      message = message.bold.black.on_green
    end
    message = "#{savesel == save[:num] ? "➔ ".red.bold : "  " }#{message}"
    
    puts message
  end

  a = readch
  case a
    when :up_arrow
      if savesel == 0
        beep # min save (new save)
      else
        savesel -= 1 # decrease save selection
      end
    # ----------------------------------------
    when :down_arrow
      if savesel == savemax[:num]
        beep # max save
      else
        savesel += 1 # increase save selection
      end
    # ----------------------------------------
    when :return
      break
      
  end # end case
  
end

if savesel == 0
  save = Save.new()
else
  save = Save.new(saves[savesel])
end

Dir.chdir "#{$curdir}/saves/#{save.save_dir}"

start_crawler()

#(fold)
# 
# def show_message(message)
#   width = message.length + 6
#   win = Window.new(5, width,
#                (lines - 5) / 2, (cols - width) / 2)
#   win.box(?|, ?-)
#   win.setpos(2, 3)
#   win.addstr(message)
#   win.refresh
#   win.getch
#   win.close
# end
# 
# init_screen
# begin
#   crmode
# #  show_message("Hit any key")
#   setpos((lines - 5) / 2, (cols - 10) / 2)
#   addstr("Hit any key")
#   refresh
#   getch
#   show_message("Hello, World!")
#   refresh
# ensure
#   close_screen
# end
#(end)