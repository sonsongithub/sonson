# 
# We avoid using extconf.rb because it's not friendly with autotools.
# Most of RUBY_* variables should be set at configure time.
#

#SUBDIRS = test

#
# Configure substitution is used here because we cannot
# define PAIRMATCHER_C_DLLIB by c.$(RUBY_DLEXT).
#
PAIRMATCHER_C_DLLIB	= pairmatcher.@RUBY_DLEXT@
PAIRMATCHER_C_OBJS	= pairmatcher.o
PAIRMATCHER_C_SRCS	= pairmatcher.c

rubyarchlibdir	= $(rubyarchdir)/langscan/pairmatcher
rubyarchlib_DATA= $(PAIRMATCHER_C_DLLIB)

EXTRA_DIST	= $(PAIRMATCHER_C_SRCS)
CLEANFILES	= $(rubyarchlib_DATA) *.o

SUFFIXES = .c .o # for automake 1.4-p6
.c.o:
	$(RUBY_CC) $(RUBY_CFLAGS) $(RUBY_CPPFLAGS) -c $<

$(PAIRMATCHER_C_DLLIB): $(PAIRMATCHER_C_OBJS)
	rm -f $@
	$(RUBY_LDSHARED) $(RUBY_DLDFLAGS) -o $@ $(PAIRMATCHER_C_OBJS) $(RUBY_LIBS)

