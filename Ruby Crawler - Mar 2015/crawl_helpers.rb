def init_sputs(sock)
  $sputs_sock = sock
end

def init_lb(sock)
  $loopback=sock
end
def trunc(str,len)
  if str.length > len
    
  else
    str
  end
end

def pad(str,len,side=:right)
  if str == nil
    return ' '*len
  end
  strlen = str.uncolored.length
  padding = len - strlen
  
  if side == :right
    #"%-#{len}s" % str
    return str + ' '*padding
  elsif side == :left
    #"%#{len}s" % str
    return str + ' '*padding
  else
    raise 'pad: invalid side, must be :right or :left'
  end
end

def makewidth(str,len,side=:right)
  pad(trunc(str,len),len,side)
end

def hor_sep_t
  TL + H*(cols-2) + TR
end

def hor_sep_b
  BL + H*(cols-2) + BR
end

def hor_sep_c
  LS + H*(cols-2) + RS
end

def addtocenter(str,insert=CR)
  str[str.length/2-insert.length/2,insert.length] = insert
  str
end

def lrcolumns(lstr,rstr,center=V)
  V + makewidth(lstr,(cols/2)-1) + V + makewidth(rstr,(cols/2)-2) + V
end

def addln(ln)
  $screen_text += "#{ln}\r\n"
end

def addln_nobreak(ln)
  $screen_text += "#{ln}"
end

def lb_refresh
  $loopback.write "lb> refresh"
end

def redraw
  clear
  setpos(0,0)
  refresh
  print $screen_text
  refresh
  $screen_text = ""
end

# def sputs(str)
#   $sputs_sock.write "#{str}\n"
# end