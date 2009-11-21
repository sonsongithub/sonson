SUBDIRS  = catalog doc gonzui langscan tests .
bin_SCRIPTS =	gonzui-db \
		gonzui-import \
		gonzui-remove \
		gonzui-search \
		gonzui-server \
		gonzui-update
noinst_SCRIPTS = langscan-test license-test
EXTRA_DIST  =	$(bin_SCRIPTS) $(noinst_SCRIPTS) \
		gonzui.rb.in langscan.rb gonzuirc.sample.in.in

rubylibdir = $(rubydir)
rubylib_DATA =	gonzui.rb langscan.rb
CLEANFILES = gonzui.rb gonzuirc.sample

sysconf_DATA = gonzuirc.sample
gonzuistatedir = $(localstatedir)/gonzui

GONZUI_LOGDIR = $(LOGDIR)/gonzui

gonzui.rb: gonzui.rb.in Makefile
	rm -f gonzui.rb
	sed -e 's!%VERSION%!$(VERSION)!g' \
	    -e 's!%SYSCONFDIR%!$(sysconfdir)!g' \
	    -e 's!%PKGDATADIR%!$(pkgdatadir)!g' \
	    -e 's!%GONZUI_URI%!$(GONZUI_URI)!g' \
	    -e 's!%HTTP_PORT%!$(HTTP_PORT)!g' \
		gonzui.rb.in > gonzui.rb
	chmod -w gonzui.rb

gonzuirc.sample.in: gonzuirc.sample.in.in
	ruby gonzui-db --gonzuirc gonzuirc.sample.in.in --dump-config \
		> gonzuirc.sample.in

gonzuirc.sample: gonzuirc.sample.in Makefile
	rm -f gonzuirc.sample
	sed	-e 's!%LOCALSTATEDIR%!$(gonzuistatedir)!g' \
	   	-e 's!%PKGDATADIR%!$(pkgdatadir)!g' \
		-e 's!%RUNDIR%!$(RUNDIR)!g' \
		-e 's!%LOGDIR%!$(GONZUI_LOGDIR)!g' \
		-e 's!%USER%!$(USER)!g' \
		-e 's!%GROUP%!$(GROUP)!g' \
		-e 's!%HTTP_PORT%!$(HTTP_PORT)!g' \
		gonzuirc.sample.in > gonzuirc.sample

install-data-local:
	mkdir -p $(DESTDIR)$(gonzuistatedir)
	mkdir -p $(DESTDIR)$(GONZUI_LOGDIR)
	if test "$$UID" = 0; then \
	    chown -R $(USER)  $(DESTDIR)$(gonzuistatedir); \
	    chgrp -R $(GROUP) $(DESTDIR)$(gonzuistatedir); \
        fi
	chmod 750 $(DESTDIR)$(gonzuistatedir)

gettext:
	@ruby gonzui/gettext.rb catalog \
              gonzui/*.rb gonzui/webapp/*.rb langscan/*.rb |\
		grep -v "^tests"

dist-check:
	make dist
	tar zxf $(distdir).tar.gz
	cd $(distdir) && \
	./configure &&	make && \
	make check && make dist
	tar ztf $(distdir).tar.gz | sort > tmp.1
	tar ztf $(distdir)/$(distdir).tar.gz | sort > tmp.2
	cmp tmp.1 tmp.2 && rm -f tmp.1 tmp.2
	rm -rf $(distdir)
