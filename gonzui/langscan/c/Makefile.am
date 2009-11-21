# 
# We avoid using extconf.rb because it's not friendly with autotools.
# Most of RUBY_* variables should be set at configure time.
#

SUBDIRS = test

#
# Configure substitution is used here because we cannot
# define LANGSCAN_C_DLLIB by c.$(RUBY_DLEXT).
#
LANGSCAN_C_DLLIB	= c.@RUBY_DLEXT@
LANGSCAN_C_OBJS		= c.o ctok.o
LANGSCAN_C_SRCS		= ctok.c.dist ctok.l tokenlist.txt

rubyarchlibdir	= $(rubyarchdir)/langscan/c
rubyarchlib_DATA= $(LANGSCAN_C_DLLIB)

EXTRA_DIST	= README $(LANGSCAN_C_SRCS)
CLEANFILES	= $(rubyarchlib_DATA) *.o ctok.c c.c c.h

c.h: ../_template.h tokenlist.txt
	ruby ../_make_h.rb ../_template.h tokenlist.txt c C

c.c: ../_template.c
	ruby ../_make_c.rb ../_template.c c C

# We do this to workaround flex 2.5.4 issue because our .l
# file could not be processed with flex 2.5.4.
ctok.c: ctok.l c.h
	flex -d -octok.c ctok.l || cp ctok.c.dist ctok.c
	cmp -s ctok.c ctok.c.dist || cp ctok.c ctok.c.dist

c.o: c.h

SUFFIXES = .c .o # for automake 1.4-p6
.c.o:
	$(RUBY_CC) $(RUBY_CFLAGS) $(RUBY_CPPFLAGS) -c $<

$(LANGSCAN_C_DLLIB): $(LANGSCAN_C_OBJS)
	rm -f $@
	$(RUBY_LDSHARED) $(RUBY_DLDFLAGS) -o $@ $(LANGSCAN_C_OBJS) $(RUBY_LIBS)

