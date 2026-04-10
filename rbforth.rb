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
    include Comparable
    attr_accessor :val
    
    def chkvala(vee)
      v = nil
      if !vee.nil?
        if vee.is_a?(Integer)
          v= vee % 65536
        end
      end
      return v
    end
    
    def initialize(val)
      @val = nil
      if val.is_a?(Integer)
        @val = chkvala(val)
      elsif val.is_a?(Faddr)
        @val = val.val
      end
      @val
    end
    
    def Faddr.b(hb, lb)
      new(hb.u * 256 + lb.u)
    end
    
    def <=>(v)
     if val.is_a?(Integer)
        return self.val.u <=> chkvala(v)
     elsif val.is_a?(Faddr)
        return self.val <=> v
     end 
    end
    
    def inc(v=1)
      ve = v.nil? ? 1 : v
      @val = chkvala(ve + self.u)
      self
    end
    
    def dec(v=1)
      ve = v.nil? ? 1 : v
      @val = chkvala(self.u - ve)
      self
    end
    
    def hb
      h,l = @val.divmod(256)
      return Fbyte.new(h)
    end
    
    def lb
      h,l = @val.divmod(256)
      return Fbyte.new(l)
    end
    
    def hex
      d = @val
      res = ""
      (0..3).each do |i|
        break if d == 0
        d,r = d.divmod(16)
        res = LOOK16[r] + res
      end
      return res.length == 4 ? res : "0" * (4 - res.length) + res
    end
    
    def u
      return @val
    end
  end
  
  class Fbyte
    include Comparable
    attr_accessor :val
    
    def initialize(val)
      @val = chkval8(val)
    end
    
    def inc(v=1)
      ve = v.nil? ? 1 : v
      @val = chkval8(@val + ve) 
    end
    
    def dec(v=1)
      ve = v.nil? ? 1 : v
      @val = chkval8(@val - ve) 
    end
    
    def <=>(v)
      self.u <=> v
    end
    
    def hex
      a, b = self.u.divmod(16)
      return LOOK16[a]+LOOK16[b]
    end
    
    def asc
      res = ""
      a = self.u
      res = ASCP[a]
      res = "\r" if a == 10
      res = "\n" if a == 13 
      return res      
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
       return res
    end
    
  end  # class Fword
  
  class Flabel
    attr_accessor :name, :addr
    
    def initialize(name, addr)
      @name = name
      @addr = Faddr.new(addr) 
    end
    
    def upd(uaddr)
      @addr = Faddr.new(uaddr);
    end
    
  end
 
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
        @mem[a] = Fbyte.new(0)
        print "." if a % 256 == 255
      end
      print "\n"
    end
    
    def getnames(addr)  # returns list of names
      fa = addr
      if !addr.is_a?(Faddr)
        fa = Faddr.new(addr)
      end
      names = []
      if @map.has_key?(fa.u)
        h = @map[fa.u]
        names = h[:name]
      end
      if name.empty?
        @labels.keys.each do |k|
          if @labels[k].u == fa.u
            names.push(k)
          end
        end
      end
      return names
    end
    
    def getaddr(lname)
      if @labels.has_key?(lname)
        addr = @labels[lname]
        return addr
      end
      return nil
    end
    
    def addlabel(lname, addr)
      fa = addr
      fa = Faddr.new(addr) if !addr.is_a?(Faddr)
      if !@labels.has_key?(lname) 
        @labels[lname] = Flabel.new(lname,fa)
      else
        raise "#{lname}: DUP LABEL!"
      end
    end
    
    def laddr(lname)
      @labels[lname].addr
    end
    
    def addstack(sname, addr, paddr, len, siz)
      fa = addr; fpa = paddr
      fa = Faddr.new(addr) if !addr.is_a?(Faddr)
      fpa = Faddr.new(paddr) if !paddr.is_a?(Faddr)
      fpv = Faddr.new(addr + len)
      s = Hash.new
      @stacks[sname] = s
      lname = sname.to_s + "_ptr"
      self.addlabel(lname, fpa)
      s[:name] = sname
      s[:ptr] = @labels[lname]
      s[:addr] = fa
      s[:siz] = siz
      s[:len] = len
      self.reg(s[:addr], :STACK, s)
      self.sta(fpa, fpv)           # initialize stack pointer
    end
    
    def inclbl(lname, v=nil)
      if @labels.has_key?(lname)
        siz = v.nil? ? 1 : v
        p = @labels[lname]
        fa = self.lda(p)
        fa.inc(siz)
        sta(p.addr, fa)
      end        
    end
    
    def declbl(lname, v=nil)
      if @labels.has_key?(lname)
        siz = v.nil? ? 1 : v
        p = @labels[lname]
        fa = self.lda(p)
        fa.dec(siz)
        sta(p.addr, fa)
      end
    end
    
    def incptr(s, v=nil)
      siz = v.nil? ? s[:siz] : v
      p = s[:ptr]
      fa = self.lda(p.addr)
      fa.inc(siz)
      sta(p.addr, fa)
    end
    
    def decptr(s, v=nil)
      siz = v.nil? ? s[:siz] : v
      p = s[:ptr]
      fa = self.lda(p.addr)
      fa.dec(siz)
      sta(p.addr, fa)
    end
    
    def sp(sname)
      s = @stacks[sname]
      p = s[:ptr]
      return p.addr
    end
    
    def pull(sn)
      s = @stacks[sn]
      p = s[:ptr]
      res = nil
      stend = s[:addr].u + s[:len]
      pa = self.lda(p.addr)
      if pa.u <= stend - s[:siz]
        incptr(s)
        if s[:siz] == 1 
           res = self.ldi(s[:ptr].addr)
        else  
           res = self.ldai(s[:ptr].addr)
        end
      else
          raise "#{sn} POINTER ERROR!"    
      end
      return res
    end
    
    def push(sn, val)
      s = @stacks[sn]
      p = s[:ptr]
      stend = s[:addr].u + s[:len]
      pa = self.lda(p.addr)     
      if (pa.u <= stend) && (pa.u > s[:addr].u + s[:siz])
        if s[:siz] == 1 
          self.sti(p.addr, val)
        else
          self.stai(p.addr, val)
        end
        decptr(s)
      else
          raise "#{sn} POINTER ERROR!" 
      end     
    end
    
    def jmp(jto)
      addr = nil
      if @labels.has_key?(jto)
        addr = @labels[jto]
      elsif @map.has_key?(jto.u)
        if @map[jto.u][:what] == :CODE
          c = @map[jto.u][:obj]
          c.x
        else
           raise "#{addr} - BAD CODE!"
        end
      end
    end
    
    def jmpi(jto)
      iaddr = nil
      if @labels.has_key?(jto)
        addr = @labels[jto]
        lb = @mem[addr.u]
        hb = @mem[addr.inc.u]
      else 
        lb = @mem[jto.u]
        hb = @mem[jto.inc.u]
      end
      iaddr = Faddr.b(hb, lb)
      jmp(iaddr)    
    end
    
    def regupd(addr, newa)
      h = @map[addr.u]
      @map.delete(addr.u)
      @map[newa.u] = h
    end
    
    def reg(addr, what, obj)
      h = Hash.new
      fa = Faddr.new(addr)
      h[:what] = what
      h[:obj] = obj
      @map[fa.u] = h
    end
    
    def unreg(lora)
      addr = @labels.has_key?(lora) ? @labels[lora].addr : lora
      addr = Faddr.new(addr)
      @map.delete(addr.u)
    end
    
    def ld(lora)
      addr = @labels.has_key?(lora) ? @labels[lora].addr : lora
      addr = Faddr.new(addr)
      return @mem[addr.u]
    end
    
    def lda(lora)
      iaddr = @labels.has_key?(lora) ? @labels[lora].addr : lora
      iaddr = Faddr.new(iaddr)
      lb = @mem[iaddr.u]
      iaddr.inc
      hb = @mem[iaddr.u]
      return Faddr.b(hb, lb)
    end
    
    def ldx(lora, off)
      addr = @labels.has_key?(lora) ?  @labels[lora].addr : lora
      addr = Faddr.new(addr)
      addr.inc(off)
      return @mem[addr.u]
    end
    
    def ldi(lora)
      addr = @labels.has_key?(lora) ?  @labels[lora].addr : lora
      addr = Faddr.new(addr)
      lb = @mem[addr.u]
      addr.inc
      hb = @mem[addr.u]  # note!  little-endian storage
      iaddr = Faddr.new(hb.u * 256 + lb.u)
      return @mem[iaddr.u]
    end
    
    def ldai(lora)
      addr = @labels.has_key?(lora) ?  @labels[lora].addr : lora
      addr = Faddr.new(addr)
      lb = @mem[addr.u]
      addr.inc
      hb = @mem[addr.u]  # note!  little-endian storage
      iaddr = Faddr.new(hb.u * 256 + lb.u)
      lb = @mem[iaddr.u]
      iaddr.inc
      hb = @mem[iaddr.u]
      return Faddr.b(hb, lb)
    end
    
    def st(lora, val)
      addr = @labels.has_key?(lora) ?  @labels[lora].addr : lora
      addr = Faddr.new(addr)
      vee = val
      if !val.is_a?(Fbyte)
        vee = Fbyte.new(val)
      end
      @mem[addr.u] = vee
    end
    
    def stx(lora, off, val)
      addr = @labels.has_key?(lora) ?  @labels[lora].addr : lora
      addr = Faddr.new(addr)
      addr.inc(off)
      vee = val
      if !val.is_a?(Fbyte)
        vee = Fbyte.new(val)
      end
      @mem[addr.u] = vee
    end
    
    def sta(loraa, vala)
      addra = @labels.has_key?(loraa) ? @labels[loraa].addr : loraa
      addra = Faddr.new(addra)
      if vala.is_a?(Faddr)
        hbd, lbd = vala.hb, vala.lb
      else
        fa = Faddr.new(vala)
        hbd, lbd = fa.hb, fa.lb
      end      
      @mem[addra.u] = lbd
      addra.inc
      @mem[addra.u] = hbd        # note!  little-endian storage
    end
    
    def stai(loraa, vala)
      addra = @labels.has_key?(loraa) ? @labels[loraa].addr : loraa
      addra = Faddr.new(addra)
      if vala.is_a?(Faddr)
        hbd, lbd = vala.hb, vala.lb
      else
        fa = Faddr.new(vala)
        hbd, lbd = fa.hb, fa.lb
      end
      lb = @mem[addra.u]
      addra.inc
      hb = @mem[addra.u]      # note!  little-endian storage
      iaddr = Faddr.new(hb.u * 256 + lb.u)
      @mem[iaddr.u] = lbd
      iaddr.inc
      @mem[iaddr.u] = hbd
    end
    
    def sti(lora, val)
      addr = @labels.has_key?(lora) ?  @labels[lora].addr : lora
      addr = Faddr.new(addr)
      lb = @mem[addr.u]
      hb = @mem[addr.inc.u]    # note!  little-endian storage
      iaddr = Faddr.new(hb.u * 256 + lb.u)
      vee = val
      if !val.is_a?(Fbyte)
        vee = Fbyte.new(val)
      end
      @mem[iaddr.u] = vee
    end 
    
    def dmap
      puts "#{@name} : registered stuff"
      @map.keys.each do |k|
        print "key: #{k} (#{@map[k][:what]}) - #{@map[k][:obj].class}"
        if @map[k][:what] == :CODE
          print "-- #{@map[k][:obj].name} \n"
        else
          print "\n"
        end
      end
    end
    
    def dstack(sname)
      s = @stacks[sname]
      p = s[:ptr]
      pa = self.lda(p.addr)
      bup = pa    # backup pointer address
      
      res = ""
      sitems = 0
      loop do
        if pa.u >= s[:addr].u + s[:len]
           break
        else
           incptr(s)
           pa = self.lda(s[:ptr].addr)
           ia = self.lda(pa)
           res += " #{ia.hex}"
           sitems += 1
        end
      end
      self.sta(p.addr, bup)   # restore pointer address
      
      print "#{sname.to_s}: #{sitems} :"
      if sitems > 0
         print res
      else
         print " (empty)"
      end
      print "\n"      
      
    end
  end

end  # FT

