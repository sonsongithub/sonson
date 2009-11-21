# 
# We avoid using extconf.rb because it's not friendly with autotools.
# Most of RUBY_* variables should be set at configure time.
#

SUBDIRS = test

#
# Configure substitution is used here because we cannot
# define LANGSCAN_JAVASCRIPT_DLLIB by javascript.$(RUBY_DLEXT).
#
LANGSCAN_JAVASCRIPT_DLLIB	= javascript.@RUBY_DLEXT@
LANGSCAN_JAVASCRIPT_OBJS	= javascript.o javascripttok.o
LANGSCAN_JAVASCRIPT_SRCS	= javascripttok.c.dist javascripttok.l tokenlist.txt

rubyarchlibdir	= $(rubyarchdir)/langscan/javascript
rubyarchlib_DATA= $(LANGSCAN_JAVASCRIPT_DLLIB)

EXTRA_DIST	= $(LANGSCAN_JAVASCRIPT_SRCS)
CLEANFILES	= $(rubyarchlib_DATA) *.o javascripttok.c javascript.c javascript.h

javascript.h: ../_template.h tokenlist.txt
	ruby ../_make_h.rb ../_template.h tokenlist.txt javascript JavaScript

javascript.c: ../_template.c
	ruby ../_make_c.rb ../_template.c javascript JavaScript

# We do this to workaround flex 2.5.4 issue because our .l
# file could not be processed with flex 2.5.4.
javascripttok.c: javascripttok.l
	flex -d -ojavascripttok.c javascripttok.l || cp javascripttok.c.dist javascripttok.c
	cmp -s javascripttok.c javascripttok.c.dist || cp javascripttok.c javascripttok.c.dist

javascript.o: javascript.h

SUFFIXES = .c .o # for automake 1.4-p6
.c.o:
	$(RUBY_CC) $(RUBY_CFLAGS) $(RUBY_CPPFLAGS) -c $<

$(LANGSCAN_JAVASCRIPT_DLLIB): $(LANGSCAN_JAVASCRIPT_OBJS)
	rm -f $@
	$(RUBY_LDSHARED) $(RUBY_DLDFLAGS) -o $@ $(LANGSCAN_JAVASCRIPT_OBJS) $(RUBY_LIBS)
