#
# text.rb - a text module of LangScan
#
# Copyright (C) 2004-2005 Satoru Takabayashi <satoru@namazu.org> 
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'langscan/_common'

module LangScan
  module Text
    module_function
    def name
      "Text"
    end

    def abbrev
      "text"
    end

    def extnames
      [".txt"]
    end

    def scan(input, &block)
      yield(Fragment.new(:text, input, 1, 0))
    end

    LangScan.register(self)
  end
end
