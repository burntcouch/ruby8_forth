#!/usr/bin/ruby -w

require_relative "rbforth.rb"

include RbForth

TIBinit

byef = 0

tokens = Array.new


DS.ph(123)
DS.ph(111)

RT.ph(3291)
RT.ph(12345)

	loop do
		dummy = gets.chop.strip.downcase
    tokens = dummy.split(/\s+/)
    ti = 0
    tokens.each do |t|
      t.each_byte do |b|
         TIB[ti] = b
         ti += 1
      end
      TIB[ti] = 32
      ti += 1
    end
    TIB[ti] = 32
    ti += 1
    TIB[ti+1] = 0
    
    tokens.each do |i|
       print i, "\n";
    end
		
    tdump
    
    DS.dump
    RT.dump
    
    byef = 1
		break if byef
	end
  
  