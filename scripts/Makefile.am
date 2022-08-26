dist_bin_SCRIPTS = doom

do_subst = \
    sed -e 's,[@]datadir[@],$(datadir),g' \
        -e 's,[@]PACKAGE[@],$(PACKAGE),g' \
        -e 's,[@]VERSION[@],$(VERSION),g'

doom: doom.in Makefile
	$(do_subst) < doom.in > doom
	chmod +x doom

doom.in: doom.m4 $(top_builddir)/config.status ../LICENSE ../AUTHOR
	$(top_builddir)/config.status doom.in
