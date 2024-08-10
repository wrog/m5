
# M5_IF_SOURCE_MOO([IF-FOUND],[IF-NOT_FOUND])
#   find a moo source directory
#   assign cache variable m5_cv_moo_srcdir
#
AC_DEFUN([M5_IF_SOURCE_MOO],
[AC_CACHE_CHECK([for moo source directory],[m5_cv_moo_srcdir],
[[m5_cv_moo_srcdir=no
_m5_pwd=`pwd`]
AS_SET_CATFILE([_m5_srcdir],[[$_m5_pwd]],[[$srcdir]])[
_m5_path=$_m5_srcdir/../Minimal.db
_m5_path=$_m5_path$PATH_SEPARATOR$_m5_srcdir/../*/Minimal.db
m5_save_IFS=$IFS; IFS=$PATH_SEPARATOR
for _m5_mdb in $_m5_path ; do
  IFS=$m5_save_IFS]
  AS_IF([[test -f "$_m5_mdb"]],
[[  # Minimal.db file might be binary crap
    _m5_hd=`dd if="$_m5_mdb" ibs=28 count=1 status=none |
       tr -d -c "!%'*+,-./:;<=>?@[\\]^_{|}~_$as_cr_alnum"`
    # yes, Minimal.db might someday be updated beyond version 1
    ]AS_IF([[test 'X**LambdaMOODatabase,Forma' = "X$_m5_hd"]],
[[    m5_cv_moo_srcdir=`expr "X$_m5_mdb" : 'X\(.*/\)Minimal\.db'`
      break]])])[
done
IFS=$m5_save_IFS]
m4_ifval([$1][$2],
  [AS_IF([[test "$m5_cv_moo_srcdir" = "no"]],
         m4_ifval([$2],[[  $2]]),
         m4_ifval([$1],[[  $1]]))])])])
