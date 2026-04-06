#!/usr/bin/ruby -w

module FT

  DSTACK = [2,3,4,7]
  RSTACK = []
  TOKENS = []
  FWORDS = Hash.new
  FMEM = Hash.new
  TEMP1 = 0
  TEMP2 = 0
  TEMP3 = 0
  TEMP4 = 0
  TEMP5 = 0
  
  LASTHEAP = 0
  NEXTHEAP = 0

  LOOK16 = "0123456789ABCDEF"

  ASCP = "................" +
    "................" +
    " !\"#$%&'()*+,-./" + 
    "0123456789:;<=>?" + 
    "@ABCDEFGHIJKLMNO" +
    "PQRSTUVWXYZ[\\]^_" +
    "`abcdefghijklmno" +
    "pqrstuvwxyz{|}~." +
    "................" +
    "................" +
    "................" +
    "................" +
    "................" +
    "................" +
    "................" +
    "................"
  
  
  
  class Faddr
    attr_accessor :hb, :lb
    
    def chkvala(vee)
        res = nil
        if !vee.nil?
          if vee.is_a?(Integer)
            vee = vee % 65536
          end
        end
        a,b = vee.divmod(256)
        h, l = Fbyte.new(a), Fbyte.new(b)
        return h, l
    end
    
    def initialize(val)
      @hb, @lb = chkvala(val)
    end
    
    def inc(v=1)
      ve = v.nil? ? 1 : v
      @hb,@lb = chkval(ve + @hb * 256 + @lb)
    end
    
    def dec(v=1)
      ve = v.nil? ? 1 : v
      @hb,@lb = chkval(@hb * 256 + @lb - ve)
    end
    
    def h
      return @hb.h + @lb.h
    end
  end
  
  class Fbyte
    attr_accessor :val
    
    def initialize(val)
      @val = chkval8(val)
    end
    
    def val=(v)
      @val = chkval8(v)
    end
    
    def inc(v=1)
      ve = v.nil? ? 1 : v
      @val = chkval8(@val + ve) 
    end
    
    def dec(v=1)
      ve = v.nil? ? 1 : v
      @val = chkval8(@val - ve) 
    end
    
    def h
      a, b = (@val >= 0 ? @val : 256 + @val).divmod(16)
      return LOOK16[a]+LOOK16[b]
    end
    
    def u
      return @val >= 0 ? @val : 256 + @val
    end
    
    def chkval8(vee)
        res = nil
        if !vee.nil?
          sg = 1
          sg = -1 if vee < 0
          ve = vee.abs
          if ve.is_a? Integer
            ve = ve % 256
            if ve > 127
              ve = 256 - ve
              sg = -sg
            end
            res = ve * sg
          end
        end
        return res
    end
  end
 

  class Fword
    attr_accessor :name, :addr, :cfa
    
    def initialize(name)
       @name = name
       @cfa = Array.new
       @addr = nil
       FWORDS[name] = self
    end
    
    def pproc(*p)             # must be a Proc, or another Fword
       @cfa.push(*p)
    end
    
    def x
       res = 0
       @cfa.each do |p|
          if p.is_a?(Proc)
            res = p.call
          elsif p.is_a?(Fword)
            p.x
          end
       end
    end
    
  end  # class Fword
  
  class Fstack
  
   attr_accessor :st,:name,:ptr,:addr,:ptr
    
    def initialize(name, addr, len)
      @name = name
      @st = Array.new
      @ptr = Faddr.new(nil)
      @addr = Faddr.new(addr)
      @len = Faddr.new(len)
    end
    
    def dump
      if !@st.empty?
        print "#{@name} #{@ptr.x}: "
        si = 0
        loop do
          vv = @st[si]
          if !vv.nil?
            print vv.x
            print " "
            print "\n" if si % 10 == 9
            si = si + 1
          else
            break
          end
        end
        print "\n"
      else 
        print "#{@name} is empty.\n"
      end
    end
    
    def ph(val)
      v = val
      if !val.is_a?(Faddr)
         v = Faddr.new(val)
      end
      @ptr = 0 if @ptr.nil?
      @st.push(v)
      @ptr.inc
      return self
    end
    
    def pli
      pl.i
    end
    
    def pl
      @ptr.dec
      val = nil
      if @ptr < 0
        @ptr = nil
        val = @st[0]
        @st = []
      else
        val = @st.pop
      end
      return val
    end  
  end    # Fstack
 
  class Fmach
    attr_accessor :name, :mem, :map
    
    def initialize(name)
      @name = name
      @mem = Hash.new
      @map = Hash.new
      @stacks = Hash.new
      @labels = Hash.new
      initram
    end
    
    def initram
      print "#{@name} initializing memory:\n"
      (0..65535).each do |a|
        aa = Faddr.new(a)
        @mem[aa] = Fbyte.new(0)
        print "." if a % 256 == 255
      end
      print "\n"
    end
    
    def getname(addr)
      name = nil
      if @map.has_key?(addr)
        h = @map[addr]
        name = h[:name]
      end
    end
    
    def getaddr(lname)
      addr = nil
      @map.keys.each do |k|
        h = @map[k]
        addr = k if h[:name] == lname
      end
      return addr
    end
    
    def addlabel(lname, addr)
      ptr = Hash.new
      ptr[:addr] = addr
      ptr[:name] = lname
      @labels[lname] = ptr
      self.reg(ptr[:addr], :LABEL, ptr)
    end
    
    def addstack(sname, addr, paddr, len, siz)
      s = Hash.new
      ptr = Hash.new
      @stacks[sname] = s
      @labels[sname + "_ptr"] = ptr
      s[:name] = sname
      s[:ptr] = ptr
      s[:addr] = addr
      p[:name] = sname + "_ptr"
      p[:addr] = paddr
      self.sta(paddr, addr + len)   # initialize ptr at end, push back
      s[:siz] = siz
      s[:len] = len
      self.reg(s[:addr], :STACK, s)
      self.reg(ptr[:addr], :LABEL, ptr)
    end
    
    def pl(sn)
      s = @stacks[sn]
      p = s[:ptr]
      res = nil
      if p[:addr] <= s[:addr] + s[:len] - s[:siz]
        if s[:siz] == 1 
           res = self.ldi(p[:addr])
        else  
           res = self.ldai(p[:addr])
        end
        olda = p[:addr]
        p[:addr] += s[:siz]
        self.regupd(olda, p[:addr])
      else
          raise "#{sn} POINTER ERROR!"    
      end
      return res
    end
    
    def ph(sn, val)
      s = @stacks[sn]
      p = s[:ptr]
      if p[:addr] > s[:addr] + s[:siz]
        olda = p[:addr]
        p[:addr] -= s[:siz]
        self.stai(p[:addr], val)
        self.regupd(olda, p[:addr])  
      else
          raise "#{sn} POINTER ERROR!" 
      end     
    end
    
    def jmp(addr)
      if @map.has_key?(addr)
        if @map[addr][:what] == :CODE
          c = @map[addr][:obj]
          c.x
        else
           raise "#{addr} - BAD CODE!"
        end
      end
    end
    
    def jmpi(addr)
      lb = @mem[addr]   # note!  little-endian address storage
      hb = @mem[addr+1]
      iaddr = Faddr.new(hb.u * 256 + lb.u)
      jmp(iaddr)    
    end
    
    def regupd(addr, newa)
      h = @map[addr]
      @map.delete(addr)
      @map[newa] = h
    end
    
    def reg(addr, what, obj)
      h = Hash.new
      h[:what] = what
      h[:obj] = obj
      @map[addr] = h
    end
    
    def unreg(addr)
      @map.delete(addr)
    end
    
    def ld(addr)
      return @mem[addr]
    end
    
    def ldx(addr,off)
      return @mem[addr + off]
    end
    
    def ldi(addr)
      lb = @mem[addr]
      hb = @mem[addr+1]  # note!  little-endian address storage
      iaddr = Faddr.new(hb.u * 256 + lb.u)
      return @mem[iaddr]
    end
    
     def ldai(addr)
      lb = @mem[addr]
      hb = @mem[addr+1]  # note!  little-endian address storage
      iaddr = Faddr.new(hb.u * 256 + lb.u)
      return @mem[iaddr]
    end
    
    def st(addr, val)
      vee = Fbyte.new(0)
      if !val.is_a?(Fbyte)
        vee = Fbyte.new(val)
      end
      @mem[addr] = vee
    end
    
    def stx(addr, off, val)
      vee = Fbyte.new(0)
      if !val.is_a?(Fbyte)
        vee = Fbyte.new(val + off)
      end
      @mem[addr] = vee + off
    end
    
    def sta(addra, addrd)
      lb, hb = addrd.divmod 256
      @mem[addra] = lb
      @mem[addra+1] = hb
    end
    
    def stai(addra, addrd)
      lbd, hbd = addrd.divmod 256
      lb = @mem[addra]
      hb = @mem[addra+1]
      iaddr = Faddr.new(hb.u * 256 + lb.u)
      @mem[iaddr] = lbd
      @mem[iaddr+1] = hbd
    end
    
    def sti(addr, val)
      lb = @mem[addr]
      hb = @mem[addr+1]    # note!  little-endian address storage
      iaddr = Faddr.new(hb.u * 256 + lb.u)
      @mem[iaddr] = val
    end 
    
    def dump(addr, addr2)
    
    end
  end
  


  
  dot = Fword.new(".")
  dot.pproc( Proc.new { res = DSTACK.pop; print "TOS: #{res}\n"; res } )
  plus = Fword.new("+")
  plus.pproc( Proc.new { res = DSTACK.pop + DSTACK.pop; DSTACK.push(res) ; res } )
  minus = Fword.new("-")
  minus.pproc( Proc.new { res = -DSTACK.pop + DSTACK.pop; DSTACK.push(res) ; res } )
  minus = Fword.new("*")
  minus.pproc( Proc.new { res = DSTACK.pop * DSTACK.pop; DSTACK.push(res) ; res } )
  minus = Fword.new("/")
  minus.pproc( Proc.new { res1 = DSTACK.pop; res2 = DSTACK.pop; res3,res4 = res2.divmod(res1); DSTACK.push(res4); DSTACK.push(res3) } )
  plusdot = Fword.new("+.")
  plusdot.pproc( plus, dot )
  s2r = Fword.new(">r")
  s2r.pproc( Proc.new { res = DSTACK.pop; RSTACK.push(res) } )
  r2s = Fword.new("r>")
  r2s.pproc( Proc.new { res = RSTACK.pop; DSTACK.push(res) } )
  mstore = Fword.new("!")
  mstore.pproc( Proc.new { FMEM[DSTACK.pop] = DSTACK.pop } )
  mfetch = Fword.new("@")
  mfetch.pproc( Proc.new { res = FMEM[DSTACK.pop]; DSTACK.push(res) } )
  
  
  colon = Fword.new(":")
  colon.pproc( Proc.new { rname = TOKENS.pop; 
                  x = Fword.new(rname); add = [];
                  loop do
                    break if TOKENS.empty?
                    t = TOKENS.pop
                    if t != ";"
                      add.push(t)
                    else
                      add.push("exit")
                      break
                    end
                  end                    
                  x.pproc(*add)
                  } )
  
end  # FT

