#
# automake.rb - Automake module of LangScan
#
# Copyright (C) 2005 Keisuke Nishida <knishida@open-cobol.org>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'langscan/_easyscanner'

module LangScan
  module Automake
    module_function
    def name
      "Automake"
    end

    def abbrev
      "automake"
    end

    def extnames
      [".am"]
    end

    Pattern = [[:comment, "#.*"],
               [:string, "\"", "\""],
               [:string, "'", "'"],
               [:integer, "\\d+"],
               [:ident, "\\w+"],
               [:keyword, "[-\\.\\w]+:"]]

    Types = []

    Keywords = %w(
      if then else elif fi continue for in do done case esac exit
    )

    def scan(input, &block)
      scanner = EasyScanner.new(Pattern, Types, Keywords)
      scanner.scan(input, &block)
    end

    LangScan.register(self)
  end
end
