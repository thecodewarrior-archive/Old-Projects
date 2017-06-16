require 'fileutils'
require 'save_helpers.rb'

class Save
  def initialize(save_info=nil)
    
    if save_info
      @num = save_info[:num]
      @name = save_info[:name]
      @save_dir = "#{@num}_#{@name}"
    else
      saves = []
      Dir['./saves/*'].each do |s|
        save_info = /(\d+)_(.+)/.match(s)
        save = {:num => save_info[1].to_i, :name => save_info[2]}
        saves << save
      end

      savemax = saves.max_by {|v| v[:num]}
      
      new_from_input(savemax[:num]+1)
    end
  end
  
  def new_from_input(id)
    @name = ""
    @num = id
    @save_dir = "#{@num}_#{@name}"
       
    url = Field.new()
    name = Field.new()

    field = 0
    done = false
    name_error = nil
    url_error = nil
    status = nil
    
    name_error, url_error = err_check(name.text, "http://#{url.text}")
    
    while !done do
      clear
      setpos(0,0)
      refresh
    
    
      puts "\
new crawler session:\r
#{name_error!='' ? '✗'.red : '✓'.green } name: #{name.text} #{     '  ' + name_error.red.bold if name_error}\r
#{ url_error!='' ? '✗'.red : '✓'.green } url: http://#{url.text} #{'  ' +  url_error.red.bold if url_error }\r
Press tab to switch fields and enter to finish\r
#{status}"
  
      if field == 0 # name
        
        col = 8 # offset
        col += name.pos
        
        setpos(1,col)
        refresh
        
        name.read do |ch|
          if ch == :tab
            field = 1
          elsif ch == :return
            name_error, url_error = err_check(name.text, "http://#{url.text}") { # block on success
              done = true
              
            }
          end
        end
        name_error, url_error = err_check(name.text, "http://#{url.text}")
        
      else # url
        col = 14 # offset
        col += url.pos
        
        setpos(2,col)
        refresh
        
        url.read do |ch|
          if ch == :tab
            field = 0
          elsif ch == :return
            name_error, url_error = err_check(name.text, "http://#{url.text}") { # block on success
              done = true
              
            }
          end
        end
        name_error, url_error = err_check(name.text, "http://#{url.text}")
      end
      
    end
    
    @name = name.text
    @save_dir = "#{@num}_#{@name}"
    mkdir_cmd = "mkdir -p \"saves/#{@save_dir}\""
    puts mkdir_cmd
    `#{mkdir_cmd}`
    `echo "#{url.text}" >> "saves/#{@save_dir}/queue.txt"`
  end
  
  def save_dir
    @save_dir
  end
end

class Field
  attr_accessor :text, :pos, :spaces
  
  def initialize(text="",pos=0,spaces=true)
    @text = text
    @pos = pos
    @spaces = spaces
  end
  
  def read
    ch = readch
    
    if ch.to_s =~ /key_.+/ or (ch == :space and @spaces)
      if ch == :space
        key = " "
      else
        key = /key_(.+)/.match(ch.to_s)[1]
      end
      
      @text.insert @pos, key
      @pos += 1
      
    elsif ch == :left_arrow
      @pos -= 1 unless @pos == 0
      
    elsif ch == :right_arrow
      @pos += 1 unless @pos == @text.length
      
    elsif ch == :backspace
      @text[@pos-1] = ""
      @pos -= 1
    
    else
      if block_given?
        yield ch
      end
    end
    
    return @text
  end
end