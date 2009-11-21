#
# rpmspec.rb - RPM SPEC module of LangScan
#
# Copyright (C) 2005 Yoshinori KUNIGA <kuniga@users.sourceforge.net>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of
# the GNU General Public License version 2.
#

require 'langscan/_easyscanner'

module LangScan
  module RPMSpec
    module_function
    def name
      "RPM SPEC"
    end

    def abbrev
      "rpmspec"
    end

    def extnames
      [".spec"]
    end

    # From RPM 4.4.1-21 sources, file build/parsePreamble.c: preambleList[].
    preamble_list = %w(
      name version release epoch serial summary copyright
      license distribution disturl vendor group packager url
      source patch nosource nopatch excludearch exclusivearch
      excludeos exclusiveos icon provides requires prereq
      conflicts obsoletes prefixes prefix buildroot
      buildarchitectures buildarch buildconflicts buildprereq
      buildrequires autoreqprov autoreq autoprov docdir
      rhnplatform disttag
    ).map{|word| [:keyword, "\\A(?i)#{word}\\d*"] }

    # From RPM 4.4.1-21 sources, file build/parseSpec.c: partList[].
    part_list = %w(
      package prep build install check clean preun postun
      pretrans posttrans pre post files changelog description
      triggerpostun triggerun triggerin trigger verifyscript
    ).map{|word| [:keyword, "\\A%#{word}"] }

    other_pattern = [[:comment, "#.*"],
#                    [:string, "'", "'"],
                     [:string, "\"", "\""],
                     [:ident, "%{\\w+}"],
                     [:ident, "%\\w+"],
                     [:word, "[-\\.\\w]+"]
                    ]

    Pattern = preamble_list + part_list + other_pattern

    Types = []

    Keywords = []

    def scan(input, &block)
      scanner = EasyScanner.new(Pattern, Types, Keywords)
      scanner.scan(input, &block)
    end

    LangScan.register(self)
  end
end
