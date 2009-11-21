#
# php.rb - a PHP module of LangScan
#
# Copyright (C) 2005 MATSUNO Tokuhiro <tokuhirom at yahoo.co.jp>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'langscan/php/php'
require 'langscan/_common'

module LangScan
  module PHP
    module_function

    def name
      "PHP"
    end

    def abbrev
      "php"
    end

    def extnames
      [".php"]
    end

    # LangScan::PHP.scan iterates over PHP program.
    # It yields for each element which is interested by gonzui. 
    #
    def scan(input, &block)
      each_fragment(input, &block)
    end

    # LangScan::PHP.each_fragment iterates over PHP-language fragments in _input_.
    # The fragments contains tokens and inter-token spaces and comments.
    #
    # If a String is specified, the String itself is assumed as a PHP-program.
    # If a IO is specified, the content of the IO is assumed as a PHP-program.
    def each_fragment(input) # :yields: token
      begin
        tokenizer = Tokenizer.new(input)
        while token_info = tokenizer.get_token
          type, text, beg_lineno, beg_columnno, beg_byteno, end_lineno, end_columnno, end_byteno = token_info
          token = Fragment.new(type, text, beg_lineno, beg_byteno)
          if (token.type == :ident or token.type == :funcall) and KeywordsHash[token.text]
            token.type = :keyword 
          end
          yield token
        end
      ensure
        tokenizer.close
      end
    end

    Keywords = %w(
		and      or      xor     __FILE__        exception       php_user_filter
		__LINE__        array   as      break   case
		class   const   continue        declare         default
		die     do      echo    else    elseif
		empty   enddeclare      endfor  endforeach      endif
		endswitch       endwhile        eval    exit    extends
		for     foreach         function        global  if
		include         include_once    isset   list    new
		print   require         require_once    return  static
		switch  unset   use     var     while
		__FUNCTION__    __CLASS__       __METHOD__      final   php_user_filter
		interface       implements      extends         public          private
		protected       abstract        clone   try     catch
		throw   cfunction       old_function
		    )
    KeywordsHash = {}
    Keywords.each {|k| KeywordsHash[k] = k }

    LangScan.register(self)
  end
end

