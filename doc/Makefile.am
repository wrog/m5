info_TEXINFOS = M5manual.texi

AM_MAKEINFOFLAGS = --fill-column 79 --no-split -DINFO
AM_MAKEINFOHTML = texi2any --html
AM_MAKEINFOHTMLFLAGS = --output html --split=section --css-ref=common.css

html-local: $(HTMLS)/common.css

$(HTMLS)/common.css:
	ln -sf $(abs_srcdir)/common.css $(HTMLS)
