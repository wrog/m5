dist_bin_SCRIPTS = m5run doom doom2
EXTRA_DIST = m5run.in doom.in doom2.in

do_subst = \
    sed -e 's,[@]datadir[@],$(datadir),g' \
	-e 's,[@]pkgdatadir[@],$(pkgdatadir),g' \
        -e 's,[@]PACKAGE[@],$(PACKAGE),g' \
        -e 's,[@]VERSION[@],$(VERSION),g' \
        -e 's,[@]CONFIG_SHELL[@],$(CONFIG_SHELL),g'

m5run: m5run.in Makefile
	$(do_subst) < m5run.in > m5run
	chmod +x m5run

doom: doom.in Makefile
	$(do_subst) < doom.in > doom
	chmod +x doom

doom.in: doom.m4 $(top_builddir)/config.status ../LICENSE ../AUTHOR
	$(top_builddir)/config.status doom.in

doom2: doom2.in Makefile
	$(do_subst) < doom2.in > doom2
	chmod +x doom2

doom2.in: doom2.m4 doom.m4 $(top_builddir)/config.status ../LICENSE ../AUTHOR
	$(AUTOM4TE) -l m4sh doom2.m4 > doom2.in
