#
# ocaml.rb - a OCaml module of LangScan
#
# Copyright (C) 2005 Soutaro Matsumoto <matsumoto@soutaro.com>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

module LangScan
  module OCaml
    CAMLEXER_PATH = $LOAD_PATH.map{|path|
      File.join(path, "langscan/ocaml/camlexer")
    }.find {|path| File.file?(path) }

    class Tokenizer
      SYMBOL_TBL = {
        "text" => :text,
        "ident" => :ident,
        "punct" => :punct,
        "keyword" => :keyword,
        "comment" => :comment,
        "integer" => :integer,
        "float" => :float,
        "string" => :string,
        "character" => :character,
        "funcdef" => :funcdef         # not implemented yet
      }

      def initialize(input)
        @io = IO.popen(CAMLEXER_PATH, "r+")
        @tin = Thread.start {
          input.each {|l|
            @io.puts(l)
          }
          @io.close_write()
        }
      end
      
      def dispose()
        @tin.join()
        @io.close()
      end

      def denormalize(str)
        str.gsub(/([^\\])\\o/,'\1'+"\n")
      end

      def get_token()
        if @io.eof? 
          nil
        else
          lno, cno, tp, wd = @io.gets().chomp().split(":",4)
          Fragment.new(SYMBOL_TBL[tp], denormalize(wd), lno.to_i(), cno.to_i())
        end
      end
      
    end
    
    module_function

    def name
      "Objective Caml"
    end

    def abbrev
      "ocaml"
    end

    def extnames
      [".ml", ".mli", ".mll", ".mly"]
    end

    def scan(input, &block)
      tokenizer = Tokenizer.new(input)
      
      while (tkn = tokenizer.get_token())
        yield tkn
      end
      
      tokenizer.dispose()
    end

    if CAMLEXER_PATH
      LangScan.register(self)
    end
  end
end
