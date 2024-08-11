# random number/string generation

# M5_RANDOM_256H
# --------------
#  as_val=a random 256-bit hex string
#
m4_defun([M5_RANDOM_256H],
[as_val=`{ echo $$ ; date ; dd if=/dev/urandom count=1 bs=16 2>&1 ; } | sha256sum -b | tr -d ' *-'`])

# M5_RANDOM_BITS(N)
# --------------
#  as_val=a random N-bit hex string
#
m4_defun([M5_RANDOM_BITS_PREPARE],
[m4_divert_text([M4SH-INIT-FN],[[
# for m5_fn_random_bits
_m5_rand_r0=0
_m5_rand_r0n=0
_m5_rand_rest=]])
AS_REQUIRE_SHELL_FN([m5_fn_random_bits],[
AS_FUNCTION_DESCRIBE([m5_fn_random_bits], [N],
[Return a random number 0..2^N-1; assign it to as_val])
],[dnl
[  m5_n=$][1
  _m5_rand_r1=0
  _m5_rand_r1n=0]
  AS_IF([[test "$m5_n" -gt $_m5_rand_r0n]],
[[  while : ; do]
      AS_IF([[test "$_m5_rand_rest"]],
[[      _m5_rand_r1n=24
        _m5_rand_r1=`expr X"$_m5_rand_rest"   : 'X\(......\)'`
        _m5_rand_rest=`expr X"$_m5_rand_rest" :   'X......\(.*\)'`]],

[      M5_RANDOM_256H[
        _m5_rand_rest=$as_val
  #     _m5_rand_rest=fedc543210fedcba543210fedcba543210fedcba543210fedcba543210fedcba
  #     _m5_rand_rest=fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210
  #     _m5_rand_rest=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
  #     _m5_rand_rest=ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        _m5_rand_r1n=16
        _m5_rand_r1=`expr   X"$_m5_rand_rest" : 'X\(....\)'`
        _m5_rand_rest=`expr X"$_m5_rand_rest" :   'X....\(.*\)'`]])
      AS_IF([[test $m5_n -le $_m5_rand_r1n]],
[[      _m5_r=`printf "%d" 0x$_m5_rand_r1`
        _m5_rn=$_m5_rand_r1n
        _m5_rand_r1=$_m5_rand_r0 ; _m5_rand_r1n=$_m5_rand_r0n
        _m5_rand_r0=$_m5_r       ; _m5_rand_r0n=$_m5_rn
        break]])
      AS_VAR_ARITH([_m5_0p1],[[$_m5_rand_r1n '+' $_m5_rand_r0n]])
      AS_IF([[test $m5_n -le $_m5_0p1]],
[      # graft n-r0n bits from r1 onto r0
        AS_VAR_ARITH([as_val],[[$m5_n '-' $_m5_rand_r0n]])
        M5_SHIFT([1],[<<],[[$as_val]])[
        _m5_m=$as_val
        _m5_rand_r1=`printf "%d" 0x$_m5_rand_r1`]
        AS_VAR_ARITH([_m5_rand_r0], [[$_m5_rand_r0 '*' $_m5_m '+' $_m5_rand_r1 '%' $_m5_m]])[
        _m5_rand_r0n=$m5_n]
        AS_VAR_ARITH([_m5_rand_r1], [[$_m5_rand_r1 '/' $_m5_m]])
        AS_VAR_ARITH([_m5_rand_r1n],[[$_m5_0p1 '-' $m5_n]])[
        break]])[
      _m5_rand_r0=`printf "0x%x%s" $_m5_rand_r0 $_m5_rand_r1`
      _m5_rand_r0=`printf "%d" $_m5_rand_r0`]
      AS_VAR_ARITH([_m5_rand_r0n],[[$_m5_rand_r0n '+' $_m5_rand_r1n]])[
    done]])
  #  m5_n <= _m5_rand_r0n
  AS_IF([[test $m5_n -lt $_m5_rand_r0n]],
[  M5_SHIFT([1],[<<],[$m5_n])
    [_m5_m=$as_val]
    AS_VAR_ARITH([_m5_return],[[$_m5_rand_r0 '%' $_m5_m]])
    AS_VAR_ARITH([as_val],[[$_m5_rand_r0n '-' $m5_n]])
    M5_SHIFT([1],[<<],[[$as_val]])
    AS_VAR_ARITH([_m5_rand_r0], [[$_m5_rand_r0 '/' $_m5_m '+' \( $_m5_rand_r1 '*' $as_val \)]])
    AS_VAR_ARITH([_m5_rand_r0n], [[$_m5_rand_r1n '+' $_m5_rand_r0n '-' $m5_n]])[
    as_val=$_m5_return]],
[[  as_val=$_m5_rand_r0
    _m5_rand_r0=$_m5_rand_r1 ; _m5_rand_r0n=$_m5_rand_r1n]])])])

m4_defun_init([M5_RANDOM_BITS],
[AS_REQUIRE([M5_RANDOM_BITS_PREPARE],[],[M4SH-INIT-FN])],
[[m5_fn_random_bits ]$1[]])

m4_defun([M5_RANDOM_RANGE_PREPARE],[
AS_REQUIRE_SHELL_FN([m5_fn_random_range],[
AS_FUNCTION_DESCRIBE([m5_fn_random_range], [FROM TO],
[Return a random number FROM..TO; assign it to as_val])
],[dnl
[ _m5_beg=$][1]
  AS_VAR_ARITH([_m5_rand_range],[$][2 '-' $_m5_beg '+' 1])
  AS_IF([[test $_m5_rand_range -lt 2]],[[as_val=$_m5_beg]],[
    AS_VAR_ARITH([as_val],[[$_m5_rand_range '-' 1]])
    M5_LOGB([$as_val])
    AS_VAR_ARITH([as_val],[[$as_val '+' 1]])
    M5_RANDOM_BITS([[$as_val]])
    AS_VAR_ARITH([as_val],[[$as_val '%' $_m5_rand_range '+' $_m5_beg]])])])])

m4_defun_init([M5_RANDOM_RANGE],
[AS_REQUIRE([M5_RANDOM_RANGE_PREPARE],[],[M4SH-INIT-FN])],
[[m5_fn_random_range ]$1[ ]$2[]])

# printf "%d %d %s\n" $(( $rb1 % 256 )) $(( $rb1 / 256 )) $rbits
