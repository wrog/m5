dnl -*- Autoconf -*-
# M5_PROG_NETCAT
# --------------
# Try to find a Netcat program.
# Set the three output variables:
#   NETCAT - program name (or path, if necessary)
#   NETCAT_KEEPALIVE - flags for not shutting down on stdin EOF
#     which is the default for nc.traditional and nc.openbsd
#   NETCAT_CLOSE_EOF - flags for shutting down on stdin EOF
#     which is the default for ncat
#     which is why this is complicated
#
# User may already be pointing us to a netcat with
#   --with-netcat=FILENAME
# and we'll try to figure out which one it is.
#
# Or it's already in the cache.
# Or user has given up on us and
# is setting the output variables directly.
# Or we're doing the full-ass search.
#
dnl
dnl _M5_PROG_NETCAT_WHICH([netcat])
dnl    which netcat is this?  Filename will not tell us.
dnl    Names like 'netcat' and 'nc' typically get remapped.
dnl
m4_define([_M5_PROG_NETCAT_WHICH],[[
  _m5_match=`"$]$1[" -h 2>&1 | \
    $EGREP 'nmap[.]org|OpenBSD|connect to somewhere'`]
  AS_CASE([[$_m5_match]],[[
    *nmap.org*]],[[
      _m5_nc_rank=1
      _m5_nc_cleof=
      _m5_nc_keepa="--no-shutdown"
     ]],[[
    OpenBSD*]],[[
      _m5_nc_rank=2
      _m5_nc_cleof="-N"
      _m5_nc_keepa=
     ]],[[
    *' 'somewhere:*]],[[
      _m5_nc_rank=3
      _m5_nc_cleof="-q 0"
      _m5_nc_keepa=
     ]],[[
      _m5_nc_rank=0
     ]])])dnl
dnl
AC_DEFUN_ONCE([M5_PROG_NETCAT],[dnl
dnl
  AC_REQUIRE([AC_PROG_EGREP])dnl
dnl
  AC_ARG_VAR([NETCAT],
[The 'Netcat' implementation to use, which is required, and can be
either (1) the Nmap project's 'ncat', (2) OpenBSD's 'nc.openbsd',
or (3) traditional netcat a.k.a. 'nc[.traditional]' (preferred).
Normally, you should use --with-netcat=PROGRAM to switch Netcats,
However, if your desired version of Netcat is not one where we know
which arguments do what, you will need to set this and the other
NETCAT_ variables manually.])dnl
dnl
  AC_ARG_VAR([NETCAT_CLOSE_EOF],
[Netcat arguments to pass to ensure that Netcat
shuts down upon reaching (local) stdin EOF.
Set this directly only if --with-netcat=PROGRAM, which is intended
to set all NETCAT* variables consistently, does not work.])dnl
dnl
  AC_ARG_VAR([NETCAT_KEEPALIVE],
[Netcat arguments to pass to ensure that Netcat
does *NOT* shut down upon reaching (local) stdin EOF.
Set this directly only if --with-netcat=PROGRAM, which is intended
to set all NETCAT* variables consistently, does not work.])dnl
dnl
  AC_ARG_WITH([netcat],
    AS_HELP_STRING([--with-netcat=PROGRAM],
    [specify Netcat program to use (see NETCAT below)]),dnl
dnl
dnl user supplies '--with-netcat=...'
dnl
[   AS_IF([[test "$withval" = "no"]],[
      AC_MSG_ERROR([[Sorry, netcat is required.]])])
    AC_PATH_PROG([NETCAT],[[$withval]])
    test "$NETCAT" ||
      AC_MSG_ERROR(
[[Cannot find Netcat program '$withval'; giving up]])
    _M5_PROG_NETCAT_WHICH([[NETCAT]])
    AS_IF([[test $_m5_nc_rank -le 0]],[
      AC_MSG_ERROR(
[[Cannot tell which version of Netcat '$NETCAT' is.
You may need to set all of NETCAT, NETCAT_KEEPALIVE,
and NETCAT_CLOSE_EOF individually.]])])
    [m5_cv_NETCAT_close_eof="$_m5_nc_cleof"
    m5_cv_NETCAT_keep_alive="$_m5_nc_keepa"]],[dnl
dnl
dnl user does NOT supply '--with-netcat=...'
dnl
    AS_IF([[${ac_cv_path_NETCAT+false} : && test "$NETCAT"]],[dnl
      # assume user knows what she is doing
dnl    in this case AC_PATH_PROGS_FEATURE_CHECK only does
dnl   ac_cv_path_NETCAT="$NETCAT"
[     m5_cv_NETCAT_close_eof="$NETCAT_CLOSE_EOF"
      m5_cv_NETCAT_keep_alive="$NETCAT_KEEPALIVE"]])
    AC_CACHE_CHECK([for netcat/ncat],[ac_cv_path_NETCAT],dnl
dnl      either ac_cv_path_NETCAT is set (from the cache),
dnl        in which case m5_cv_NETCAT* will be as well,
dnl        and AC_PATH_PROGS_FEATURE_CHECK does nothing
dnl      or NETCAT is already set and
dnl        prior AS_IF did what is needed
dnl        and AC_PATH_PROGS_FEATURE_CHECK does nothing
dnl      or NETCAT is also not set
dnl        and we need to do the full search
      [[_m5_nc_maxrank=0]
      AC_PATH_PROGS_FEATURE_CHECK([NETCAT],
        [[nc.traditional nc.openbsd netcat nc ncat]],[dnl
dnl
        _M5_PROG_NETCAT_WHICH([[ac_path_NETCAT]])
        AS_IF([[test $_m5_nc_rank -gt $_m5_nc_maxrank]],[[
          ac_cv_path_NETCAT="$ac_path_NETCAT"
          _m5_nc_maxrank="$_m5_nc_rank"
          m5_cv_NETCAT_close_eof="$_m5_nc_cleof"
          m5_cv_NETCAT_keep_alive="$_m5_nc_keepa"
          test $_m5_nc_rank -ge 3 && ac_path_NETCAT_found=:]])],[dnl

        AC_MSG_ERROR(
[cannot find any recognizable version of Netcat; giving up])])])])dnl
dnl end of AC_ARG_WITH
dnl
  [NETCAT="$ac_cv_path_NETCAT"
  NETCAT_CLOSE_EOF="$m5_cv_NETCAT_close_eof"
  NETCAT_KEEPALIVE="$m5_cv_NETCAT_keep_alive"]
  AC_SUBST([NETCAT])
  AC_SUBST([NETCAT_CLOSE_EOF])
  AC_SUBST([NETCAT_KEEPALIVE])
])#
# ------------ end of M5_PROG_NETCAT
