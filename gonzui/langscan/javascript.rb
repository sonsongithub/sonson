#
# javascript.rb - a JavaScript module of LangScan
#
# Copyright (C) 2004-2005 Keisuke Nishida <knishida@open-cobol.org>
# Copyright (C) 2005 Kouichirou Eto <2005 at eto.com>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'langscan/javascript/javascript'
require 'langscan/_common'
require 'langscan/_pairmatcher'

module LangScan
  module JavaScript
    module_function
    def name
      "JavaScript"
    end

    def abbrev
      "js"
    end

    def extnames
      [".js"]
    end

    # LangScan::JavaScript.scan iterates over JavaScript program.
    # It yields for each element which is interested by gonzui. 
    #
    def scan(input, &block)
      pm = LangScan::PairMatcher.new(1,0,0,1)
      pm.define_intertoken_fragment :space, nil
      pm.define_intertoken_fragment :comment, nil
      pm.define_pair :paren, :punct, "(", :punct, ")"
      pm.define_pair :brace, :punct, "{", :punct, "}"
      pm.define_pair :bracket, :punct, "[", :punct, "]"
      pm.parse(LangScan::JavaScript::Tokenizer.new(input), lambda {|f|
        if f.type == :ident
          f.type = IdentType[f.text]
        end
        yield f
      }) {|pair|
        if pair.pair_type == :paren &&
           1 <= pair.before_open_length &&
           pair.around_open(-1).type == :ident && IdentType[pair.around_open(-1).text] == :ident
          before_open_token = pair.around_open(-1)
          if !KeywordsHash[before_open_token.text]
            if !(outer = pair.outer) || !outer.outer
              if 1 <= pair.after_close_length &&
                 pair.around_close(1).type == :punct &&
                 pair.around_close(1).text == '{'
                before_open_token.type = :fundef
              else
                before_open_token.type = :funcall
              end
            else
              before_open_token.type = :funcall
            end
          end
        end
      }
    end

    Keywords = %w(
      break else new var
      case finally return void
      catch for switch while
      continue function this with
      default if throw
      delete in try
      do instanceof typeof
      null true false
    )
    KeywordsHash = {}
    Keywords.each {|k| KeywordsHash[k] = k }

    Types = []
    TypesHash = {}
    Types.each {|k| TypesHash[k] = k }

    IdentType = Hash.new(:ident)
    Keywords.each {|k| IdentType[k] = :keyword }
    Types.each {|k| IdentType[k] = :type }

    LangScan.register(self)
  end
end

