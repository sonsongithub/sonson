# 
# We avoid using extconf.rb because it's not friendly with autotools.
# Most of RUBY_* variables should be set at configure time.
#

SUBDIRS = test

#
# Configure substitution is used here because we cannot
# define LANGSCAN_PYTHON_DLLIB by python.$(RUBY_DLEXT).
#
LANGSCAN_PYTHON_DLLIB	= python.@RUBY_DLEXT@
LANGSCAN_PYTHON_OBJS	= python.o pythontok.o
LANGSCAN_PYTHON_SRCS	= pythontok.c.dist pythontok.l tokenlist.txt

rubyarchlibdir	= $(rubyarchdir)/langscan/python
rubyarchlib_DATA= $(LANGSCAN_PYTHON_DLLIB)

EXTRA_DIST	= $(LANGSCAN_PYTHON_SRCS)
CLEANFILES	= $(rubyarchlib_DATA) *.o pythontok.c python.c python.h

python.h: ../_template.h tokenlist.txt
	ruby ../_make_h.rb ../_template.h tokenlist.txt python Python

python.c: ../_template.c
	ruby ../_make_c.rb ../_template.c python Python

# We do this to workaround flex 2.5.4 issue because our .l
# file could not be processed with flex 2.5.4.
pythontok.c: pythontok.l
	flex -d -opythontok.c pythontok.l || cp pythontok.c.dist pythontok.c
	cmp -s pythontok.c pythontok.c.dist || cp pythontok.c pythontok.c.dist

python.o: python.h

SUFFIXES = .c .o # for automake 1.4-p6
.c.o:
	$(RUBY_CC) $(RUBY_CFLAGS) $(RUBY_CPPFLAGS) -c $<

$(LANGSCAN_PYTHON_DLLIB): $(LANGSCAN_PYTHON_OBJS)
	rm -f $@
	$(RUBY_LDSHARED) $(RUBY_DLDFLAGS) -o $@ $(LANGSCAN_PYTHON_OBJS) $(RUBY_LIBS)
