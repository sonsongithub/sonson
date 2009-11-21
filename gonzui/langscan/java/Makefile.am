# 
# We avoid using extconf.rb because it's not friendly with autotools.
# Most of RUBY_* variables should be set at configure time.
#

SUBDIRS = test

#
# Configure substitution is used here because we cannot
# define LANGSCAN_JAVA_DLLIB by java.$(RUBY_DLEXT).
#
LANGSCAN_JAVA_DLLIB	= java.@RUBY_DLEXT@
LANGSCAN_JAVA_OBJS	= java.o javatok.o
LANGSCAN_JAVA_SRCS	= javatok.c.dist javatok.l tokenlist.txt

rubyarchlibdir	= $(rubyarchdir)/langscan/java
rubyarchlib_DATA= $(LANGSCAN_JAVA_DLLIB)

EXTRA_DIST	= $(LANGSCAN_JAVA_SRCS)
CLEANFILES	= $(rubyarchlib_DATA) *.o javatok.c java.c java.h

java.h: ../_template.h tokenlist.txt
	ruby ../_make_h.rb ../_template.h tokenlist.txt java Java

java.c: ../_template.c
	ruby ../_make_c.rb ../_template.c java Java

# We do this to workaround flex 2.5.4 issue because our .l
# file could not be processed with flex 2.5.4.
javatok.c: javatok.l
	flex -d -ojavatok.c javatok.l || cp javatok.c.dist javatok.c
	cmp -s javatok.c javatok.c.dist || cp javatok.c javatok.c.dist

java.o: java.h

SUFFIXES = .c .o # for automake 1.4-p6
.c.o:
	$(RUBY_CC) $(RUBY_CFLAGS) $(RUBY_CPPFLAGS) -c $<

$(LANGSCAN_JAVA_DLLIB): $(LANGSCAN_JAVA_OBJS)
	rm -f $@
	$(RUBY_LDSHARED) $(RUBY_DLDFLAGS) -o $@ $(LANGSCAN_JAVA_OBJS) $(RUBY_LIBS)
