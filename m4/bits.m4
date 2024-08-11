# bit shifting utilities for m4sh
#
# for those of us who want to do << and >>
# even on platforms where $(()) is unavailable
#   M5_SHIFT
#   M5_LOGB

# _m5_arith_works
# --------------
#   = _AS_VAR_ARITH_WORKS in m4sh.m4
#   unless somebody has messed with the latter
#   in a more recent version of autoconf
#
m4_define([_m5_arith_works],
[[(eval "]AS_ESCAPE([test $(( 1 + 1 )) = 2])[") 2>/dev/null]])

# M5_SHIFT(N, OP, B)
# --------
#   M5_SHIFT([n],[<<],[b])  -> as_val=$((n << b))
#   M5_SHIFT([n],[>>],[b])  -> as_val=$((n >> b))
#
m4_defun([_M5_SHIFT_PREPARE],[
AS_FUNCTION_DESCRIBE([m5_fn_shift], [N OP BY],
    [Does as_val=$(( N OP BY )).
OP must be literally << or >> (no quotes).
BY must be non-negative and less than 32.
])

AS_IF([_m5_arith_works],
[[m5_fn_shift () {
    as_fn_arith "$][@"
}]],
[[m5_fn_shift () {
    _m5_n=$][1
    _m5_by=$][3]
    AS_IF([[test "$][2" = "<<"]],[[_m5_op='*' ]],[[_m5_op='/' ]])[
    set x 16 65536 8 256 4 16 2 4 1 2
    shift
    while test $][@%:@ -gt 0; do
]      AS_IF([[test $_m5_by -ge $][1]],
 [      AS_VAR_ARITH([[_m5_by]],[[$_m5_by '-' $][1]])
        AS_VAR_ARITH([[_m5_n]],[[$_m5_n "$_m5_op" $][2]])])[
      shift
      shift
    done
    as_val=$_m5_n
}]])])

m4_defun_init([M5_SHIFT],
[AS_REQUIRE([_M5_SHIFT_PREPARE], [], [M4SH-INIT-FN])],
[m5_fn_shift $1 '$2' $3])
# ------------ end of M5_LOGB


# M5_LOGB(N)
# --------
#   M5_LOGB([n])  -> as_val=$(( floor ( log2 ( n ) ) ))
#
# Assuming N is within the range [1.. 2^32-1],
# find the position of the highest-order set bit
# and assign it to $as_val.

m4_defun([_M5_LOGB_PREPARE],
[AS_REQUIRE_SHELL_FN([m5_fn_logb],[
AS_FUNCTION_DESCRIBE([m5_fn_logb], [N],
    [Does as_val=floor(log_2(N)).
N must be positive and less than 2^32.
])],
[[  _m5_n=$][1
  _m5_by=0
  set x 16 65536 8 256 4 16 2 4 1 2
  shift
  while test $][@%:@ -gt 0; do
    ]AS_IF([[test $_m5_n -ge $][2]],
 [    AS_VAR_ARITH([[_m5_by]],[[$_m5_by '+' $][1]])
      AS_VAR_ARITH([[_m5_n]], [[$_m5_n '/' $][2]])])[
    shift
    shift
  done
  as_val=$_m5_by]])
])

m4_defun_init([M5_LOGB],
[AS_REQUIRE([_M5_LOGB_PREPARE], [], [M4SH-INIT-FN])],
[m5_fn_logb $1])
# ------------ end of M5_LOGB
