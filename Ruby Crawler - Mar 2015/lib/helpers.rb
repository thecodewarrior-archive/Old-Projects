# read a character without pressing enter and without printing to the screen
def read_char
  begin
    # save previous state of stty
    old_state = `stty -g`
    # disable echoing and enable raw (not having to press enter)
    system "stty raw -echo"
    system "stty onlcr"
    c = STDIN.getc
    if c
      c = c.chr
    else
      return nil
    end
    # gather next two characters of special keys
    if(c=="\e")
      extra_thread = Thread.new{
        c = c + STDIN.getc.chr
        c = c + STDIN.getc.chr
      }
      # wait just long enough for special keys to get swallowed
      extra_thread.join(0.00001)
      # kill thread so not-so-long special keys don't wait on getc
      extra_thread.kill
    end
  rescue => ex
    puts "#{ex.class}: #{ex.message}"
    puts ex.backtrace
  ensure
    # restore previous state of stty
    system "stty #{old_state}"
  end
  return c
end

# Read a single keypress from stdin
def readch(ignore_ctrl_c=false,ctrl_c_message='Pressed Ctrl-C in readch')
  # read character
  c = read_char
  # convert raw char to symbol
  symb = case c
    when " "
      :space
    when "\t"
      :tab
    when "\r"
      :return
    when "\n"
      :line_feed
    when "\e"
      :escape
    when "\e[A"
      :up_arrow
    when "\e[B"
      :down_arrow
    when "\e[C"
      :right_arrow
    when "\e[D"
      :left_arrow
    when "\177"
      :backspace
  # ctrl-* (fold)
    when "\037"
      :ctrl_underscore
    when "\036"
      :ctrl_caret
    when "\035"
      :ctrl_close_bracket
    when "\034"
      :ctrl_space
#   "\033" is escape: ctrl-[
    when "\032"
      :ctrl_z
    when "\031"
      :ctrl_y
    when "\030"
      :ctrl_x
    when "\027"
      :ctrl_w
    when "\026"
      :ctrl_v
    when "\025"
      :ctrl_u
    when "\024"
      :ctrl_t
    when "\023"
      :ctrl_s
    when "\022"
      :ctrl_r
    when "\021"
      :ctrl_q
    when "\020"
      :ctrl_p
    when "\017"
      :ctrl_o
    when "\016"
      :ctrl_n
    when "\015"
      :ctrl_m
    when "\014"
      :ctrl_l
    when "\013"
      :ctrl_k
    when "\012"
      :ctrl_j
    when "\011"
      :ctrl_i
    when "\010"
      :ctrl_h
    when "\007"
      :ctrl_g
    when "\006"
      :ctrl_f
    when "\005"
      :ctrl_e
    when "\004"
      :ctrl_d
    when "\003"
      if ignore_ctrl_c
        :ctrl_c
      else
        raise Interrupt, ctrl_c_message
      end
      
    when "\002"
      :ctrl_b
    when "\001"
      :ctrl_a
    when "\000"
      :ctrl_at
  #(end)
    when /^.$/
      :"key_#{c}"
      
    when nil
      return :__error__
    else
      :"other_#{c.inspect}"
  end
  return symb
end

def get_new_save_num
  
end

# Create a gets like text field
class Field
  attr_accessor :text, :pos, :spaces
  
  # initalize a field
  # Params:
  # +text+ :: Text to initalize field with
  # +pos+ :: Position to place cursor at
  # +spaces+ :: Allow spaces?
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