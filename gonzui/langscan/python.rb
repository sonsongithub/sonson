#
# python.rb - a python module of LangScan
#
# Copyright (C) 2005 Yoshinori K. Okuji <okuji@enbug.org>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'langscan/python/python'
require 'langscan/_common'

module LangScan
  module Python
    module_function
    def name
      "Python"
    end

    def abbrev
      "python"
    end

    def extnames
      [".py"]
    end

    # LangScan::Python.scan iterates over Python program.
    # It yields for each element which is interested by gonzui. 
    #
    def scan(input, &block)
      last_token = nil
      each_fragment(input) {|t|
        if t.type == :space
          yield t
          next
        end
        if last_token
          if t.type == :ident and last_token.type == :keyword
            case last_token.text
            when 'def'
              t.type = :fundef
            when 'class'
              t.type = :classdef
            end
          elsif t.type == :punct and t.text == '(' and last_token.type == :ident
            last_token.type = :funcall
          end
          yield last_token
          last_token = nil
        end
        if t.type == :ident or t.type == :keyword
          last_token = t
        else
          yield t
        end
      }
      if last_token
        yield last_token
      end
    end

    # LangScan::Python.each_fragment iterates over Python-language fragments in _input_.
    # The fragments contains tokens and inter-token spaces and comments.
    #
    # If a String is specified, the String itself is assumed as a Python-program.
    # If a IO is specified, the content of the IO is assumed as a Python-program.
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
      and assert break class continue def del elif else except exec finally
      for from global if import in is lambda not or pass print raise return
      try while yield
    )
    FutureKeywords = %w(
      as None
    )
    KeywordsHash = {}
    Keywords.each {|k| KeywordsHash[k] = k }
    FutureKeywords.each {|k| KeywordsHash[k] = k }

    LangScan.register(self)
  end
end
