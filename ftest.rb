#!/usr/bin/ruby -w

require_relative "rbforth.rb"

include FT

DSptr = 50
RTptr = 52
InstReg = 54
WorkReg = 56
CurBuf = 58
NxtToken = 60

Temp1 = 62
Temp2 = 64
Temp3 = 66
Temp4 = 68

TIB_start = 4 * 256
DS_end = 5*256 + 126
RT_end = 6*256 - 2

R8 = Fmach.new("Ruby8")

R8.addstack(:DS, DS_end - 126, DSptr, 126, 2)
R8.addstack(:RT, RT_end - 126, RTptr, 126, 2)
R8.addstack(:TIB, TIB_start, CurBuf, 256, -1)

a3 = R8.lda(DSptr)
puts "DSPtr  : "  + a3.hex + "\n\n"

fa = R8.lda(CurBuf)
R8.sta(NxtToken, fa)

RAMSTART = 6 * 256
HDRSIZE = 6

#
#   initialize words
#

dot = Fword.new(".")
dot.pproc( Proc.new { res = R8.pull(:DS).u ; print "TOS: #{res}\n"; res } )
plus = Fword.new("+")
plus.pproc( Proc.new { res = R8.pull(:DS).u + R8.pull(:DS).u ; R8.push(:DS, res) ; res } )
minus = Fword.new("-")
minus.pproc( Proc.new { res = -R8.pull(:DS).u + R8.pull(:DS).u ; R8.push(:DS, res)  ; res } )
mult = Fword.new("*")
mult.pproc( Proc.new { res = R8.pull(:DS).u * R8.pull(:DS).u ; R8.push(:DS, res) ; res } )
divmod = Fword.new("/")
divmod.pproc( Proc.new { 
  res1 = R8.pull(:DS).u; res2 = R8.pull(:DS).u; 
  res3,res4 = res2.divmod(res1); R8.push(:DS, res4); R8.push(:DS, res3) } )
plusdot = Fword.new("+.")
plusdot.pproc( plus, dot )
s2r = Fword.new(">r")
s2r.pproc( Proc.new { res = R8.pull(:DS).u; R8.push(:RT, res) } )
r2s = Fword.new("r>")
r2s.pproc( Proc.new { res = R8.pull(:RT).u; R8.push(:DS,res) } )
mstore = Fword.new("!")
mstore.pproc( Proc.new { FMEM[R8.pull(:DS).u] = R8.pull(:DS).u } )
mfetch = Fword.new("@")
mfetch.pproc( Proc.new { res = FMEM[R8.pull(:DS).u]; R8.push(:DS,res) } )

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
                  
print "r8 is ready.\n"

fmem = RAMSTART
FWORDS.keys.each {|k| 
   print k
   fw = FWORDS[k]
   fad = Faddr.new(fmem)
   R8.reg(fad, :CODE, fw)
   fw.addr = fad
   print " is reg'd at #{fad.hex}\n"
   fmem += HDRSIZE
}

puts "stack pointer for DS is at: " + R8.lda(R8.sp(:DS)).hex
R8.push(:DS, 34)
puts "stack pointer for DS is at: " + R8.lda(R8.sp(:DS)).hex
R8.push(:DS, 23)
puts "stack pointer for DS is at: " + R8.lda(R8.sp(:DS)).hex
R8.push(:DS, 12)
puts "stack pointer for DS is at: " + R8.lda(R8.sp(:DS)).hex
R8.push(:DS, 7)
puts "stack pointer for DS is at: " + R8.lda(R8.sp(:DS)).hex
R8.dstack(:DS)
puts "stack pointer for DS is at: " + R8.lda(R8.sp(:DS)).hex

puts "running plusdot directly"
plusdot.x
R8.dstack(:DS)
puts "jumping to plus dot"
R8.jmp(FWORDS["+."].addr)
R8.dstack(:DS)

R8.dmap

dummy = gets.chop.strip.downcase
TOKENS = dummy.split(/\s+/)

TOKENS.each {|t| puts t}
