#
# _easyscanner.rb - simple scanner for LangScan
#
# Copyright (C) 2005 Keisuke Nishida <knishida@open-cobol.org>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'langscan/_common'

module LangScan
  class EasyScanner
    def initialize(pattern, types, keywords)
      @pattern = pattern

      # build regexp
      regexp = "(\n)|" + @pattern.map {|v| "(" + v[1] + ")"}.join("|")
      @regexp = Regexp.new(regexp)

      # build type hash
      @type = {}
      types.each {|k| @type[k] = true }

      # build keyword hash
      @keyword = {}
      keywords.each {|k| @keyword[k] = true }
    end

    def scan(input, &block)
      lineno = 0
      offset = 0
      while match = @regexp.match(input[offset..-1])
        if match[1]
          # newline
          lineno += 1
          offset += match.end(0)
        else
          for i in 2..match.size-1
            if match[i]
              type = @pattern[i-2][0]
              byteno = offset + match.begin(0)
              if @pattern[i-2][2]
                # pattern with terminator
                start = offset + match.end(0)
                end_match = input[start..-1].match(@pattern[i-2][2])
                if end_match
                  offset = start + end_match.end(0)
                else
                  # not terminated! what should we do?
                  offset = start
                end
              else
                # simple pattern
                offset += match.end(0)
              end
              text = input[byteno..offset-1]
              if type == :ident
                case true
                when @type[text]
                  type = :type
                when @keyword[text]
                  type = :keyword
                end
              end
              yield(Fragment.new(type, text, lineno, byteno))
              lineno += text.count("\n")
              break
            end
          end
        end
      end
    end
  end
end

