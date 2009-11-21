# 
# We avoid using extconf.rb because it's not friendly with autotools.
# Most of RUBY_* variables should be set at configure time.
#

SUBDIRS = test

#
# Configure substitution is used here because we cannot
# define LANGSCAN_PHP_DLLIB by php.$(RUBY_DLEXT).
#
LANGSCAN_PHP_DLLIB	= php.@RUBY_DLEXT@
LANGSCAN_PHP_OBJS	= php.o phptok.o
LANGSCAN_PHP_SRCS	= phptok.c.dist phptok.l tokenlist.txt

rubyarchlibdir	= $(rubyarchdir)/langscan/php
rubyarchlib_DATA= $(LANGSCAN_PHP_DLLIB)

EXTRA_DIST	= $(LANGSCAN_PHP_SRCS)
CLEANFILES	= $(rubyarchlib_DATA) *.o phptok.c php.c php.h

php.h: ../_template.h tokenlist.txt
	ruby ../_make_h.rb ../_template.h tokenlist.txt php PHP

php.c: ../_template.c
	ruby ../_make_c.rb ../_template.c php PHP

# We do this to workaround flex 2.5.4 issue because our .l
# file could not be processed with flex 2.5.4.
phptok.c: phptok.l
	flex -F -8 -d -ophptok.c phptok.l || cp phptok.c.dist phptok.c
	cmp -s phptok.c phptok.c.dist || cp phptok.c phptok.c.dist

php.o: php.h

SUFFIXES = .c .o # for automake 1.4-p6
.c.o:
	$(RUBY_CC) $(RUBY_CFLAGS) $(RUBY_CPPFLAGS) -c $<

$(LANGSCAN_PHP_DLLIB): $(LANGSCAN_PHP_OBJS)
	rm -f $@
	$(RUBY_LDSHARED) $(RUBY_DLDFLAGS) -o $@ $(LANGSCAN_PHP_OBJS) $(RUBY_LIBS)
