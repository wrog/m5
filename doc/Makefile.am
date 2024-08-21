info_TEXINFOS = m5.texi
m5_TEXINFOS = m5runopt.texi

AM_MAKEINFOFLAGS = --fill-column 79 --no-split -DINFO
AM_MAKEINFOHTML = texi2any --html
AM_MAKEINFOHTMLFLAGS = --split=section \
  --css-ref=https://www.gnu.org/software/gnulib/manual.css \
  --css-ref=common.css \
  --init-file=$(abs_srcdir)/my_html.pm \
  -c HEADER_IN_TABLE=true

all-local: html info

html-local: $(HTMLS)/common.css $(srcdir)/my_html.pm

$(HTMLS)/common.css:
	ln -sf $(abs_srcdir)/common.css $(HTMLS)

m5runopt.texi: $(top_srcdir)/scripts/options.m4 $(top_srcdir)/scripts/opt_maketexi.m4
	rm -f $(srcdir)/m5runopt.texi
	$(AUTOM4TE) -l m4sugar -I $(top_srcdir)/scripts opt_maketexi.m4 > $(srcdir)/m5runopt.texi
	chmod ugo-w $(srcdir)/m5runopt.texi

maintainer-clean-local:
	rm -rf Makefile.in m5.info m5.html m5runopt.texi version.texi config.log
