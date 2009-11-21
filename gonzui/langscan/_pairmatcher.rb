#
# pairmatcher.rb - a pair matching parser
#
# Copyright (C) 2005 Akira Tanaka <akr@m17n.org> 
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'langscan/_common'
require 'langscan/pairmatcher/pairmatcher'

class Struct::LangScanPair
  def outmost
    ret = self
    while o = ret.outer
      ret = o
    end
    ret
  end
end
