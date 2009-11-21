#
# autoconf.rb - Autoconf module of LangScan
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
  module Autoconf
    module_function
    def name
      "Autoconf"
    end

    def abbrev
      "autoconf"
    end

    def extnames
      [".ac"]
    end

    Pattern = [[:comment, "#.*"],
               [:string, "\"", "\""],
               [:string, "'", "'"],
               [:integer, "\\d+"],
               [:ident, "\\w+"],
               [:keyword, "AC_\\w+"]]

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
