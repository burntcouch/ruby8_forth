#
#  Ruby8 setup
#
#  r8setup.rb
#

module R8Set

DSPtr = 50
RTPtr = 52
InstRet = 54
WorkReg = 56
CurBuf = 58
NxtTok = 60

Temp1 = 62
Temp2 = 64
Temp3 = 66
Temp4 = 68

@@stat = {:INIT => :WARM, :PROC => :INT}

TIB_start = 4 * 256
DS_end = 5*256 + 126
RT_end = 6*256 - 2

R8 = Fmach.new("Ruby8")

R8.addstack(:DS, DS_end - 126, DSPtr, 126, 2)
R8.addstack(:RT, RT_end - 126, RTPtr, 126, 2)
R8.addstack(:TIB, TIB_start, CurBuf, 256, -1)

fa = R8.lda(CurBuf)
R8.sta(NxtTok, fa)

RAMSTART = 6 * 256
HDRSIZE = 6

tokens = []
#
#   initialize words
#
bye = Fword.new("bye")
bye.pproc( Proc.new { STATUS[:INIT] = :BYE })
freset = Fword.new("reset")
freset.pproc( Proc.new { STATUS[:INIT] = :RESET })
fwarm = Fword.new("warm")
fwarm.pproc( Proc.new { STATUS[:INIT] = :WARM })
fquit = Fword.new("quit")
fquit.pproc( Proc.new { STATUS[:INIT] = :QUIT })
fquit = Fword.new("abort")
fquit.pproc( Proc.new { STATUS[:INIT] = :ABORT })
##########################################
dot = Fword.new(".")
dot.pproc( Proc.new { res = R8.pull(:DS) ; print res.hex })
dotS = Fword.new(".S")
dotS.pproc( Proc.new { R8.dstack(:DS) })
dotR = Fword.new(".R")
dotR.pproc( Proc.new { R8.dstack(:RT) })
dotS = Fword.new("xS")
dotS.pproc( Proc.new { 
  s = R8.stacks[:DS]
  p = s[:ptr]
  fpv = Faddr.new(s[:addr].u + s[:len])
  R8.sta(p.addr, fpv)
})
dotR = Fword.new("xR")
dotR.pproc( Proc.new {  
  s = R8.stacks[:RT]
  p = s[:ptr]
  fpv = Faddr.new(s[:addr].u + s[:len])
  R8.sta(p.addr, fpv)
})
xIn = Fword.new("xIn")
xIn.pproc( Proc.new {  
  s = R8.stacks[:TIB]
  p = s[:ptr]
  fpv = Faddr.new(s[:addr].u)
  R8.sta(p.addr, fpv)
  R8.stai(p.addr, Faddr.new(0))
  R8.sta(NxtTok, fpv)  
})
gkey = Fword.new("key")
gkey.pproc( Proc.new { res = STDIN.getc ; R8.push(:DS, res.ord) })
emit = Fword.new("emit")
emit.pproc( Proc.new { res = R8.pull(:DS).asc; print res })
plus = Fword.new("+")
plus.pproc( Proc.new { res = R8.pull(:DS).u + R8.pull(:DS).u ; R8.push(:DS, res) ; res })
minus = Fword.new("-")
minus.pproc( Proc.new { res = -R8.pull(:DS).u + R8.pull(:DS).u ; R8.push(:DS, res)  ; res })
mult = Fword.new("*")
mult.pproc( Proc.new { 
  res = R8.pull(:DS).u * R8.pull(:DS).u 
  R8.push(:DS, res) 
})
divmod = Fword.new("/")
divmod.pproc( Proc.new { 
  res1 = R8.pull(:DS).u
  res2 = R8.pull(:DS).u
  res3,res4 = res2.divmod(res1)
  R8.push(:DS, res4)
  R8.push(:DS, res3) 
})
plusdot = Fword.new("+.")
plusdot.pproc( "+", "." )
s2r = Fword.new(">r")
s2r.pproc( Proc.new { res = R8.pull(:DS).u; R8.push(:RT, res) } )
r2s = Fword.new("r>")
r2s.pproc( Proc.new { res = R8.pull(:RT).u; R8.push(:DS,res) } )
r8map = Fword.new("regmap")
r8map.pproc( Proc.new { R8.dmap } )
########################################
mstore = Fword.new("!")
mstore.pproc( Proc.new { 
  res1 = R8.pull(:DS)
  res2 = R8.pull(:DS)
  R8.sta(res2, res1)
})
mfetch = Fword.new("@")
mfetch.pproc( Proc.new { 
  res1 = R8.pull(:DS)
  res2 = R8.lda(res1)
  R8.push(:DS, res2)
})
colon = Fword.new(":")
colon.pproc( Proc.new { 
    rname = tokens.pop
    x = Fword.new(rname)
    add = []
    loop do
      break if tokens.empty?
      t = tokens.pop
      if FWORDS.has_key?(t)
        if t != ";"
          add.push(t)
        else
          add.push("exit")
          break
        end
      else
        Fword.remove(rname)
        raise "!UNKNOWN WORD!"
      end
    end                    
    x.pproc(*add)
})

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

LIN75 = '-' * 75;

print "r8 is ready.\n"
puts LIN75


end  # R8Set