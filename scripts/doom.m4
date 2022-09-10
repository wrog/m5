dnl -*- Autoconf -*-
[
lib_path="${M5LIBPATH:-/home/moo/src/git/m5/lib}"
moo_exec="${M5MOOEXEC:-/home/moo/src/git/server/moo}"

can_dev_stdin=false

netcat="@NETCAT@"
nc_close_eof="@NETCAT_CLOSE_EOF@"
nc_keepalive="@NETCAT_KEEPALIVE@"

auth_code=cd261b3bbb7f11644511ba96c18677397981d645318cd202604a680de2897a26
# auth_code=

run_dir=
moo_log_pipe=
moo_conn=
moo_n=
moo_ip="127.0.0.2"
moo_port=
moo_args=
template_db=
file_db=
temp_db=
ckpt_db=
final_db=
final_log=

do_stdin_code=false
code_count=0
# _code_what$N = 'file'|'stdin'|'expr'
# _code_source$N = actual filename or expression
]dnl
m4_define([M5_VAR_INCR],
  [AS_VAR_ARITH([$1],[[$]$1[ \+ 1]])])dnl
dnl
dnl M5_PUSH_CODE([WHAT],[SOURCE])
dnl   add a new code source
dnl     WHAT='file'|'stdin'|'expr
dnl     SOURCE=filename or expression
dnl
m4_define([M5_PUSH_CODE],[
    M5_VAR_INCR([[code_count]])
    AS_VAR_SET([[_code_what${code_count}]],[$1])
    AS_VAR_SET([[_code_source${code_count}]],[$2])])dnl
dnl
dnl M5_FOREACH_CODE([IF-FILE],[IF-STDIN],[IF-EXPR])
dnl   iterate over code options, provide
dnl     $$code_this = $code_source = filename or expression
dnl
m4_define([M5_FOREACH_CODE],[[
    z=1
    while test "$z" -le "$code_count"  ; do
        code_this="_code_source$z"]
        AS_VAR_COPY([[code_source]],[[$code_this]])
        AS_VAR_COPY([[w]],[[_code_what$z]])
        AS_CASE([[$w]],[[file]],[$1],[[stdin]],[$2],[[expr]],[$3])
        M5_VAR_INCR([[z]])[
    done
]])dnl
[
do_runmoo='exit 65'
do_shconn='exit 66'
do_player='exit 68'
do_shutdown='exit 69'
do_softfail_shconn=false

shell_port=MAYBE
shell_listener='$shell_listener'
listen_zcount=0
listen_fixed=
# _listen_$N = listener for listen_fixed[$N]
# _listen_z$N = $Nth port 0 listener
]dnl
dnl  M5_FOREACH_LISTENER
dnl    iterate over listeners, provide
dnl      $port = port number
dnl      $lname = listener obj(s)
dnl      $is_shell_port :/false
dnl
m4_define([M5_FOREACH_LISTENER],[[
    for port in $listen_fixed; do]
        AS_VAR_COPY([[lname]],[[_listen_$port]])[
        is_shell_port=false
        test "$shell_port" && test "$shell_port" -eq "$port" &&
            is_shell_port=:
        ]$1[
    done
    port=0
    z=1
    while test "$z" -le "$listen_zcount"; do]
        AS_VAR_COPY([[lname]],[[_listen_z$z]])[
        is_shell_port=false
        test "$shell_port" && test "$shell_port" -eq "$port" &&
            test "$shell_listener" = "$lname" &&
            is_shell_port=:
        ]$1
        M5_VAR_INCR([[z]])[
    done
]])dnl
[
do_dryrun=false
do_help=false
do_version=false
do_verbose=false

cleanup () {
    if test -n "$run_dir" ; then
        if test -z "$cu_run_dir" ; then
            rm -f "${run_dir}"/pipe_* "${run_dir}"/log* "${run_dir}"/ckpt*
        fi
        rm -rf $cu_run_dir
    fi
}

# :; preserves exit status in pre-2.05 versions of bash (?)
trap ':; cleanup' 0

die () {
    s=$?
    test $s -eq 0 && s=1
    if test $# -gt 0 ; then
        printf "%s\n" "$@" >&2
    fi]
    AS_EXIT([[$s]])[
}

usage () {
    if test "$2" ; then
        die "$1" "$as_me --help  will show a list of valid options"
    else
        die "$1"
    fi
}

verbose_printf () {
    if $do_verbose ; then
        printf "$@" 1>&2
    fi
}

gen_auth_code () {
    auth_code=$(dd if=/dev/urandom count=1 ibs=28 status=none | shasum -b -a 224) || die;
    auth_code=`expr "X$auth_code" : 'X\([^ ]*\)'`
}

make_run_dir () {
    if test -z "$run_dir" ; then]
        AS_TMPDIR([m5.],[.])[
        run_dir="$tmp"
        cu_run_dir="$tmp"
    elif test ! -d "$run_dir" || test ! -w "$run_dir" ; then
        die "bad run_directory:  $run_dir"
    else
        cu_run_dir=
    fi
}

lib_find () {
    # local base exts save_IFS dir ext
    base="$1"
    exts="$2"
    full=
    for ext in $exts ; do]
        AS_CASE([[$base]],[[
          *$ext]],[[
            exts=
            break;
          ]])[
    done]
    AS_CASE([[$base]],[[
      *[\\/]*]],[[
        for ext in $exts ''; do
            full="$base$ext"
            if test -f "$full" ; then
                test -r "$full" || die "not readable: $full"
                break
            fi
            full=
        done
      ]],[[
        save_IFS=$IFS
        IFS=$PATH_SEPARATOR
        for dir in $lib_path ; do
            IFS=$save_IFS
            test -z "$dir" && dir=.
            for ext in $exts ''; do
                full="$dir/$base$ext"
                if test -f "$full" ; then
                    test -r "$full" || die "not readable: $full"
                    break 2
                fi
            done;
            full=
        done
        IFS=$save_IFS
      ]])[
    test "$full" || return 1;
    return 0;
}

lib_template_find () {]
    AS_CASE([[$1]],[[
      *.db]],[[
        lib_find "${1}.top" || return 1
      ]],[[
        lib_find "${1}" ".db.top .top" || return 1
        test "$full" = "${1}" &&
        die "file not found: $1.[db.]top"
      ]])[
    full=`expr "X$full" : 'X\(.*\).top'`
    if test ! -f "$full.bot" || test ! -r "$full.bot" ; then
        die "file not found: $full.bot"
    fi
    return 0;
}

db_middle () {
    printf "run_info={\"m5_version\",m5_version=\"%s\"" "${m5_version}"
    test -n "$auth_code" &&
        printf ",\"auth_code\",auth_code=\"%s\"" "${auth_code}"
    printf ",\"ckpt_db\",ckpt_db=\"%s\"" "$(printf "%s" "${ckpt_db}" | sed 's/\([\\"]\)/\\\1/g')"
    printf ",\"run_dir\",run_dir=\"%s\"" "$(printf "%s" "${run_dir}" | sed 's/\([\\"]\)/\\\1/g')"
    printf '};'
    printf 'try shell_port=0;set_verb_code(#0,1,{});'
    if test -z "$moo_port" ; then
        printf "%s" "original_port = listeners()[1][2];unlisten(original_port);"
    elif test "$shell_port" &&
         test "$shell_listener" = "#0" &&
         test "$shell_port" -eq "$moo_port" ; then
        printf "%s" "shell_port = listeners()[1][2];"
    fi
    if $do_player ; then
        printf "%s" 'npl=create(#-1);set_verb_code(npl,add_verb(npl,{#0,"rxd","do_login_command"},{"this","none","this"}),{"if(argstr==\"\")","return;",tostr("elseif(argstr!=\"",auth_code,"\")"),"boot_player(player);return;","endif","port=toint(substitute(\"%1\",match(connection_name(player),\"^port %([0-9]+%)\",1)));","unlisten(port);","for p in(connected_players(1))","if(p!=player)","boot_player(p);","endif","endfor","recycle(this);","reset_max_object();","mx=toobj(toint(this)-1);","while(max_object()<mx)","recycle(create(#-1));","endwhile",tostr("resume(",task_id(),",player);")});pport=listen(npl,0,0);server_log(tostr("playerport ",pport));player=suspend();'
    fi
    comma=false
    printf 'listeners={'
    if test "$moo_port" ; then
        printf "$moo_port,"'"#0"'
        comma=:
    fi]
    M5_FOREACH_LISTENER([[
        $comma && printf ','
        if $is_shell_port ; then
            printf 'shell_port='
        fi
        printf 'listen('
        for l in $lname ; do
            printf '`{%s,o="%s"}[1]!ANY=>1'"' &&" $l $l
        done
        printf '%s' "raise(E_PROPNF),$port,1),o"
        comma=:
    ]])[
    printf '};run_info[$+1..$]={"listeners",listeners,@shell_port?{"shell_port",shell_port}|{}};'
    printf 'server_log(tostr("ri ",toliteral(run_info)));'
    printf 'if(shell_port)server_log(tostr("shellport ",shell_port));endif '

    printf 'except (ANY)`boot_player(player)!ANY'"'"';shutdown();endtry '
    $do_shutdown && printf 'try '
    printf 'args = {%s};' "$moo_args"]
    M5_FOREACH_CODE([[
        cat "$code_source"
        printf ";\n"
      ]],[
        AS_IF([[$do_dryrun]],[[
            printf "\n<< code from standard input >>\n"
        ]],[[
            cat <&5
            exec 5>&-
            printf ";\n"
      ]])],[[
        printf "%s\n" "$code_source;"
      ]])[
    $do_shutdown &&
        printf "%s\n" 'finally`boot_player(player)!ANY'"'"';shutdown();endtry '
    printf "\n"
}


# catdb TEMPLATE CODE_FILE
#   write a (small) MOO db to stdout
#   concatenates template.db.top code_expr code_file[.moo] template.db.bot
cat_db () {
    cat "${template_db}.top"
    db_middle
    cat "${template_db}.bot"
}

# unlogged_moo
#   run MOO with current db and network parameters, logging to stderr.
#   (We NEVER used the compiled-in port number; it will be unpredictable
#   whether some other MOO is trying to the same => intermittant failure.)
unlogged_moo () {
    # local p
    p="$moo_port"
    test -n "$p" || p=0
    "$moo_exec" "$in_db" "$ckpt_db" +O -a "$moo_ip" -p $p
}

# logged_moo
#   run MOO, outputing db to $final_db (if set)
#   writing log to $final_log (if set)
#   writing log to $moo_log_pipe (if set)
logged_moo () {
    # local llog
    llog="$final_log"
    if test -z "$moo_log_pipe" ; then
        if test "$final_log" = "-"; then
            unlogged_moo 1>&2
        else
            test -z "$llog" && llog="/dev/null"
            unlogged_moo >"$llog" 2>&1
        fi
    elif test -z "$llog" ; then
        unlogged_moo >"$moo_log_pipe" 2>&1
    elif test "$llog" = "-"; then
        unlogged_moo 2>&1 | tee "$moo_log_pipe" 1>&2
    else
        unlogged_moo 2>&1 | tee "$moo_log_pipe" >"$llog" 2>&1
    fi
    sync
    if test "$final_db" = "-" ; then
        cat "$temp_db"
        exec 1>&-
    fi
    rm -f "$temp_db"
}

run_moo () {
    if test -z "$final_db" || test "$final_db" = "-" ; then
        temp_db="${run_dir}/ckpt${moo_n}"
        ckpt_db="$temp_db"
    else
        temp_db=
        ckpt_db="$final_db"
    fi
    if test "$file_db" ; then
        if test "$file_db" != "-" ; then
            in_db="$file_db"
            logged_moo &
        elif $can_dev_stdin ; then
            in_db="/dev/stdin"
            { logged_moo 0<&5 5<&- & } 5<&0 0<&-
            exec 5>&-
        else
            in_db="${run_dir}/pipe_d"
            mkfifo -m600 "$in_db" || die
            { { cat - >"$in_db" 0<&5 5<&-; rm -f "$in_db" ; } & } 5<&0 0<&-
            exec 5>&-
            logged_moo &
        fi
    elif test -n "$template_db" ; then
        if $can_dev_stdin ; then
            in_db="/dev/stdin"
            if $do_stdin_code ; then
                { cat_db | logged_moo & } 5<&0 0<&-
                exec 5>&-
            else
                cat_db | logged_moo &
            fi
        else
            in_db="${run_dir}/pipe_d"
            mkfifo -m600 "$in_db" || die
            if $do_stdin_code ; then
                { { cat_db >"$in_db" ; rm -f "$in_db" ; } & } 5<&0 0<&-
                exec 5>&-
            else
                { cat_db >"$in_db" ; rm -f "$in_db" ; } &
            fi
            logged_moo &
        fi
    else
        die "need --db or --dbfile"
    fi
    eval "moo_pid${moo_n}=$!"
}

wait_error=

wait_log () {
    # local toss fst snd thd goal
    test "$moo_log_pipe" || return 0;
    if $do_shconn ; then
        goal="shellport"
    elif $do_player ; then
        goal="playerport"
    elif test "$moo_port"; then
        goal="LISTEN:"
    else
        goal="UNLISTEN:"
    fi
    {
        while read toss toss toss fst snd thd; do
#printf "%s\n" "SERVER LOG |${fst}| |${snd}| |${thd}|" >&2
            if test "$moo_log_pipe"; then
                rm -f "$moo_log_pipe"
                moo_log_pipe=
            fi]
            AS_CASE([[$fst]],[[
              '***']],[[
                wait_error="$snd $thd"
                break
               ]],[[
              '>']],[
                AS_CASE([[$snd]],[[
                  playerport]],[[
                    printf "%s\n" "$auth_code" |]dnl
 ["$netcat" $nc_keepalive "$moo_ip" "$thd" |]dnl
 [tr -d '\015' &
                   ]],[[
                  shellport]],[[
                    if test -z "$shell_port" ; then
                        :
                    elif test "$shell_port" = 0 ; then
                        shell_port="$thd"
                    elif test "$shell_port" != "$thd" ; then
                        wait_error="wrong shell_port"
                        break
                    fi
                  ]])[
                if test "$goal" = "$snd"; then
                    goal= ; break
                fi
               ]],[[
              LISTEN:]],[[
                if test "$goal" = "$fst"; then
                    goal= ; break
                fi
               ]],[[
              UNLISTEN:]],[[
                if test "$goal" = "$fst"; then
                    goal="LISTEN:"
                fi
               ]],[[
              SHUTDOWN:]],[[
                if test "$goal" = "$fst"; then
                    goal= ;
                fi
                wait_error="premature shutdown"
                break
            ]])[
        done
        { cat - >/dev/null 0<&5 5<&- & } 5<&0
        exec 5>&-
    } <"$moo_log_pipe"
    test "$goal" && return 1;
    return 0;
}

sh_connect () {
    # local pi po
    pi="${run_dir}/pipe_i"
    po="${run_dir}/pipe_o"
    mkfifo -m600 "$pi" "$po" || die
    "$netcat" $nc_close_eof "$@" <"$po" >"$pi" &
    exec 3>"$po" 4<"$pi"
    rm -f "$po" "$pi"
    if test -n "$auth_code" ; then
        printf "%s\n" "$auth_code" >&3
    fi
}

do_commands () {
    # local cmd ccmd id args
    while read -r cmd id args <&4; do
        args="$(printf "%s" "$args" | tr -d '\015')"
        ccmd="cmd_$cmd"
        if test "$cmd" = '***' ; then
            ccmd="cmd_BYE"
            args=
        elif test "$cmd" = "??:" ; then
            ccmd="cmd_ECHO"
        fi]
        # printf "|>>%s<<|\n" "$cmd $id $args" >&2
        AS_CASE([[$(type $ccmd 2>/dev/null)]],[[
            # ksh and bash say 'function'
            # zsh and sh say 'shell function'
          *' is a'*' 'function*]],[[
            eval "$ccmd $id $args"
          ]],[[
            result -1 "$id" "unknown: $cmd"
          ]])[
    done
    exec 3>&- 4>&-
}

result () {
    # local stat id msg kwd
    stat="$1"
    id="$2"
    shift 2
    msg="$*"
    if test "x$msg" = 'x -status' ; then
        kwd="STATUS"
        msg=
    elif test "$stat" -eq "0" ; then
        kwd="DONE"
        stat=
    elif test "$stat" -gt "0" ; then
        kwd="FAIL"
    else
        kwd="CANT"
    fi
    flock "$run_dir" -c "echo $kwd $id $stat \\\"$msg\\\" >&3"
}

#### available redirection commands

cmd_BYE () {
    exec 3>&-
}

cmd_READ () {
    # local id port file
    id="$1"
    port="$2"
    file="$3"
    ( {
        echo "$auth_code,$id,<"
        cat "$file" 2>/dev/null
        result "$?" "$id" " -status"
    } | {
        "$netcat" $nc_close_eof "$moo_ip" "$port" 2>&1 >/dev/null
        result "$?" "$id"
    } ) &
}

cmd_WRITE () {
    # local id port file
    id="$1"
    port="$2"
    file="$3"
    ( echo "$auth_code,$id,>" | "$netcat" $nc_keepalive "$moo_ip" "$port" 2>/dev/null >"$file"
      result "$?" "$id" ) &
}

cmd_PROC () {
    # local id port errs efd
    id="$1"
    port="$2"
    errs="$3"
    shift 3
    efd="2>&1"
    if test "$errs" = "toss" ; then
        efd="2>/dev/null"
    fi
    ( echo "$auth_code,$id,>" \
          | "$netcat" $nc_keepalive "$moo_ip" "$port" 2>/dev/null \
          | {
          echo "$auth_code,$id,<"
          eval "$@" "$efd"
          result "$?" "$id" " -status"
      } | "$netcat" $nc_close_eof "$moo_ip" "$port" 2>&1 >/dev/null
      result "$?" "$id"
    ) &
}

cmd_PROC2 () {
    # local id port errs efd
    id="$1"
    port="$2"
    errs="$3"
    shift 3
    if test "$errs" = "toss" ; then
        efd="2>/dev/null"
    fi
    ( echo "$auth_code,$id,>" \
          | "$netcat" $nc_keepalive "$moo_ip" "$port" 2>/dev/null \
          | {
          echo "$auth_code,$id,<"
          echo "$auth_code,$id,e" >&5
          eval "$@" 2>&5
          result "$?" "$id" " -status"
      } | "$netcat" $nc_close_eof "$moo_ip" "$port" 2>&1 >/dev/null \
          | "$netcat" $nc_close_eof "$moo_ip" "$port" 2>&1 >/dev/null <&5
      result "$?" "$id"
    ) &
}

cmd_YOUARE () {
    echo "YOUARE $1"
    moo_conn="$1"
}

cmd_CMD () {
    # local id result
    id="$1"
    shift
    result="$("$@" 2>&1 | head -1)"
    result $? $id "$result"
}

cmd_EVAL () {
    # local id
    id="$1"
    shift
    eval "$@" >/dev/null 2>&1
    result $? $id ""
}

cmd_ECHO () {
    printf "%s\n" "$*"
}

cmd_WORDS () {
    while test $# -gt 0 ; do
        printf "%s\n" "$1" | cat -A
        shift
    done
}

#### informational ##################

version_message() {
    if $do_verbose ; then
        m5_version_major=`expr "X$m5_version" : 'X\([^.]*\)'`
        m5_version_minor=`expr "X$m5_version" : 'X[^.]*[.]\([^.]*\)'`
        cat <<EOF
This is M5, version ${m5_version_major}, subversion ${m5_version_minor} (v$m5_version)

$m5_legal_msg

Complete documentation for M5 is available at https://ipomoea.org/moo/m5
EOF
    else
        printf "M5 version %s\n" "$m5_version"
    fi
}]
m4_rename([AS_HELP_STRING],[_M5_prev_HS])dnl
m4_define([AS_HELP_STRING],[_M5_prev_HS([$1],[$2],[36])])dnl
[
help_message () {
    cat <<EOF
Usage:
  $as_me [options] [-- args...]

Top-level options:]
AS_HELP_STRING([[+M, -M, --(no-)moo]],[run a moo server instance [+M=yes]])
AS_HELP_STRING([[+S, -S, --(no-)shell]],[connect a shell instance [+S=yes*]])

[File options:]
AS_HELP_STRING([[-x, --moo-exec=<pathname>]],[moo server executable [*]])
AS_HELP_STRING([[-L, --lib-path=<pathstring>]],[library/db file search path [*]])
AS_HELP_STRING([[-t, --db=<template>]],[use moo template database])
AS_HELP_STRING([[-d, --dbfile=<basename>]],[use moo file database])

[Network options:]
AS_HELP_STRING([[-b, --address=<ip>]],[listen/connect address [127.0.0.2]])
AS_HELP_STRING([[    --(no-)shell-port=<port>]],[moo<->shell port [0*]])
AS_HELP_STRING([[-p, --listen=<port>[,<listener>]]],[add moo listening port])

[First Verb options (template databases only):]
AS_HELP_STRING([[+P, -P, --(no-)player]],[first verb gets 'player' [-P=no*]])
AS_HELP_STRING([[    --]],[first verb gets remaining 'args'])
AS_HELP_STRING([[-e, --expr=<expression>]],[insert expression into first verb])
AS_HELP_STRING([[-f, --code-file=<filename>]],[insert file into first verb])
AS_HELP_STRING([[+H, -H, --(no-)shutdown]],[shutdown after first verb [-H=no*]])

[Output options:]
AS_HELP_STRING([[-o, --(no-)out-db=<basename>]],[retain moo database output [no]])
AS_HELP_STRING([[-l, --(no-)log=<filename>]],[retain moo server log file [no]])

[Informational options:]
AS_HELP_STRING([[-v, +v, --verbose]],[be extra chatty on stderr])
AS_HELP_STRING([[-n, +n, --dry-run]],[validate command line and exit])
AS_HELP_STRING([[-h, +h, -?, --help]],[print this text and exit])
AS_HELP_STRING([[-V, +V, --version, --about]],[print version info and exit])

[ short options cannot be combined, parameters are required]

[ * = defaults this way most of the time, but..., see Info page

EOF
}]
m4_rename_force([_M5_prev_HS],[AS_HELP_STRING])dnl
dnl m4_define([printf],[pppprintf])
dnl -- uncomment to purposefully screw up
dnl -- improperly quoted m4
[
describe_for_dryrun () {
    # local v e z

    printf "M5 Version:  %s\n" "$m5_version"
    $do_verbose && printf "  be verbose (-v|--verbose)\n"
    $do_help    && printf "  print helptext (-h|--help)\n"
    $do_version && printf "  print version  (-V|--version)\n"

    printf "\nSome Environment:\n"
    for e in HOME INSIDE_EMACS TERM PWD SHELL PATH M5MOOEXEC M5LIBPATH; do]
        AS_VAR_COPY([[v]],[[$e]])[
        if test "$v"; then
            printf "  %s=%s\n" "$e" "$v"
        fi
    done
    printf "\nM5 Library path:  %s\n" "$lib_path"
    if $do_help || $do_version ; then
        return
    fi
    if $do_runmoo ; then
        test "$moo_exec" || moo_exec=' ??'
        printf "\nRunning a MOO server (+M|--moo):\n  (-x) --moo-exec=%s\n" "$moo_exec"
        if test "$final_db" ; then
            if test "$final_db" = "-" ; then
                printf "  (-o) --out-db goes to standard output\n"
            else
                printf "  (-o) --out-db=%s\n" "$final_db"
            fi
        fi
        if test "$final_log" ; then
            if test "$final_log" = "-" ; then
                printf "  (-l) --log goes to standard error\n"
            else
                printf "  (-l) --log=%s\n" "$final_log"
            fi
        fi
        printf "  (-b) --address=%s \n" "$moo_ip"
        if test -z "$moo_port"; then
            printf "  will unlisten initial #0 listener\n"
        else
            printf "  keeping initial #0 listener at port %s\n" "$moo_port"
            if test "$shell_listener" = "#0" && test "$shell_port" -eq "$moo_port" ; then
                printf "    (= shell listener port)\n"
            fi
        fi
        if test "$file_db"; then
            if test "$file_db" = "-" ; then
                printf "\nFile database (-d|--db-file) will be read from standard input.\n"
            else
                printf "\nFile database (-d|--db-file):\n  %s\n" "$file_db"
            fi
        elif test "$template_db"; then
            printf "\nTemplate database (-t|--db):\n  %s.{top,bot}\n" "$template_db"
            is_first=:]
            M5_FOREACH_LISTENER([[
                if $is_first ; then
                    printf "  other listeners (-p|--listen):\n"
                    is_first=false
                fi
                if $is_shell_port ; then
                    lname="$lname  (shell listener port)"
                fi
                printf "    %d -> %s\n" "$port" "$lname"
            ]])[
            $do_player && printf "  (+P) adding fake 'player'\n"
            printf "  args = {%s}\n" "$moo_args"]
            M5_FOREACH_CODE([[
                printf "  (-f) --code_file= %s\n" "$code_source"
            ]],[[
                printf "  (-f) --code_file will be read from standard input\n"
            ]],[[
                printf "  (-e) --expr= %s\n" "$code_source"
            ]])[
            $do_shutdown && printf "  (+H) adding shutdown()\n"
        fi
    else
        printf "\nNOT running a MOO server (-M|--no-moo)\n"
    fi

    if $do_shconn ; then
        printf "\nConnecting a shell redirector (+S|--shell):\n  --shell_port=%s\n" "$shell_port"
        $do_runmoo ||
            printf "  (-b) --address=%s\n" "$moo_ip"
    else
        printf "\nNOT connecting a shell redirector (-S|--no-shell)\n"
    fi
    printf "\n"]
    AS_IF([[test "$template_db" && $do_verbose]],[[
        printf "Code being inserted in first verb:\n  "
          db_middle
    ]])[
}

push_moo_listeners () {
    # local v port lname
    v="$1"
    lname=]
    AS_CASE([[$v]],[[
      *[!0-9a-zA-Z_.,\#]*]],[[
        usage "--listen=|-p: illegal characters in $v"; return
       ]],[[
      *,*,*]],[[
        usage "--listen=|-p: at most one comma allowed: $v"; return
       ]],[[
      *[!0-9]*,*]],[[
        usage "--listen=|-p: port must be a number: $v"; return
       ]],[[
      *,[\#]*[!0-9]*]],[[
        usage "--listen=|-p: listener bad literal objectid: $v"; return
       ]],[[
      *,?*[\#]* | *,[0-9.]* | *,*.[0-9.]* | *,*. | *,]],[[
        usage "--listen=|-p: listener invalid identifier: $v"; return
       ]],[[
      *,*_listener]],[[
        port=`expr "X$v" : 'X\(.*\),.*'`
        lname='$'`expr "X$v" : 'X.*,\(.*\)'`
       ]],[[
      *,[\#]*]],[[
        port=`expr "X$v" : 'X\(.*\),.*'`
        lname=`expr "X$v" : 'X.*,\(.*\)'`
       ]],[[
      *,*]],[[
        port=`expr "X$v" : 'X\(.*\),.*'`
        lname=`expr "X$v" : 'X.*,\(.*\)'`
        lname="\$${lname}_listener \$${lname}"
       ]],[[
      *[!0-9]*]],[[
        usage "--listen=|-p: port must be a number: $v"; return
      ]],[[
        port="$v"
        lname="#0"
      ]])[

    if test "$lname" = "#0" && test -z "$moo_port"; then
        moo_port="$port"
    elif test "$port" -eq 0; then]
        M5_VAR_INCR([[listen_zcount]])
        AS_VAR_SET([[_listen_z${listen_zcount}]],[["$lname"]])[
    elif] AS_VAR_TEST_SET([[_listen_$port]])[ ; then
        usage "--listen|-p:  multiple listeners at $port" ; return
    else
        listen_fixed="$listen_fixed $port"]
        AS_VAR_SET([[_listen_$port]],[["$lname"]])[
    fi
}

push_lib_path () {
    # local v
    v="${1}"]
    AS_CASE([[$v]],[[
      +::*[!:]*]],[[
        v=`expr "X$v" : 'X.:*\(.*[^:]\)'`
        lib_path="${lib_path}:.:${v}"
       ]],[[
      +: | +::*]],[[
        lib_path="${lib_path}:."
       ]],[[
      +:?*:]],[[
        v=`expr "X$v" : 'X..\(.*[^:]\)'`
        lib_path="${lib_path}:${v}:."
       ]],[[
      +:?*]],[[
        v=`expr "X$v" : 'X..\(.*\)'`
        lib_path="${lib_path}:${v}"
       ]],[[
      :*[!:]*:+]],[[
        v=`expr "X$v" : 'X:*\(.*[^:]\).*+'`
        lib_path=".:$v:${lib_path}"
       ]],[[
      :+ | :*:+]],[[
        lib_path=".:${lib_path}"
       ]],[[
      ?*::+]],[[
        v=`expr "X$v" : 'X\(.*[^:]\).*+'`
        lib_path="${v}:.:${lib_path}"
       ]],[[
      ?*:+]],[[
        v=`expr "X$v" : 'X\(.*\):+'`
        lib_path="${v}:${lib_path}"
       ]],[[
      :*]],[[
        v=`expr "X$v" : 'X:*\(.*[^:]\)'`
        lib_path=".:${v}"
       ]],[[
      *:]],[[
        v=`expr "X$v" : 'X\(.*[^:]\)'`
        lib_path="${v}:."
       ]],[[
      ?*]],[[
        lib_path="${v}"
      ]],[[
        lib_path="."
      ]])[
}

push_code () {
    if test "$1" = 'file' && test "$2" = '-' ; then
        $do_stdin_code &&
          usage "only one -f|--code-file can be standard input"
        do_stdin_code=:
        w=stdin
    else
        w="$1"
    fi]
    M5_PUSH_CODE([["$w"]],[["$2"]])[
}

conflicts=
conflict () {
    usage "conflicting options:  $conflicts vs. $1";
}

#### Gather command line args

arg_count=0

while test "$#" -gt 0 ; do]
    M5_VAR_INCR([[arg_count]])[
    conflicts="$1"]
    AS_CASE([[$1]],[[
      --*=?*]],[[
        argument=`expr "X$1" : '[^=]*=\(.*\)'`
      ]],[[
        argument=
      ]])
    AS_CASE([[$1]],[[
      +M | --moo]],[
        AS_CASE([[$do_runmoo]],[[false]],[[conflict "-M|--no-moo"]],[[do_runmoo=:]])
       ],[[
      -M | --no-moo | --no_moo | --nomoo]],[
        AS_CASE([[$do_runmoo]],[[:]],[[conflict "+M|--moo"]],[[do_runmoo=false]])
       ],[[
      +S | --shell]],[
        AS_CASE([[$do_shconn]],[[false]],[[conflict "-S|--no-shell"]],[[do_shconn=:]])
       ],[[
      -S | --no-shell | --no_shell | --noshell]],[
        AS_CASE([[$do_shconn]],[[:]],[[conflict "+S|--shell"]],[[do_shconn=false]])
       ],[[
      --moo-exec=* | --moo_exec=* | --mooexec=*]],[[
        moo_exec="$argument"
       ]],[[
      -x]],[[
        test $# -gt 1 || usage "$1: <pathname> missing"
        shift
        moo_exec="$1"
       ]],[[
      --lib-path=* | --lib_path=* | --libpath=*]],[
        AS_VAR_ARITH([[arg_count]],[[$arg_count \- 1]])[
        push_lib_path "$argument"
       ]],[[
      -L]],[
        AS_VAR_ARITH([[arg_count]],[[$arg_count \- 1]])[
        test $# -gt 1 || usage "$1: <pathstring> missing"
        shift
        push_lib_path "$1"
       ]],[[
      --db=*]],[[
        template_db="$argument"
       ]],[[
      -t]],[[
        test $# -gt 1 || usage "$1: <template> missing"
        shift
        template_db="$1"
       ]],[[
      --dbfile=*]],[[
        file_db="$argument"
       ]],[[
      -d]],[[
        test $# -gt 1 || usage "$1: <basename> missing"
        shift
        file_db="$1"
       ]],[[
      --address=*]],[[
        moo_ip="$argument"
       ]],[[
      -b]],[[
        test $# -gt 1 || usage "$1: <ip> missing"
        shift
        moo_ip="$1"
       ]],[[
      --no-shell-port | --no_shell_port | --noshellport]],[[
        shell_port=
       ]],[[
      --shell-port=* | --shell_port=* | --shellport=*]],[[
        shell_port="$argument"
       ]],[[
      --listen=*]],[[
        push_moo_listeners "$argument"
       ]],[[
      -p]],[[
        test $# -gt 1 || usage "$1: <port>[,<listener>] missing"
        shift
        push_moo_listeners "$1"
       ]],[[
      +P | --player]],[[
        do_player=:
       ]],[[
      -P | --no-player | --no_player | --noplayer]],[[
        do_player=false
       ]],[[
      --]],[[
        moo_args=
        shift
        while test "$#" -gt 0; do
          test "$moo_args" && moo_args="$moo_args,"
          x="$1"
          moo_args="$moo_args\"$(printf "%s" "$x" | sed 's/\([\\"]\)/\\\1/g')\""
          shift
        done
        set --
        break;
       ]],[[
      --expr=*]],[[
        push_code expr "$argument"
       ]],[[
      -e]],[[
        test $# -gt 1 || usage "$1: <expression> missing"
        shift
        push_code expr "$1"
       ]],[[
      --code-file=* | --code_file=* | --codefile=*]],[[
        push_code file "$argument"
       ]],[[
      -f]],[[
        test $# -gt 1 || usage "$1: <filename> missing"
        shift
        push_code file "$1"
       ]],[[
      +H | --shutdown]],[[
        do_shutdown=:
       ]],[[
      -H | --no-shutdown | --no_shutdown | --noshutdown]],[[
        do_shutdown=false
       ]],[[
      --no-out-db | --no_out_db | --nooutdb]],[[
        final_db=
       ]],[[
      --out-db=* | --out_db=* | --outdb=*]],[[
        final_db="$argument"
       ]],[[
      -o]],[[
        test $# -gt 1 || usage "$1: <basename> missing"
        shift
        final_db="$1"
       ]],[[
      --no-log | --no_log | --nolog]],[[
        final_log=
       ]],[[
      --log=*]],[[
        final_log="$argument"
       ]],[[
      -l]],[[
        test $# -gt 1 || usage "$1: <filename> missing"
        shift
        final_log="$1"
       ]],[[
      -v | +v | --verbose]],[
        AS_VAR_ARITH([[arg_count]],[[$arg_count \- 1]])[
        do_verbose=:
       ]],[[
      -n | +n | --dry-run | --dry_run | --dryrun]],[
        AS_VAR_ARITH([[arg_count]],[[$arg_count \- 1]])[
        do_dryrun=:
       ]],[[
      -h | +h | -[?] | --help]],[
        AS_VAR_ARITH([[arg_count]],[[$arg_count \- 1]])[
        do_help=:
       ]],[[
      -V | +V | --version]],[
        AS_VAR_ARITH([[arg_count]],[[$arg_count \- 1]])[
        do_version=:
       ]],[[
      --about]],[
        AS_VAR_ARITH([[arg_count]],[[$arg_count \- 1]])[
        do_version=:
        do_verbose=:
      ]],[[
        usage "unrecognized option:  '$1'" :
      ]])[
    shift
done

if $do_dryrun && { $do_help || $do_version ; } ; then
    describe_for_dryrun]
    if test "$arg_count" -gt 0 ; then
        printf "\n(leave out --version,-V,--help,-h,--about\n"
        printf " to see what remaining options are doing)\n"
    fi
    AS_EXIT(0)[
fi

if $do_version ; then
    version_message]
    AS_EXIT(0)[
fi

if $do_help; then
    if $do_verbose ; then
        version_message
    fi
    help_message]
    AS_EXIT(0)[
fi

# Flags that can still be unset at this point:
#   do_shutdown, do_runmoo, do_shconn, shell_port, do_player
]
dnl  *** TODO *** maybe this can go away now?
AS_CASE([[$template_db]],[[
  Raw*]],[
    AS_CASE([[$do_shconn]],[[
      exit*]],[[
        if test "$shell_port" = MAYBE ; then
            do_shconn=false
            shell_port=
        fi
    ]])
  ])[

# set do_runmoo, infer from --dbfile or --db
#
if test "$file_db" ; then
    conflicts="--dbfile|-d"
    test "$template_db" && conflict "--db|-t"]
    AS_CASE([[$do_runmoo]],[[
      false]],[[
        conflict "--no-moo|-M"
      ]],[[
        do_runmoo=:
      ]])[
elif test "$template_db" ; then
    conflicts="--db|-t"]
    AS_CASE([[$do_runmoo]],[[
      false]],[[
        conflict "--no-moo|-M"
      ]],[[
        do_runmoo=:
      ]])[
else]
    AS_CASE([[$do_runmoo]],[[
      :]],[[
        usage "--moo|+M requires database (--db|-t or --dbfile|-d)"
      ]],[[
        do_runmoo=false
      ]])[
fi

# make sure --log and --out-db are doable
if $do_runmoo ; then
    if test "$final_db" && test "$final_db" != "-"; then
        test -w "$(dirname "$final_db")"  ||
            die "--out-db not writable:  $final_db"
    fi
    if test "$final_log" && test "$final_log" != "-"; then
        test -w "$(dirname "$final_log")" ||
            die "--log not writable:  $final_log"
    fi
fi

# set do_shconn, shell_port, infer from each other and do_runmoo
#
if test -z "$shell_port" ; then
    conflicts="--no-shell-port"]
    AS_CASE([[$do_shconn]],[[:]],[[conflict "--shell|+S"]],[[do_shconn=false]])[
    $do_runmoo ||
        usage "--no-shell and (--no-moo / no database) ?"
elif test "$shell_port" = MAYBE ; then
    $do_runmoo ||
        usage "specific --shell-port required if --no-moo|-M"]
    AS_CASE([[$do_shconn]],[[
      false]],[[
        shell_port=]],[[
      exit*]],[[
        do_softfail_shconn=:
        do_shconn=:
        shell_port=0
      ]],[[
        do_shconn=:
        shell_port=0
    ]])[
elif test "$shell_port" -eq 0 ; then
    $do_runmoo ||
        usage "specific --shell-port required if --no-moo|-M"
fi]
AS_CASE([[$do_shconn]],[[exit*]],[[do_shconn=:]])[
$do_shconn ||
    $do_runmoo ||
    usage "--no-shell and (--no-moo / no database) ?"

# do_shutdown, do_player need to be set
#
if test "$file_db" ; then
    conflicts="-d|--dbfile"]
    AS_CASE([[$do_shutdown]],[[
      :]],[[conflict "+H|--do-shutdown"]],[[
      do_shutdown=false]])
    AS_CASE([[$do_player]],[[
      :]],[[conflict "+P|--player"]],[[
      do_player=false]])[

    test "$code_count" -gt 0 && conflict "-f|--code-file|-e|--expr"
    test "$moo_args"    && conflict "--"

    # $moo_port is the only allowed listener
    if test "$listen_fixed" || test "$listen_zcount" -gt 0; then
        if test "$moo_port"; then
            usage "-d|--dbfile only allows one -p|--listen"
        else
            usage "-d|--dbfile only allows #0 as listener"
        fi
    fi

    # resolve filename
    if test "$file_db" != "-"; then
        lib_find "$file_db" .db || die "--dbfile|-d not found: $file_db";
        file_db="$full"
    fi

elif test "$template_db" ; then]
    # add shell port to listeners if not there already
    #
    AS_VAR_COPY([[lname]],[[_listen_${shell_port}]])[
    if test "$shell_port" && test "$shell_port" -gt 0 && test "$lname"; then
        shell_listener="$lname"
    elif test "$shell_port"; then
        push_moo_listeners "${shell_port},shell_listener"
    fi]

    AS_CASE([[$do_player]],[[
      exit*]],[[
        if test "$shell_port" ||
                test "$listen_fixed" ||
                test "$moo_port" ||
                test "$listen_zcount" -gt 0 ||
                test "$final_log" ||
                test "$final_db" ; then
            do_player=false
        else
            # lonely moo detected, send help
            do_player=:
        fi
      ]])

    # shutdown if no listeners
    AS_CASE([[$do_shutdown]],[[
      exit*]],[[
        if test "$moo_port" || test "$listen_fixed" || test "$listen_zcount" -gt 0; then
            do_shutdown=false
        else
            do_shutdown=:
        fi
    ]])

    # resolve filenames
    M5_FOREACH_CODE([[
        lib_find "$code_source" '.m5 .moo' ||
            die "-f|--code-file not found: $code_source"]
        AS_VAR_SET([[$code_this]],[["$full"]])],[],[])[
    lib_template_find "$template_db" ||
        die "-t|--db not found: $template_db"
    template_db="$full"

else
    # no moo rules out a whole lot of activities
    conflicts="--no-moo|-M"

    test "$final_log" && conflict "-l|--log";
    test "$final_db"  && conflict "-o|--out-db";
    if test "$moo_port" || test "$listen_zcount" -gt 0 || test "$listen_fixed"; then
        conflict "-p|--listen"
    fi
    test "$moo_args"    && conflict "-- args..."
    test "$template_db" && conflict "-t|--db";
    test "$file_db"     && conflict "-d|--dbfile";
    test "$code_count" -gt 0 && conflict "-f|--code-file|-e|--expr";]
    AS_CASE([[$do_shutdown]],[[
      exit*]],[[do_shutdown=false]],[[
      conflict "+H|-H|--(no)-shutdown"]])
    AS_CASE([[$do_player]],[[
      exit*]],[[do_player=false]],[[
      conflict "+P|-P|--(no)-player"]])[
fi

if $do_player ; then
    conflicts="--player|+P"
    test "$final_db" = "-" && conflict "-o|--out-db= standard output"
fi

if $do_dryrun ; then
    describe_for_dryrun]
    AS_EXIT(0)[
fi

#### Actually Do Things

make_run_dir
if $do_runmoo ; then
    moo_log_pipe=
    if $do_shconn || $do_player ; then
        moo_log_pipe="${run_dir}/pipe_l${moo_n}"
        mkfifo -m600 "$moo_log_pipe" || die "mkfifo for log"
    fi
    run_moo
    wait_log || {
        # kill "$moo_pid"
        if $do_softfail_shconn && test "$wait_error" = "premature shutdown"; then
            do_shconn=false
        else
            die "$wait_error"
        fi
    }
fi
if $do_shconn ; then
    sh_connect "$moo_ip" "$shell_port"
    do_commands
fi
if $do_runmoo ; then
    # printf "%s\n" '|>> waiting for moo <<|' >&2
    wait
fi]
AS_EXIT(0)
