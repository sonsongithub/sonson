#
# c.rb - a C module of LangScan
#
# Copyright (C) 2004-2005 Akira Tanaka <akr@m17n.org> 
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'langscan/c/c'
require 'langscan/_common'
require 'langscan/_pairmatcher'

module LangScan
  module C
    module_function
    def name
      "C/C++"
    end

    def abbrev
      "c"
    end

    def extnames
      [".c", ".h", ".cc", ".cpp"]
    end

    # LangScan::C.scan iterates over C program.
    # It yields for each element which is interested by gonzui. 
    #
    def scan(input, &block)
      pm = LangScan::PairMatcher.new(3,2,2,2)
      pm.define_intertoken_fragment :space, nil
      pm.define_intertoken_fragment :comment, nil
      pm.define_pair :paren, :punct, "(", :punct, ")"
      pm.define_pair :brace, :punct, "{", :punct, "}"
      pm.define_pair :bracket, :punct, "[", :punct, "]"
      pm.define_pair :preproc, :preproc_beg, "#", :preproc_end, "\n"
      pm.parse(LangScan::C::Tokenizer.new(input), lambda {|f|
        if f.type == :ident
          f.type = IdentType[f.text]
        end
        yield f
      }) {|pair|
        if pair.pair_type == :paren
          if 1 <= pair.before_open_length
            fun = pair.around_open(-1)
            if fun.type == :ident && IdentType[fun.text] == :ident
              # ident(...)
              if (outer = pair.outer) && pair.outmost.pair_type == :paren
                # type ident(type (*arg)());
              elsif outer &&
                 outer.pair_type == :preproc &&
                 2 <= outer.after_open_length &&
                 outer.around_open(1).type == :ident && /\Adefine\z/ =~ outer.around_open(1).text &&
                 outer.around_open(2) == pair.around_open(-1)
                # #define ident(...)
                # #define ident (...)
                if pair.around_open(-1).end_byteno == pair.open_token.beg_byteno
                  # #define ident(...)
                  fun.type = :fundef
                end
              elsif !outer ||
                    (!outer.outer && # extern "C" { ... }
                     outer.pair_type == :brace &&
                     2 <= outer.before_open_length &&
                     outer.around_open(-2).type == :ident && /\Aextern\z/ =~ outer.around_open(-2).text &&
                     outer.around_open(-1).type == :string && /\A"C"\z/ =~ outer.around_open(-1).text)
                if 2 <= pair.before_open_length &&
                   pair.around_open(1).type == :punct && pair.around_open(1).text == '(' &&
                   pair.around_close(-1).type == :punct && pair.around_close(-1).text == ')' &&
                   pair.around_open(-2).type == :ident && IdentType[pair.around_open(-2).text] == :ident
                  # ident ident((...))
                  pair.around_open(-2).type = :fundecl
                elsif 1 <= pair.after_close_length &&
                      pair.around_close(1).type == :punct && /\A;\z/ =~ pair.around_close(1).text
                  # ident(...);
                  fun.type = :fundecl
                elsif 1 <= pair.after_close_length &&
                      ((pair.around_close(1).type == :punct && /\A\{\z/ =~ pair.around_close(1).text) || # }
                       (pair.around_close(1).type == :ident))
                  # name(...) { ... }
                  # name(...) int arg; { ... }
                  # name(...) struct tag *arg; { ... }
                  # name(...) typedefed_type arg; { ... }
                  fun.type = :fundef
                else
                  fun.type = :funcall
                end
              else
                if /\Adefined\z/ =~ fun.text &&
                   (outer = pair.outer) &&
                   !outer.outer &&
                   outer.pair_type == :preproc &&
                   1 <= outer.after_open_length &&
                   /\Aif\z/ =~ outer.around_open(1).text
                  # #if ... defined(...)
                else
                  fun.type = :funcall
                end
              end
            end
          end
        end
      }
    end

    Keywords = %w(
      auto break case char const continue default do
      double else enum extern float for goto if int
      long register return short signed sizeof static
      struct switch typedef union unsigned void volatile
      while
    )
    KeywordsHash = {}
    Keywords.each {|k| KeywordsHash[k] = k }

    Types = %w(char double float int long short void)
    TypesHash = {}
    Types.each {|k| TypesHash[k] = k }

    IdentType = Hash.new(:ident)
    Keywords.each {|k| IdentType[k] = :keyword }
    Types.each {|k| IdentType[k] = :type }

    # for debug
    def C.each_fragment(input)
      tokenizer = LangScan::C::Tokenizer.new(input)
      while t = tokenizer.get_token
        yield t
      end
    end

    LangScan.register(self)
  end
end

