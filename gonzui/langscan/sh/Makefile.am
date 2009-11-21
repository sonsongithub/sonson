# 
# We avoid using extconf.rb because it's not friendly with autotools.
# Most of RUBY_* variables should be set at configure time.
#

SUBDIRS = test

#
# Configure substitution is used here because we cannot
# define LANGSCAN_SH_DLLIB by sh.$(RUBY_DLEXT).
#
LANGSCAN_SH_DLLIB	= sh.@RUBY_DLEXT@
LANGSCAN_SH_OBJS	= sh.o shtok.o
LANGSCAN_SH_SRCS	= shtok.c.dist shtok.l tokenlist.txt

rubyarchlibdir	= $(rubyarchdir)/langscan/sh
rubyarchlib_DATA= $(LANGSCAN_SH_DLLIB)

EXTRA_DIST	= $(LANGSCAN_SH_SRCS)
CLEANFILES	= $(rubyarchlib_DATA) *.o shtok.c sh.c sh.h

sh.h: ../_template.h tokenlist.txt
	ruby ../_make_h.rb ../_template.h tokenlist.txt sh Shell

sh.c: ../_template.c
	ruby ../_make_c.rb ../_template.c sh Shell

# We do this to workaround flex 2.5.4 issue because our .l
# file could not be processed with flex 2.5.4.
shtok.c: shtok.l
	flex -d -oshtok.c shtok.l || cp shtok.c.dist shtok.c
	cmp -s shtok.c shtok.c.dist || cp shtok.c shtok.c.dist

sh.o: sh.h

SUFFIXES = .c .o # for automake 1.4-p6
.c.o:
	$(RUBY_CC) $(RUBY_CFLAGS) $(RUBY_CPPFLAGS) -c $<

$(LANGSCAN_SH_DLLIB): $(LANGSCAN_SH_OBJS)
	rm -f $@
	$(RUBY_LDSHARED) $(RUBY_DLDFLAGS) -o $@ $(LANGSCAN_SH_OBJS) $(RUBY_LIBS)
