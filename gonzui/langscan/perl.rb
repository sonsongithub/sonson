#
# perl.rb - a Perl module of LangScan
#
# Copyright (C) 2005 Tatsuhiko Miyagawa <miyagawa@bulknews.net>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

unless system("perl -MPPI -e 1 2>/dev/null")
  raise LoadError.new("PPI module is required")
end

require 'langscan/_common'

module LangScan
  module Perl
    module_function

    def name
      "Perl"
    end

    def abbrev
      "perl"
    end

    def extnames
      [".pl", ".PL", ".pm", ".t" ] # XXX remove ".t"
    end

    PERLTOKENIZER_PATH = $LOAD_PATH.map {|path|
      File.join(path, "langscan/perl/tokenizer.pl")
    }.find {|path| File.file?(path) }
    raise "tokenizer.pl not found" if PERLTOKENIZER_PATH.nil?

    def shell_escape(file_name)
      '"' + file_name.gsub(/([$"\\`])/, "\\\\\\1") + '"'
    end

    def open_tokenizer 
      command_line = sprintf("perl %s 2>/dev/null", 
                             shell_escape(PERLTOKENIZER_PATH))
      @io = IO.popen(command_line, "r+")
    end

    def scan(input)
      open_tokenizer if @io.nil? or @io.closed? # in case of Perl error
      @io.puts(input.length)
      @io.write(input)
      inputlen = input.length
      buflen   = 0
      begin
        while (buflen < inputlen)
          type    = @io.readline.chomp.intern
          lineno  = @io.readline.chomp.to_i
          byteno  = @io.readline.chomp.to_i
          bodylen = @io.readline.chomp.to_i
          text    = @io.read(bodylen)
          if type.nil? or text.nil? or lineno.nil? or byteno.nil?
            raise ScanFailed.new("Unexpected output from tokenizer.pl")
          end
          yield Fragment.new(type, text, lineno, byteno)
          @io.read(1) # newline
          buflen += bodylen
        end
      rescue EOFError
        @io.close
        raise  ScanFailed.new("tokenizer.pl failed to parse")
      end
    end

    LangScan.register(self)
  end
end



    
    
    
