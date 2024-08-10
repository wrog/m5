m4_define([m5_version],m4_esyscmd([build-aux/git-version-gen .tarball-version]))
AC_INIT([M5],[m5_version],[bug-m5@wrog.net],[m5],[https://wrog.net/moo/m5])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIRS([m4])
AM_INIT_AUTOMAKE([-Wall -Werror foreign no-texinfo.tex])
AC_CONFIG_SRCDIR([lib/Raw.db.top])
AC_PROG_YACC
M5_PROG_NETCAT
AC_SUBST([CONFIG_SHELL])
AC_CONFIG_FILES([Makefile scripts/Makefile doc/Makefile])
AC_CONFIG_COMMANDS([scripts/doom.in],
  [m4_pushdef([AS_MESSAGE_FD],[1])dnl
m4_include([scripts/optshell.m4])dnl
m4_divert_push([KILL])
m4_include([scripts/options.m4])dnl
m4_divert_pop([KILL])
AS_INIT_GENERATED([scripts/doom.in], [[#
m5_legal_msg="]AS_ESCAPE([$(cat <<])['ENDLEGAL']
m4_include([AUTHOR])
m4_include([LICENSE])
ENDLEGAL
)"
[m5_version]="@VERSION@"
[m5_website]="@PACKAGE_URL@"
[prefix]="@prefix@"
[bindir]="@bindir@"
[pkgdatadir]="@pkgdatadir@"
]) || { AS_ECHO(["failed to create doom.in"]); AS_EXIT; }
m4_pushdef([AS_MESSAGE_LOG_FD],[2])dnl
cat >> scripts/doom.in <<\__EOF__
m4_include([scripts/doom.m4])dnl
__EOF__
m4_popdef([AS_MESSAGE_LOG_FD],[AS_MESSAGE_FD])
])dnl -- end of AC_CONFIG_COMMANDS
AC_PROG_GREP
AC_PROG_EGREP
AC_PROG_FGREP
AC_CONFIG_TESTDIR([tests],[scripts])
AC_CONFIG_FILES([tests/Makefile tests/atlocal])
AM_MISSING_PROG([AUTOM4TE], [autom4te])
AC_OUTPUT
