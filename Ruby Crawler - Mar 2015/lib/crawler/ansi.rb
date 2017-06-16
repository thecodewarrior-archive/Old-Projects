require 'rubygems'
require 'terminfo'


def gen_escape_seq(char,*vars)
  seq = "\e["
  if vars
    seq += vars.join ';'
  end
  seq += char
  return seq
end


class Cursor

  def self.move(col,row)
    print gen_escape_seq("H",row,col)
  end
  
  def self.save
    print gen_escape_seq('s')
  end
  
  def self.restore
    print gen_escape_seq('u')
  end
  
  def self.up(v=1)
    print gen_escape_seq('A',v)
  end
  
  def self.down(v=1)
    print gen_escape_seq('B',v)
  end
  
  def self.right(v=1)
    print gen_escape_seq('C',v)  
  end
  
  def self.left(v=1)
    print gen_escape_seq('D',v) 
  end
  
end

class Screen

  
  def self.clear(reset_cursor=false)
    Cursor.save unless reset_cursor
    print gen_escape_seq('2J')
    Cursor.restore unless reset_cursor
  end
  
  def self.erase_line(line,col=1)
    Cursor.save
    Cursor.move(row, col)
    print gen_escape_seq('K')
    Cursor.restore
  end
  
  def self.size
    TermInfo.screen_size
  end
  
  def self.columns
    TermInfo.screen_size[1]
  end
  
  def self.lines
    TermInfo.screen_size[0]
  end
  
end