SUBDIRS  = cmdapp webapp
rubylib_files =	apt.rb \
		bdbdbm.rb \
		cmdapp.rb \
		config.rb \
		content.rb \
		dbm.rb \
		deindexer.rb \
		delta.rb \
		extractor.rb \
		fetcher.rb \
		gettext.rb \
		importer.rb \
		indexer.rb \
		info.rb \
		license.rb \
		logger.rb \
		monitor.rb \
		progressbar.rb \
		remover.rb \
		searcher.rb \
		searchquery.rb \
		searchresult.rb \
		updater.rb \
		util.rb \
		vcs.rb \
		webapp.rb

rubylibdir = $(rubydir)/gonzui
rubylib_DATA =	$(rubylib_files)

TEXTTOKENIZER_DLLIB	= texttokenizer.@RUBY_DLEXT@
TEXTTOKENIZER_OBJS	= texttokenizer.o
TEXTTOKENIZER_SRCS	= texttokenizer.c

DELTA_DLLIB	= delta.@RUBY_DLEXT@
DELTA_OBJS	= delta.o
DELTA_SRCS	= delta.c

AUTOPACK_DLLIB	= autopack.@RUBY_DLEXT@
AUTOPACK_OBJS	= autopack.o
AUTOPACK_SRCS	= autopack.c

rubyarchlibdir	= $(rubyarchdir)/gonzui
rubyarchlib_DATA= $(TEXTTOKENIZER_DLLIB) $(DELTA_DLLIB) $(AUTOPACK_DLLIB)
EXTRA_DIST =	$(rubylib_files) \
		$(TEXTTOKENIZER_SRCS) \
		$(DELTA_SRCS) \
		$(AUTOPACK_SRCS)
CLEANFILES = $(rubyarchlib_DATA) *.o

SUFFIXES = .c .o # for automake 1.4-p6
.c.o:
	$(RUBY_CC) $(RUBY_CFLAGS) $(RUBY_CPPFLAGS) -c $<

$(TEXTTOKENIZER_DLLIB): $(TEXTTOKENIZER_OBJS)
	rm -f $@
	$(RUBY_LDSHARED) $(RUBY_DLDFLAGS) -o $@ $(TEXTTOKENIZER_OBJS) $(RUBY_LIBS)

$(DELTA_DLLIB): $(DELTA_OBJS)
	rm -f $@
	$(RUBY_LDSHARED) $(RUBY_DLDFLAGS) -o $@ $(DELTA_OBJS) $(RUBY_LIBS)

$(AUTOPACK_DLLIB): $(AUTOPACK_OBJS)
	rm -f $@
	$(RUBY_LDSHARED) $(RUBY_DLDFLAGS) -o $@ $(AUTOPACK_OBJS) $(RUBY_LIBS)
