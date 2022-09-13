dnl
dnl Macro definitions for use in m5run.m4 to
dnl to convert option and section declarations
dnl into help text and AS_CASE arguments
dnl
dnl ------------
dnl  parameters
dnl ------------
dnl
m4_define([M5_HELP_WIDTH],[36])dnl -- width for AS_HELP_STRING
dnl
dnl -----------------------------------------
dnl  section declarations
dnl -----------------------------------------
dnl
dnl M5_HELP_SECTION([Header])
dnl   start of a new section 'Header options'
dnl
m4_define([M5_HELP_SECTION],
[m4_append([M5_HELP_OPTION_LINES],[

[$1 options]m4_ifval($2,[ ($2)],[])[:]])])dnl
dnl
dnl -----------------------------------------
dnl  option declarations
dnl -----------------------------------------
dnl
dnl M5_OPTION_INFOBOOLEAN([h],[help],[msg],[?],[code])
dnl   informational boolean,
dnl     normally false
dnl     ANY mention (any of +h,-h,-?,--help) means true and
dnl       code (that will generally exit) should be invoked
dnl     no mention means false, do nothing, run normally
dnl
m4_define([M5_OPTION_INFOBOOLEAN],
[m4_append([M5_HELP_OPTION_LINES],
  [AS_HELP_STRING(m4_ifval($1,[[[-$1, +$1, ]]],[[[        ]]])dnl
m4_ifval($4,[[[-$4, ]]],[])[[--$2]],[$3],M5_HELP_WIDTH)],[
])dnl
m4_append([M5_OPTION_CASES],[dnl
  m4_ifval($1,[[[-$1 | +$1 | ]]],[])dnl
m4_ifval($4,[[[-[$4] | ]]],[])[M5_LONG_OPT_PATTERN([$2])],[
    M5_VAR_DECR([[arg_count]])
    $5
  ],])])dnl
dnl
dnl M5_OPTION_BOOLEAN([s],[long],[helpmsg],[default],[do_it])
dnl   regular boolean option
dnl     +s or --long     means  true
dnl     -s or --no-long  means  false
dnl   and complain about multiple conflicting settings
dnl
m4_define([M5_OPTION_BOOLEAN],
[m4_append([M5_HELP_OPTION_LINES],
  [AS_HELP_STRING([[+$1, -$1, -(-no)-$2]],
   m4_ifval([$4],[[$3 [$4]]],[[$3]]),M5_HELP_WIDTH)],[
])dnl
m4_append([M5_OPTION_CASES],[[[
  +$1 | ]M5_LONG_OPT_PATTERN([$2])],[
AS_CASE([[$]$5],[[false]],[[conflict "-$1|--no-$2"]])
    $5[=:
  ]],[[
  -$1 | ]M5_LONG_OPT_PATTERN([no-$2])],[
AS_CASE([[$]$5],[[:]],[[conflict "+$1|--$2"]])
    $5[=false
  ]],])])dnl
dnl
dnl  M5_OPTION_VALUE([s],[long],[pname],[helpmsg],[default],[var])
dnl    regular value option
dnl      '--long=value' or '-s value'  sets  var=value
dnl
m4_define([M5_OPTION_VALUE],
[m4_append([M5_HELP_OPTION_LINES],
  [AS_HELP_STRING(m4_ifval($1,[[[-$1,]]],[   ])[[ --$2=]$3],
    m4_ifval([$5],[[$4 [$5]]],[[$4]]),M5_HELP_WIDTH)],[
])dnl
m4_append([M5_OPTION_CASES],[[
  M5_LONG_OPT_PATTERN([$2=*])],[
    $6[="$argument"
  ]],m4_ifval($1,[[[
  -$1]],[[
    test $][# -gt 1 || usage "$][1: ]$3[ missing"
    shift]
    $6[="$][1"
  ]],],[])])])dnl
dnl
dnl  M5_OPTION_NEGVALUE([s],[long],[pname],[helpmsg],[default],[var])
dnl    value option that can be null
dnl      '--long=value'  sets  var='value'
dnl      '-s value'      sets  var='value'
dnl      '--no-long'     sets  var=''  (empty string)
dnl
m4_define([M5_OPTION_NEGVALUE],
[m4_append([M5_HELP_OPTION_LINES],
  [AS_HELP_STRING(m4_ifval($1,[[[-$1,]]],[   ])[[ --(no-)$2=]$3],
    m4_ifval([$5],[[$4 [$5]]],[[$4]]),M5_HELP_WIDTH)],[
])dnl
m4_append([M5_OPTION_CASES],[[
  M5_LONG_OPT_PATTERN([no-$2])],[
    $6[=
  ]],[
  M5_LONG_OPT_PATTERN([$2=*])],[
    $6[="$argument"
  ]],m4_ifval($1,[[[
  -$1]],[[
    test $][# -gt 1 || usage "$][1: ]$3[ missing"
    shift]
    $6[="$][1"
  ]],],[])])])dnl
dnl
dnl  M5_OPTION_PUSH([s],[long],[pname],[helpmsg],[default],[pushfn])
dnl    option that can be invoked multiple times
dnl    to push values onto a list
dnl      invoke 'pushfn value' each time
dnl
m4_define([M5_OPTION_PUSH],
[m4_append([M5_HELP_OPTION_LINES],
  [AS_HELP_STRING(m4_ifval($1,[[[-$1,]]],[   ])[[ --$2=]$3],
    m4_ifval([$5],[[$4 [$5]]],[[$4]]),M5_HELP_WIDTH)],[
])dnl
m4_append([M5_OPTION_CASES],[[
  M5_LONG_OPT_PATTERN([$2=*])],[
    $6[ "$argument"
  ]],m4_ifval($1,[[[
  -$1]],[[
    test $][# -gt 1 || usage "$][1: ]$3[ missing"
    shift]
    $6[ "$][1"
  ]],],[])])])dnl
dnl
dnl  M5_OPTION_END([--],[helpmsg],[code])
dnl    -- indicates end of options
dnl    code should do something useful with remaining arguments
dnl
m4_define([M5_OPTION_END],
[m4_append([M5_HELP_OPTION_LINES],
  [AS_HELP_STRING([[    $1]],[$2],M5_HELP_WIDTH)],[
])dnl
m4_append([M5_OPTION_CASES],[
  --,
    $3,])])dnl
dnl
dnl =========
dnl utilities
dnl ---------
dnl
dnl M5_LONG_OPT_PATTERN([long-name])
dnl   expands to "[long-name | long_name | longname]"
dnl   or just "longname" for names that have no hyphens
dnl   for use in case-label patterns
dnl
m4_define([M5_LONG_OPT_PATTERN],
[m4_if(m4_bregexp([$1],[[-_]]),[-1],  [[--$1]],
[m4_pushdef([__x__],
  [--m4_join](m4_dquote([$]1)[,
   m4_unquote(m4_split(m4_translit([[$1]],[-],[_]),[_]))]))dnl
m4_map_args_sep([__x__(],[)],[ | ],[-],[_],[])dnl
m4_popdef([__x__])])])dnl
