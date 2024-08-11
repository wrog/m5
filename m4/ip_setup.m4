# ip configuration macros
#
# M5_IP_LO_SCAN
# -------------
# Scan loopback network for usable addresses
# Set cache variable m5_cv_netlo_bits = highest usable bit
# where rightmost is numbered 0.
#
AC_DEFUN([M5_IP_LO_SCAN],
[AC_REQUIRE([M5_PROG_NETCAT])dnl
AC_CACHE_CHECK([loopback net bitmask],[m5_cv_netlo_bits],
[AS_VAR_ARITH([m5_port],[\( $$ \* 22 \) \% 64493 \+ 1043])
AS_VAR_ARITH([_m5_lo],[m5_port \- 20])[
until]
  AS_ECHO_N('.. ') >&AS_MESSAGE_FD
  M5_NETCAT_TEST_ADDR_PORT([],[[$m5_port]])[
do]
  AS_VAR_ARITH([m5_port],[m5_port - 1]);
  AS_IF([[test $m5_port -le $_m5_lo ]],[[
    m5_port=
    break]])[
done]
AS_VAR_IF([m5_port],[],
[[  m5_cv_netlo_bits=-2]
  AC_MSG_ERROR([could not find an available port])],
[[  _m5_lo=-1
  _m5_hi=24
  while as_fn_arith \( $_m5_hi '+' $_m5_lo '+' 1 \) '/' 2 ;
        test $as_val -lt $_m5_hi; do
    x=$as_val]
    M5_IP_RANDOM_WITH_BIT([[$x]])
    AS_ECHO_N([["($x).. "]]) >&AS_MESSAGE_FD
    AS_IF([M5_NETCAT_TEST_ADDR_PORT([[$m5_ip]],[[$m5_port]])],[[
       _m5_lo=$x
    ]],[[
       _m5_hi=$x
    ]])[
  done
  m5_cv_netlo_bits=$_m5_lo]
  sync
  AS_IF([test $_m5_lo -lt 0],
[[  m5_cv_netlo_bits=-1]
  AC_MSG_ERROR([could not find a usable loopback address])])])])])

# M5_IP_LO_SETUP
# -------------
# Set M5_IP_DEFAULT and M5_IP_LO_SETUP if not already set.
# (each can be inferred from the other, and if neither is
# provided on the command line, we do a scan.)
#
AC_DEFUN([M5_IP_LO_SETUP],[
AC_REQUIRE([M5_PROG_NETCAT])dnl
AC_ARG_VAR([M5_IP_DEFAULT],
[Default IP address to use for all MOO and redirection services;
must be a loopback address])dnl
dnl
AC_ARG_VAR([M5_IP_LO_BITS],
[Range of loopback IP addresses to use (see manual)])dnl
dnl
AS_IF([[test "$M5_IP_DEFAULT"]],[
  AS_IF([[test "$M5_IP_LO_BITS"]],[],[[
    m5_fn_ip_lo_to_n "$M5_IP_DEFAULT"]
    M5_LOGB([[$as_val]])[
    M5_IP_LO_BITS=$as_val]])
],[[test "$M5_IP_LO_BITS"]],[
  M5_IP_RANDOM([["$M5_IP_LO_BITS"]])[
  M5_IP_DEFAULT=$m5_ip
]],[
  M5_IP_LO_SCAN
  [M5_IP_LO_BITS=$m5_cv_netlo_bits]
  M5_IP_RANDOM([["$M5_IP_LO_BITS"]])
  [M5_IP_DEFAULT=$m5_ip]])
AC_SUBST([M5_IP_LO_BITS])
AC_SUBST([M5_IP_DEFAULT])
])
