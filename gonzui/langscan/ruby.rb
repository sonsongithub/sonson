#
# ruby.rb - a Ruby module of LangScan
#
# Copyright (C) 2004-2005 Akira Tanaka <akr@m17n.org> 
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

if RUBY_VERSION < "1.9.0"
  raise LoadError.new("Ruby 1.9.0 or later is required")
end

require 'langscan/_common'
require 'ripper'

module LangScan
  module Ruby
    module_function
    def name
      "Ruby"
    end

    def abbrev
      "ruby"
    end

    def extnames
      [".rb"]
    end

    def scan(input, &block)
      Parser.new(input).parse(&block)
    end

    class Parser < Ripper
      def initialize(src)
        super
        @fragments = {}
        @found = {}
      end
      attr_reader :fragments

      FragmentType = {
        :rparen => :punct,
        :lbrace => :punct,
        :embexpr_end => :punct,
        :__end__ => :punct,
        :tstring_end => :punct,
        :qwords_beg => :punct,
        :ident => :ident,
        :cvar => :ident,
        :semicolon => :punct,
        :lbracket => :punct,
        :embvar => :punct,
        :backref => :punct,
        :words_beg => :punct,
        :rbrace => :punct,
        :ignored_nl => :punct,
        :embdoc => :punct,
        :sp => :space,
        :lparen => :punct,
        :float => :punct,
        :backtick => :punct,
        :words_sep => :punct,
        :rbracket => :punct,
        :int => :integer,
        :embdoc_beg => :punct,
        :symbeg => :punct,
        :nl => :space,
        :gvar => :ident,
        :comma => :punct,
        :regexp_beg => :punct,
        :ivar => :ident,
        :embdoc_end => :punct,
        :tstring_beg => :punct,
        :op => :punct,
        :heredoc_beg => :punct,
        :comment => :comment,
        :regexp_end => :punct,
        :kw => :keyword,
        :embexpr_beg => :punct,
        :tstring_content => :string,
        :period => :punct,
        :heredoc_end => :punct,
        :const => :const,
        :CHAR => :integer,
      }

      Ripper::SCANNER_EVENTS.each {|ev|
        type = FragmentType[ev]
        define_method("on_#{ev}") {|text|
          key = [lineno, column]
          @fragments[key] = [type, text]
          [text, key]
        }
      }

      def on_class(*args)
        name_key, * = args
        name, key = name_key
        @found[key] = :classdef
      end

      def on_module(*args)
        name_key, * = args
        name, key = name_key
        @found[key] = :moduledef
      end

      def on_def(*args)
        name_key, * = args
        name, key = name_key
        @found[key] = :fundef
      end

      def on_call(recv, _, meth)
        name, key = meth
        @found[key] = :funcall
      end

      def on_symbol_literal(*args)
        name_key, * = args
        name, key = name_key
        @found[key] = :symbol
      end

      def parse
        super
        byteno = 0
        @fragments.keys.sort.each {|key|
          type, text = @fragments[key]
          len = text.length
          l1, c1 = key
          if /\n/ =~ text
            l2 = l1+text.count("\n")
          else
            l2 = l1
          end
          byteno2 = byteno+len
          fragment = Fragment.new(type, text, l1, byteno)
          if type = @found[key]
            fragment.type = type
          end
          yield fragment
          byteno = byteno2
        }
      end
    end

    LangScan.register(self)
  end
end
