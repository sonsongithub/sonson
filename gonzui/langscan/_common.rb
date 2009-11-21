#
# _common.rb - a part of LangScan
#
# Copyright (C) 2004-2005 Akira Tanaka <akr@m17n.org> 
# Copyright (C) 2004-2005 Satoru Takabayashi <satoru@namazu.org> 
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'langscan/_type'

module LangScan
  class ScanFailed < StandardError; end

  Fragment = Struct.new(
    :type, :text,
    :beg_lineno, :beg_byteno)

  class Fragment
    alias_method :lineno, :beg_lineno
    alias_method :byteno, :beg_byteno
    
    def inspect
      "\#<#{self.class} #{type} #{text.inspect} #{beg_lineno} (#{beg_byteno})>"
    end

    def pretty_print(q)
      q.text inspect
    end

    def end_byteno
      self.beg_byteno + self.text.length
    end
  end

  unless respond_to?(:register)
    # stub
    def register(mod)
    end
    module_function :register
  end
end
