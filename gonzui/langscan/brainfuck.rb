#
# brainfuck.rb - a Brainfuck module of LangScan
#
# Copyright (C) 2005 MATSUNO Tokuhiro <tokuhirom at yahoo.co.jp>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'langscan/_easyscanner'

module LangScan
  module Brainfuck
    module_function
    def name
      "BrainFuck"
    end

    def abbrev
      "bf"
    end

    def extnames
      [".bf"]
    end

    Pattern = [
	  [:ident, '[<>+\\-.,\[\]]'],
	  [:comment, '[^<>+\\-.,\[\]]+'],
    ]

    Types = []

    Keywords = []

    def scan(input, &block)
      EasyScanner.new(Pattern, Types, Keywords).scan(input) {|t|
		yield t
      }
    end

    LangScan.register(self)
  end
end
