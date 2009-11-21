AC_INIT(gonzui-db)
AM_INIT_AUTOMAKE(gonzui, 1.2)

HTTP_PORT=46984 
GONZUI_URI="http://gonzui.sourceforge.net/"
AC_SUBST(HTTP_PORT)
AC_SUBST(GONZUI_URI)

AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_MAKE_SET
AM_MAINTAINER_MODE
AM_PATH_RUBY
AM_RUN_LOG_DIRS
AM_USER_GROUP
AM_CHECK_RUBY_VERSION(1.8.2)
AM_CHECK_RUBY_LIB(bdb, http://raa.ruby-lang.org/project/bdb)
AM_CHECK_RUBY_LIB(webrick, http://raa.ruby-lang.org/project/webrick)
AM_CHECK_RUBY_LIB(iconv)
AM_CHECK_RUBY_LIB(zlib, http://raa.ruby-lang.org/project/ruby-zlib)
AM_CHECK_RUBY_LIB(strscan, http://raa.ruby-lang.org/project/strscan)

AC_PATH_PROG(OCAMLC,   ocamlc,   no)
AC_PATH_PROG(OCAMLLEX, ocamllex, no)
AM_CONDITIONAL(OCAML_AVAILABLE, test "$OCAMLC" != no -a "$OCAMLLEX" != no)

AC_OUTPUT([	Makefile
                catalog/Makefile
                doc/Makefile
                gonzui/Makefile
                gonzui/cmdapp/Makefile
                gonzui/webapp/Makefile
                langscan/Makefile
                langscan/brainfuck/Makefile
                langscan/brainfuck/test/Makefile
                langscan/c/Makefile
                langscan/c/test/Makefile
                langscan/css/Makefile
                langscan/css/test/Makefile
                langscan/java/Makefile
                langscan/java/test/Makefile
                langscan/javascript/Makefile
                langscan/javascript/test/Makefile
                langscan/ocaml/Makefile
		langscan/ocaml/test/Makefile
                langscan/pairmatcher/Makefile
                langscan/perl/Makefile
                langscan/php/Makefile
                langscan/php/test/Makefile
                langscan/python/Makefile
                langscan/python/test/Makefile
                langscan/rpmspec/Makefile
                langscan/rpmspec/test/Makefile
                langscan/ruby/Makefile
                langscan/ruby/test/Makefile
                langscan/sh/Makefile
                langscan/sh/test/Makefile
                tests/Makefile
                tests/foo/Makefile
                ])
