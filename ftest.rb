#!/usr/bin/ruby -w

require_relative "rbforth.rb"

include FT

require_relative "r8setup.rb"

include R8Set

puts LIN75
print "START of Ruby8 Forth testing\n"
puts LIN75

print "hit a key to continue.."
k = STDIN.getc

loop do
  if !STATUS[:INIT].nil?
    if STATUS[:INIT] == :WARM  # setup and reregister TIB
    
      STATUS[:INIT] = :RESET
    end
    if STATUS[:INIT] == :RESET  
    
      STATUS[:INIT] = :ABORT
    end    
    if STATUS[:INIT] == :ABORT  # clear and rest DS
      FWORDS["xS"].x
      STATUS[:INIT] = :QUIT
    end
    if STATUS[:INIT] == :QUIT   #clear and reset RT, TIB, Tokens
      FWORDS["xR"].x
      FWORDS["xIn"].x
      tokens = []
      STATUS[:INIT] = nil
    end
  end
  
  puts "STACKS"
  R8.dstack(:DS)
  R8.dstack(:RT)
  
  print "\nrbF>"
  dummy = gets.chop.strip.downcase
  tokens = dummy.split(/\s+/)
  
  tokens.each do |t| 
    if t =~ /^(\d+)/              # decimal conversion -32768 to 32767
      res = Faddr.new($1.to_i)
      R8.push(:DS, res)
    elsif t =~ /^\$([A-F0-9]+)/   # hex conversion of $xxxx
      res = 0
      $1.bytes do |b|
        s = (b < 58 ? b - 48 : b - 55)
        res *= 16
        res += s
      end
      res2 = Faddr.new(res)
      R8.push(:DS, res2)
    elsif t =~ /^\%([01]+)/         # binary conversion of %bbbbbbb
      res = 0
      $1.bytes do |b|
        res *= 2
        res += 1 if b == 49
      end
      res2 = Faddr.new(res)
      R8.push(:DS, res2)      
    elsif FWORDS.has_key?(t)
      FWORDS[t].x
    else
      raise "!UNKNOWN WORD"
    end      
  end
  
  tokens = []
  break if STATUS[:INIT] == :BYE
end
