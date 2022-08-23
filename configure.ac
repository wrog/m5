m4_define([m5_version],m4_esyscmd([build-aux/git-version-gen .tarball-version]))

AC_INIT([m5],[m5_version],[bug-m5@wrog.net])
AC_SUBST([M5_VERSION],[m5_version])
AC_CONFIG_SRCDIR([notes/m5])
AC_CONFIG_FILES([Makefile doc/Makefile])

AC_OUTPUT
