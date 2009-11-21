rubylib_files =	advsearch.rb \
		filehandler.rb \
		jsfeed.rb \
		markup.rb \
		search.rb \
		source.rb \
		stat.rb \
		top.rb \
		servlet.rb \
		snippet.rb \
		uri.rb \
		webrick.rb

XMLFORMATTER_DLLIB	= xmlformatter.@RUBY_DLEXT@
XMLFORMATTER_OBJS	= xmlformatter.o
XMLFORMATTER_SRCS	= xmlformatter.c

rubylibdir = $(rubydir)/gonzui/webapp
rubylib_DATA =	$(rubylib_files)
rubyarchlibdir	= $(rubyarchdir)/gonzui/webapp
rubyarchlib_DATA= $(XMLFORMATTER_DLLIB)
EXTRA_DIST = $(rubylib_files) $(XMLFORMATTER_SRCS)
CLEANFILES = $(rubyarchlib_DATA) *.o

SUFFIXES = .c .o # for automake 1.4-p6
.c.o:
	$(RUBY_CC) $(RUBY_CFLAGS) $(RUBY_CPPFLAGS) -c $<

$(XMLFORMATTER_DLLIB): $(XMLFORMATTER_OBJS)
	rm -f $@
	$(RUBY_LDSHARED) $(RUBY_DLDFLAGS) -o $@ $(XMLFORMATTER_OBJS) $(RUBY_LIBS)
