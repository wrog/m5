dist_bin_SCRIPTS = m5run doom doom2
EXTRA_DIST = m5run.in doom.in doom2.in

do_subst = \
    sed -e 's,[@]prefix[@],$(prefix),g' \
        -e 's,[@]bindir[@],$(bindir),g' \
        -e 's,[@]datadir[@],$(datadir),g' \
        -e 's,[@]pkgdatadir[@],$(pkgdatadir),g' \
        -e 's,[@]PACKAGE[@],$(PACKAGE),g' \
        -e 's,[@]PACKAGE_URL[@],$(PACKAGE_URL),g' \
        -e 's,[@]VERSION[@],$(VERSION),g' \
        -e 's,[@]NETCAT[@],$(NETCAT),g' \
        -e 's,[@]NETCAT_CLOSE_EOF[@],$(NETCAT_CLOSE_EOF),g' \
        -e 's,[@]NETCAT_KEEPALIVE[@],$(NETCAT_KEEPALIVE),g' \
        -e 's,[@]M5_MOO_EXEC[@],$(M5_MOO_EXEC),g' \
        -e 's,[@]CONFIG_SHELL[@],$(CONFIG_SHELL),g'

m5run: $(srcdir)/m5run.in Makefile
	$(do_subst) < $(srcdir)/m5run.in > m5run
	chmod +x m5run

doom: doom.in Makefile
	$(do_subst) < doom.in > doom
	chmod +x doom

doom.in: $(srcdir)/doom.m4 $(top_builddir)/config.status $(top_srcdir)/LICENSE $(top_srcdir)/AUTHOR
	$(top_builddir)/config.status doom.in

doom2: doom2.in Makefile
	$(do_subst) < doom2.in > doom2
	chmod +x doom2

doom2.in: $(srcdir)/doom2.m4 $(srcdir)/doom.m4 $(top_builddir)/config.status $(top_srcdir)/LICENSE $(top_srcdir)/AUTHOR
	$(AUTOM4TE) -l m4sh --include=$(srcdir) $(srcdir)/doom2.m4 > doom2.in

maintainer-clean-local:
	rm -f Makefile.in doom.in doom2.in $(dist_bin_SCRIPTS)
