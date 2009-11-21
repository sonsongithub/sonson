#
# sh.rb - a shellscript module of LangScan
#
# Copyright (C) 2005 Kenichi Ishibashi <bashi at dream.ie.ariake-nct.ac.jp>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'langscan/sh/sh'
require 'langscan/_common'

module LangScan
  module Shell
    module_function
    def name
      "shell script"
    end

    def abbrev
      "sh"
    end

    def extnames
      [".sh"]
    end

    # LangScan::Shell.scan iterates over shell scripts.
    # It yields for each element which is interested by gonzui. 
    def scan(input, &block)
      last_token = nil
      each_fragment(input) {|t|
        if t.type == :ident
          if t.text[0] == ?$
            yield Fragment.new(:punct, '$', t.beg_lineno, t.beg_byteno)
            yield Fragment.new(:ident, t.text[1 .. -1], t.beg_lineno,
                               t.beg_byteno + 1)
            last_token = nil
            next
          end

          if last_token != nil && last_token.type == :keyword && last_token.text == "function"
            t.type = :fundef
          end
        end

        if t.type == :heredoc_end
          blank_len = t.text.rindex(/\s/)
          if blank_len == nil
            yield Fragment.new(:ident, t.text, t.beg_lineno, t.beg_byteno)
          else
            yield Fragment.new(:space, t.text[0 .. blank_len],
                               t.beg_lineno, t.beg_byteno)
            yield Fragment.new(:ident, t.text[blank_len+1 .. -1],
                               t.beg_lineno, t.beg_byteno+blank_len+1)
          end
          next
        end

        t.type = :ident if t.type == :heredoc_beg

        yield t

        if t.type != :space && t.type != :comment
          last_token = t
        end
      }
    end

    # LangScan::Shell.each_fragment iterates over shell script fragments in _input_.
    # The fragments contains tokens and inter-token spaces and comments.
    #
    # If a String is specified, the String itself is assumed as a shell script.
    # If a IO is specified, the content of the IO is assumed as a shell script.
    def each_fragment(input) # :yields: token
      begin
        tokenizer = Tokenizer.new(input)
        while token_info = tokenizer.get_token
          type, text, beg_lineno, beg_columnno, beg_byteno, end_lineno, end_columnno, end_byteno = token_info
          token = Fragment.new(type, text, beg_lineno, beg_byteno)
          if token.type == :ident
            if KeywordsHash[token.text]
              token.type = :keyword 
            end
          end

          yield token
        end
      ensure
        tokenizer.close
      end
    end

    Keywords = %w(
      case do done elif else esac fi for function if in select then until
      while time
    )
    ShBuiltinCommands = %w(
      break cd continue eval exec exit export getopts hash pwd readonly
      return shift test times trap umask unset
    )
    BashBuiltinCommands = %w(
      alias bind builtin caller command declare echo enable help let
      local logout printf read shopt set source type typeset ulimit unalias
    )

    KeywordsHash = {}
    Keywords.each {|k| KeywordsHash[k] = k }
    ShBuiltinCommands.each {|k| KeywordsHash[k] = k }
    BashBuiltinCommands.each {|k| KeywordsHash[k] = k }

    LangScan.register(self)
  end
end
