#
# css.rb - a CSS module of LangScan
#
# Copyright (C) 2005 Kouichirou Eto <2005 at eto.com>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'langscan/_easyscanner'

module LangScan
  module CSS
    module_function
    def name
      "CSS"
    end

    def abbrev
      "css"
    end

    def extnames
      [".css"]
    end

    Pattern = [
      [:comment, "/\\*", "\\*/"],
      [:string, "\"", "[^\\\\]\""],
      [:string, "\\(", "[^\\\\]\\)"],
      [:keyword, "\\!\s*important"],
#     [:ident, "[-@\\.\\#\\>\\w]+"],
      [:ident, "[-@\\w]+"],
      [:integer, "\\d[\\.\\w\\d%]+"],
      [:punct, "\\."],
      [:punct, "\\#"],
      [:punct, "\\{"],
      [:punct, "\\}"],
      [:punct, "\\:"],
      [:punct, "\\;"],
    ]

    Types = []

    Keywords = %w(
      url
      @import
      important
    )

    def goback(new_tokens)
      for i in 0...new_tokens.length
	past_token = new_tokens[new_tokens.length-1-i] # take it from the last
	if past_token
	  if past_token.type == :ident || past_token.type == :keyword
	    past_token.type = :fundef
	  end

	  if past_token.type == :punct &&
	      (past_token.text == "}" || past_token.text == ";")
	    break
	  end
	end
      end
    end

    def parse_token(t, new_tokens)
      last_token = new_tokens.last
      return if last_token.nil?

      return unless t.type == :punct and last_token.type == :ident

      if t.text == ':'
	last_token.type = :keyword
	return
      end

      if t.text == '{'
	goback(new_tokens)
	return
      end
    end

    def scan(input, &block)
      scanner = EasyScanner.new(Pattern, Types, Keywords)

      tokens = []
      scanner.scan(input) {|t|
	tokens << t
      }

      new_tokens = []
      tokens.each {|t|
	parse_token(t, new_tokens)
	new_tokens << t
      }

      new_tokens.each {|t|
	yield t
      }
    end

    LangScan.register(self)
  end
end
