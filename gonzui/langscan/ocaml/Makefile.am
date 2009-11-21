# We avoid using extconf.rb because it's not friendly with autotools.
# Most of RUBY_* variables should be set at configure time.
#

SUBDIRS = test

#
# Configure substitution is used here because we cannot
# define LANGSCAN_C_DLLIB by c.$(RUBY_DLEXT).
#
CAMLEXER_SRCS		= types.ml lexer.mll camlexer.ml
CAMLEXER_EXEC		= camlexer

rubyarchlibdir	= $(rubyarchdir)/langscan/ocaml
if OCAML_AVAILABLE
rubyarchlib_DATA= $(CAMLEXER_EXEC)
endif

OCAMLC = ocamlc

EXTRA_DIST	= $(CAMLEXER_SRCS)
CLEANFILES	= $(CAMLEXER_EXEC) *.cmi *.cmo lexer.ml

lexer.ml: lexer.mll
	ocamllex lexer.mll

$(CAMLEXER_EXEC): lexer.ml types.ml camlexer.ml
	$(OCAMLC) -o camlexer types.ml lexer.ml camlexer.ml
