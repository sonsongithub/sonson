#
# elisp.rb - a elisp module of LangScan
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
  module EmacsLisp
    module_function
    def name
      "Emacs Lisp"
    end

    def abbrev
      "elisp"
    end

    def extnames
      [".el"]
    end

    Pattern = [[:comment, ";.*"],
               # ?A  ?\101  ?\x41  ?\)  ?\\  ?\^Ij  ?\C-j  ?\M-\C-b  ?\H-\M-\A-x
               [:character, "\\?(?:\\\\[CMHsA]-|\\\\^)*(?:\\\\x?[\\da-fA-F]+|\\\\.|.)"],
               [:string, "\"\""],
               [:string, "\"", "(?:[^\\\\]|\\A)(?:\\\\\\\\)*\""],
               [:integer, "\\d+"],
               [:ident, "[-\\w]+"]]

    Types = []

    Keywords = %w(
      defun defvar defmacro defgroup defcustom
      lambda prog1 prog2 progn let if when unless cond catch throw require
    )

    def scan(input, &block)
      scanner = EasyScanner.new(Pattern, Types, Keywords)
      scanner.scan(input, &block)
    end

    LangScan.register(self)
  end
end
