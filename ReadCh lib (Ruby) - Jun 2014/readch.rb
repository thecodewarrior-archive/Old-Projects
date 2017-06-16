# == read_ch.rb
# read a character without pressing enter and without printing to the screen
 
# root module
module ReadCh
  @@keys = {
       " " => :space,
      "\t" => :tab,
      "\r" => :return,
      "\n" => :line_feed,
      "\e" => :escape, # ctrl-[
    "\e[A" => :up_arrow,
    "\e[B" => :down_arrow,
    "\e[C" => :right_arrow,
    "\e[D" => :left_arrow,
    "\177" => :backspace,
# ctrl-* (fold)
    "\037" => :ctrl_underscore,
    "\036" => :ctrl_caret,
    "\035" => :ctrl_close_bracket,
    "\034" => :ctrl_space,
#   "\033" => \e
    "\032" => :ctrl_z,
    "\031" => :ctrl_y,
    "\030" => :ctrl_x,
    "\027" => :ctrl_w,
    "\026" => :ctrl_v,
    "\025" => :ctrl_u,
    "\024" => :ctrl_t,
    "\023" => :ctrl_s,
    "\022" => :ctrl_r,
    "\021" => :ctrl_q,
    "\020" => :ctrl_p,
    "\017" => :ctrl_o,
    "\016" => :ctrl_n,
    "\015" => :ctrl_m,
    "\014" => :ctrl_l,
    "\013" => :ctrl_k,
    "\012" => :ctrl_j,
    "\011" => :ctrl_i,
    "\010" => :ctrl_h,
    "\007" => :ctrl_g,
    "\006" => :ctrl_f,
    "\005" => :ctrl_e,
    "\004" => :ctrl_d,
    "\003" => Proc.new { |args, char|
        if args[:ign_ctrl_c]
          :ctrl_c
        else
          raise Interrupt, args[:ctrl_c_msg]
        end
      },
    "\002" => :ctrl_b,
    "\001" => :ctrl_a,
    "\000" => :ctrl_at,
#(end)
  }
  
  @@keys.default = Proc.new { |args, char|
    case char
      when /^.$/
        :"key_#{char}"
      when nil
        :__error__
      else
        :"other_#{char.inspect}"
    end
  }
  
  
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
      puts "#{ex.class}: #{ex.message :foobar}"
      puts ex.backtrace
    ensure
      # restore previous state of stty
      system "stty #{old_state}"
    end
    return c
  end
  
  def read(arguments={})
    args = {
        :ign_ctrl_c  => false,
        :ctrl_c_msg  => 'Ctrl-C in readch',
        :raw         => false
    }.merge(arguments)
    
    char = read_char
    
    return char if args[:raw]
    
    cval = @@keys[char]
    
    if cval.is_a? Symbol
      return cval
    else
      return cval.call(args,char)
    end
  end
 
  private :read_char
end # module