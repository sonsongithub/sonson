SUBDIRS  =	. \
		brainfuck \
		c \
		css \
		java \
		javascript \
		ocaml \
		pairmatcher \
		perl \
		php \
		python \
		rpmspec \
		ruby \
		sh

if OCAML_AVAILABLE
conditional_rubylib_data = ocaml.rb
endif
rubylibdir = $(rubydir)/langscan
rubylib_DATA =	_common.rb \
		_easyscanner.rb \
		_pairmatcher.rb \
		_type.rb \
		autoconf.rb \
		automake.rb \
		brainfuck.rb \
		c.rb \
		css.rb \
		elisp.rb \
		java.rb \
		javascript.rb \
		perl.rb \
		php.rb \
		python.rb \
		rpmspec.rb \
		ruby.rb \
		sh.rb \
		text.rb \
		$(conditional_rubylib_data)

TEMPLATE_SRCS = _template.c _template.h
noinst_SCRIPTS = _make_c.rb _make_h.rb

EXTRA_DIST = $(rubylib_DATA) $(TEMPLATE_SRCS) $(noinst_SCRIPTS)
CLEANFILES = *.o

SUFFIXES = .c .o # for automake 1.4-p6
.c.o:
	$(RUBY_CC) $(RUBY_CFLAGS) $(RUBY_CPPFLAGS) -c $<
