#!/usr/bin/ruby -w

require_relative "plist.rb"

include FT

r8 = Fmach.new("Ruby8")
print "r8 is ready.\n"

FWORDS.keys.each {|k| puts k}

r8.reg(1024, :CODE, FWORDS["+."])

r8.jmp(1024)

dummy = gets.chop.strip.downcase
TOKENS = dummy.split(/\s+/)

TOKENS.each {|t| puts t}