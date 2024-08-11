# ip utilities for m4sh
#
#  M5_IP_RANDOM
#  M5_IP_RANDOM_WITH_BIT

m4_defun([_M5_IP_FNS_PREPARE],

[AS_REQUIRE_SHELL_FN([m5_fn_ip_lo_from_n],[
AS_FUNCTION_DESCRIBE([m5_fn_ip_lo_from_n], [N],
[Convert ordinal N to a loopback IP address.
Assign it to m5_ip])
],
[[  as_fn_arith $][1 '/' 65536 '%' 256
  m5_ip=127.$as_val
  as_fn_arith $][1 '/' 256 '%' 256
  m5_ip=$m5_ip.$as_val
  as_fn_arith $][1 '%' 256
  m5_ip=$m5_ip.$as_val]])

AS_REQUIRE_SHELL_FN([m5_fn_ip_lo_to_n],[
AS_FUNCTION_DESCRIBE([m5_fn_ip_lo_to_n], [IP],
[Convert loopback IP address to an ordinal.
Return it in as_val])
],
[[  as_val=0]
  AS_CASE([[$][1]],
[[    127.*]],
[[      _m5_rest=`expr X"$][1" : 'X127\+[.]\?\(.*\)'`
      while test "$_m5_rest"; do
         _m5_q=`expr X"$_m5_rest" : 'X\([0-9]\+\)'`]
         AS_IF([[test "$_m5_q"]],
           [],[AS_ERROR([not a valid IP address: $_m5_rest])])[
         as_fn_arith $as_val '*' 256 '+' $_m5_q
         _m5_rest=`expr X"$_m5_rest" : 'X[0-9]\+[.]\?\(.*\)'`
      done]],
[  AS_ERROR([not a valid loopback IP address: $][1])])
])

AS_REQUIRE_SHELL_FN([m5_fn_b_to_min_n],[
AS_FUNCTION_DESCRIBE([m5_fn_b_to_min_n], [B],
[Return lowest usable loopback IP address that has bit B set
as an ordinal; assign it to as_val])
],
[  M5_SHIFT([1],[<<],[$][1])[
  if test "$][1" -ge 2; then
    as_fn_arith $as_val '+' 1
  fi
]])

AS_REQUIRE_SHELL_FN([m5_fn_b_to_max_n],[
AS_FUNCTION_DESCRIBE([m5_fn_b_to_max_n], [B],
[Return highest usable loopback IP address that has bit B set
as an ordinal; assign it to as_val])
],
[  M5_SHIFT([1],[<<],[$][1])[
  if test "$][1" -gt 0; then
    as_fn_arith \( $as_val '-' 1 \) '*' 2
  fi
]])

])dnl -- end of _M5_IP_FNS_PREPARE

# M5_IP_RANDOM_WITH_BIT(B)
# ---------------------
# as_val = randomly chosen loopback IP address with bit B set
# Use this for probing whether the loopback range extends
# this far up.  Rightmost bit is numbered 0.
#
m4_defun_init([M5_IP_RANDOM_WITH_BIT],
[AS_REQUIRE([_M5_IP_FNS_PREPARE], [], [M4SH-INIT-FN])],
[[m5_fn_b_to_min_n ]$1[
_m5_ip_rwb_lo=$as_val
m5_fn_b_to_max_n ]$1
M5_RANDOM_RANGE([[$_m5_ip_rwb_lo]],[[$as_val]])[
m5_fn_ip_lo_from_n $as_val]])

# M5_IP_RANDOM(B)
# ---------------------
# as_val = randomly chosen loopback IP address
# assuming the netmask allows using up to bit B.
# Use this for selecting a random loopback address
# once the range is known.  Rightmost bit is numbered 0.
#
m4_defun_init([M5_IP_RANDOM],
[AS_REQUIRE([_M5_IP_FNS_PREPARE], [], [M4SH-INIT-FN])],
[[m5_fn_b_to_max_n ]$1
M5_RANDOM_RANGE([[1]],[[$as_val]])[
m5_fn_ip_lo_from_n $as_val]])
