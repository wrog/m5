m4_define([m5_version],m4_esyscmd([build-aux/git-version-gen .tarball-version]))
AC_INIT([M5],[m5_version],[bug-m5@wrog.net],[m5],[https://wrog.net/moo/m5])
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([-Wall -Werror foreign no-texinfo.tex])
AC_CONFIG_SRCDIR([lib/Raw.db.top])
AC_PROG_YACC
AC_CONFIG_FILES([Makefile scripts/Makefile])

AC_CONFIG_COMMANDS([scripts/doom.in],
  [m4_pushdef([AS_MESSAGE_FD],[1])dnl
AS_INIT_GENERATED([scripts/doom.in], [[#
m5_legal_msg="]AS_ESCAPE([$(cat <<])['ENDLEGAL']
m4_include([AUTHOR])
m4_include([LICENSE])
ENDLEGAL
)"
[m5_version]="@VERSION@"
]) || { AS_ECHO(["failed to create doom.in"]); AS_EXIT; }
m4_pushdef([AS_MESSAGE_LOG_FD],[2])dnl
cat >> scripts/doom.in <<\__EOF__
m4_include([scripts/doom.m4])
__EOF__
m4_popdef([AS_MESSAGE_LOG_FD],[AS_MESSAGE_FD])
])dnl -- end of AC_CONFIG_COMMANDS

AC_CONFIG_TESTDIR([tests],[bin])

AC_OUTPUT
