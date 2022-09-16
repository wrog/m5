dnl
dnl Options declarations for m5run
dnl ================================
dnl
M5_HELP_SECTION([Top-level])dnl
[
The @command{m5run} shell script normally runs an instance of the @moo server, then optionally creates a redirection service that connects to the @moo's @code{$shell_listener}, and then enables shell command/file redirections from inside the @moo.

It is also possible to run the redirection facility by itself, connecting it to a pre-existing @moo server instance rather than running a fresh @moo ourselves.
]
dnl ---------------
dnl  +M|-(-no)-moo
M5_OPTION_BOOLEAN( [M], [moo],
  [run a moo server instance], [+M=yes],
  [[do_runmoo]])dnl
[
Launch (or do not launch) an instance of the @moo server.

The default is to launch (@samp{+M}), unless no database (@option{-t|--db} or @option{-d|--dbfile}) is specified, in which case we do not (@samp{-M}).
]
dnl -----------------
dnl  +S|-(-no)-shell
M5_OPTION_BOOLEAN( [S], [shell],
  [connect a shell instance], [+S=yes*],
  [[do_shconn]])dnl
[
Connect (or do not connect) a shell redirection service to the @moo's @code{$shell_listener}.

The default for this, if we're running a @moo server (@option{+M}), is to follow the setting for @option{-[-no]-shell-port} (which see), and if that's left blank, then just watch the @moo server log, try to connect if the server says there it's listening at a shell port, and otherwise don't.

The main utility of this option is to use @option{-S} to prevent a connection attempt in cases where there would otherwise be one, say, in order to let Someone Else connect.  It is quite possible (if I've done this right) that you will never otherwise need to specify this option explicitly.

If we're @emph{not} running a @moo server, then the only thing this command could be doing is running a separate redirection service (@option{+S}), meaning we will connect to a pre-existing @moo server (i.e., we @emph{are} the Somebody Else in the previous paragraph), and this cannot work unless we also explicitly specify the port to connect to using @option{--shell-port=@var{port}} (and possibly also the @option{--address|-b}), which will then imply @option{+S}, so we'll never actually need to say @option{+S} in this case.
]dnl
_M5_END_TABLE()dnl
[
@noindent
Note that, unless you're just getting help (@option{-h},@dots{}), you have to do at least one of these, i.e., we do not allow @option{-M -S}.
]dnl
dnl ================================
M5_HELP_SECTION([File])dnl
[
When running a @moo server (@option{+M}) an input database option (@option{-t|--db} or @option{-d|--dbfile}) must be specified, and there can be at most one.

@anchor{std-file}
Also, some of these allow specifying @samp{-} to mean standard input, standard output, or standard error, depending on context, which you should use if this is the behavior you want.  Meaning do not use @file{/dev/stdin} or @file{/dev/fd/5} if your operating system offers such things; there are enough weird redirections happening behind the scenes that these will probably not work in the way you expect.  Just use @samp{-} and redirect from the outside if you want bits being sent to unorthodox file descriptors.

And it is entirely legal to use @samp{-} for multiple options in the same command, e.g., @emph{all} of input database (@option{-d}), output database (@option{-o}) and the server log (@option{-l}) could be @samp{-}, since these are referring to standard input, standard output, and standard error, respectively, each being used only once, there is no conflict.
]
dnl --------------------------
dnl  -x|--moo-exec=<pathname>
M5_OPTION_VALUE( [x], [moo-exec], [[<pathname>]],
  [moo server executable], [*],
  [[moo_exec]])dnl
[
Use @var{pathname} as the @moo server executable.  @xref{exec-prereq,,Prerequisites}, for more on what this needs to be.  As usual, @env{PATH} is searched if @var{pathname} has no directory separators (i.e., slashes).
]
dnl ----------------------------
dnl  -L|--lib-path=<pathstring>
M5_OPTION_PUSH(  [L], [lib-path], [[<pathstring>]],
  [library/db file search path],[*],
  [M5_VAR_DECR([[arg_count]])[
    push_lib_path]])dnl
[
Sets or adds to the M5 Library Path, a list of directories initialized the value of the environment variable @env{M5LIBPATH} if that is set, and otherwise to a sensible default based on installation parameters.  See the description of @ref{lib-path,,@env{M5LIBPATH} in the Environment section}, for more on the format and uses of this path.

There are 3 possibilities for @var{pathstring}:
@itemize
@item
A @var{pathstring} beginning with @samp{+:} is appended to the path.
@item
A @var{pathstring} ending with @samp{:+} adds directories to the beginning of the path.
@item
Otherwise @var{pathstring} replaces the entire path.
@end itemize

This option may be given multiple times and the results are cumulative.  All @option{-L|--lib-path} options are collected @emph{first} and considered in the order they appear to determine the (@emph{single}) library path.  The relative order of @option{-L|--lib-path} with respect to any other options does not matter (except for @option{--}, beyond which any further @option{-L|--lib-path} options are not recognized).  The resulting path is then used to resolve all input filenames (@option{-f|--code-file}, @option{-d|--db-file}, @option{-t|--db}), regardless of whether these options occur before or after the @option{-L|--lib-path} options they depend on.
]
dnl --------------------
dnl  -t|--db=<template>
M5_OPTION_VALUE(  [t], [db], [[<template>]],
  [use moo template database],[],
  [[template_db]])dnl
[
Start the @moo instance using this template database.  The M5 Library Path (see @option{-L}) is searched if @var{template} has no directory separators.

Template databases are actually pairs of files.  One of @file{@var{template}.db.top} (if @file{@var{template}} does not already end with @file{.db}) or @file{@var{template}.top} (searched in this order) must exist, and, if found, a corresponding @file{.bot} file (i.e., @file{@var{template}.db.bot} or @file{@var{template}.bot}, respectively) must be present in the same directory.
]
dnl ------------------------
dnl  -d|--dbfile=<basename>
M5_OPTION_VALUE(  [d], [dbfile], [[<basename>]],
  [use moo file database],[],
  [[file_db]])dnl
[
Start the @moo instance using this file database.  The M5 library path (see @option{-L}) is searched if @var{basename} has no directory separators.  One of @file{@var{basename}.db} (if @file{@var{basename}} does not already end with @file{.db}) or @file{@var{basename}} is expected to be found.

Also, @var{basename} can be @file{-}, in which case the file database is read from standard input.

Note that using a file database disables options that are intended only for template databases, i.e., the ones where we say ``This option can only be used with template databases (@option{-t}).''
]
dnl --------------------------------
dnl  -o|-(-no)-out-db=<basename>
M5_OPTION_NEGVALUE(  [o], [out-db], [[<basename>]],
  [retain moo database output],[no],
  [[final_db]])dnl
[
Write the output moo database to @file{@var{basename}.db} (or @var{basename} if that already ends with @samp{.db}).

The default is @option{--no-out-db}, meaning the output database is discarded.

If @var{basename} is @samp{-}, then the file database is written to standard output.  If you do this you cannot use the fake player (@option{+P|--player}), since that also takes over standard output.
]
dnl --------------------------
dnl  -l|-(-no)-log=<filename>
M5_OPTION_NEGVALUE(  [l], [log], [[<filename>]],
  [retain moo server log file], [no],
  [[final_log]])dnl
[
Write the moo server log to @var{filename}.

The default is @option{--no-log}, meaning the server log is discarded.

If @var{filename} is @samp{-}, then the server log will appear on standard error.@footnote{Yes, this also goes against tradition if you were expecting @samp{-} to mean standard output in this case, but standard error is pretty much always where you want a log anyway, and this way, we reduce the likelihood that an output database and server log will get jumbled together, which will help exactly no one.  Anyway, if you @emph{really} do want the log on standard output, @code{2>&1} isn't that hard.}  Error messages from the redirection service will get mixed in with the @moo server log if you do this.@footnote{And, often, this is what you want.}
]dnl
dnl =======================
M5_HELP_SECTION([Network])
dnl -------------------
dnl  -b|--address=<ip>
M5_OPTION_VALUE(  [b], [address], [[<ip>]],
  [listen/connect address], [127.0.0.2],
  [[moo_ip]])dnl
[
Use this IP address (default is @samp{127.0.0.2}) for all service bindings.  This will pass @option{-a} to the @moo server executable, and any listening ports created separately in the shell will likewise use this address.

@strong{WARNING}:  Combining @option{+S} or @option{--shell-port=@var{p}} with @option{-b} and any address that is @emph{not} on your loopback net (@samp{127.*.*.*/localhost}), unless you @strong{completely} trust everyone who has access to the @emph{actual} network that your machine lives on, will essentially be you committing Security Suicide, since this potentially gives, to everyone who can reach your machine via that address, filesystem access on your host with your own permissions.@footnote{And if you totally hate your employer and your employment, you should also be sure to arrange for the @command{m5run} script to be made setuid-root as well, except do this all on one of your company's mission-critical servers, @dots{} though I will readily admit to having put zero effort into making that scenario work properly.  Perhaps I should.}

(Note that the loopback net, in contrast, is only accessible by local users and processes on the same host machine, so as long as there are none of those that you do not trust --- one hopes this is the case for the hosts where you do development and run test suites --- you should be fine.  And even if there are, there are various measures we take to reduce exposure (@pxref{Security}).
]
dnl --------------------------
dnl  -(-no)-shell-port=<port>
M5_OPTION_NEGVALUE(  [], [shell-port], [[<port>]],
  [moo<->shell port],[0*],
  [[shell_port]])dnl
[
This option specifies the port for the shell redirection service (@option{+S|--shell}) to connect to.

In the case where we are @emph{not} also running a @moo server (@option{-M|--no-moo}), but instead connecting to a pre-existing server instance, this option is @strong{required} and the port number @emph{must} be non-zero (and, chances are, you will need to specify an @option{-a|--address} as well).

In the case where a @moo server @emph{is} being run (@option{+M|--moo}), and both this option and @option{+S|-S|-(-no)-shell} are left unspecified, the default behavior is to expect (or direct in the case of template databases) the @moo server to choose a port randomly, listen with @code{$shell_listener}, advertise this in the server log, and then we read the log and either connect accordingly or quietly give up if no advertisement is seen.  The scenarios for changing this behavior are as follows:

@itemize
@item
Specifying @option{--no-shell-port} @emph{always} implies @option{-S|--no-shell}, that no connection will be attempted, but also removes the direction to the @moo server to listen, though the latter only affects template databases.@htmlbrbr
@item
Combining @option{--no-shell-port} with @option{+S|--shell} makes no sense and is not allowed.@htmlbrbr
@item
@option{--shell-port=@var{port}} in the case where @option{@var{port}} > 0 requires the use of that specific port, and it is an error (i.e., non-zero @command{m5run} exit status) for the @moo server to either fail to listen or advertise the wrong port (this can only happen for file databases).

Combining @option{--shell-port=@var{port}} with @option{-S|--no-shell}, i.e., the direction/expection to listen while suppressing the connection attempt, is what is needed if you want to connect to the shell listener from another process.
@item
@option{--shell-port=0} is essentially the default behavior except that here, it is an error for the @moo server to either fail to listen or advertise a port in the log (which, again, will only happen for file databases).

Combining @option{--shell-port=0} with @option{-S|--no-shell}, i.e., choose a port randomly for listening and do not connect to it, is the other way of enabling an external connection, has the advantage that there will never be conflicts over a particular port, however you will need to find some means of communicating the port number (available as @code{@var{shell_port}} in the first verb) to the other process.
@end itemize
]
dnl ---------------------------------
dnl  -p|--listen=<port>[,<listener>]
M5_OPTION_PUSH(  [p], [listen], [[<port>[,<listener>]]],
  [add moo listening port],[],
  [[push_moo_listeners]])dnl
[
Have the @moo listen at a specific port.  The @var{listener} portion should be one of

@table @code
@item @var{word}
naming a property accessible from the system object (@samp{#0} or an ancestor).  Both @code{$@var{word}_listener}, provided @code{$@var{word}} does not already end with @code{_listener}, and then @code{$@var{word}} will be tried, in that order, and if neither exists an error will be raised.  @var{word} must be a period(@samp{.})-separated sequence of valid @moo property names and must @emph{not} begin with a @samp{$} (which is already assumed).
@item #@var{n}
a literal object number,
@end table

@noindent
and defaults to @samp{#0}.

For file databases, this option may be given at most once, and @samp{#0} is the only allowed value for @var{listener} (and, being the default, there will then never any point to explicitly specifying a listener object in this case).  In other words, all you can do with file databases is give a single @option{-p @var{port}} which then gets passed straight through to the @moo server command line.

For template databases, this option may be given multiple times and the results are cumulative.  The first such option that specifies @samp{#0} as its listener is passed to the @moo server command line; if there is no such option the @moo server's original port is @code{unlisten()}ed in @code{$server_started} and nothing will ever get a chance to connect to it.

If multiple @option{-p|--listen} options are present, there must be at most one for any given non-zero port number.  For port 0, arbitrarily many listeners are allowed, since port 0 just means, ``Choose a random port,'' and the kernel takes care of making them all be different.

If you specify both @option{-p|--listen=@var{port},@var{listener}} and @option{--shell-port=@var{port}} for the same non-zero @var{port}, this forces the shell listener be @var{listener} (i.e., rather than the hardwired @code{shell_listener}).@footnote{Yes, this is esoteric and weird.  We may rethink this behavior at some point.  Normally you do not want to change the shell listener, but you might if you, say, want to try out a more advanced shell listener@dots{}}
]dnl
dnl ====================================================
M5_HELP_SECTION( [First Verb], [template databases only])dnl
[
A template database is a pair of files in which the @file{.top} file consist of everything from the database header to the beginning of the code for the @dfn{first verb} on @samp{#0} (designated @samp{#0:0} in the file, but referenced as @code{#0:1} from actual code), which is normally either @code{$server_started} or something that is called directly by @code{$server_started}.  The @file{.bot} file consists of everything from the @samp{.} that terminates the first verb to the end of the file.

Essentially, this @dfn{first verb}, usually left blank, serves as a place for @command{m5run} to insert arbitrary code to make possible the following special effects:.
]
dnl ---------------------
dnl  +P -P -(-no)-player
M5_OPTION_BOOLEAN(  [P], [player],
  [first verb gets 'player'],[-P=no*],
  [[do_player]])dnl
[
Include, in the first verb, an assignment to @code{player} such that @code{notify(player,@var{line})} sends @var{line} to standard output and @code{boot_player(player)} closes standard output.

Default is @option{--no-player} unless there is no output database file (@samp{-o}) and no listening points are explicitly specified, whether via @option{-p|--listen} or @option{--shell-port}.  In other words, by default, we only create the fake @code{player} if there is no other way for this @moo to communicate with anyone.

@option{+P|--player} can only be used with template databases (@option{-t}) and is not allowed if the output database (@samp{-o|--out-db}) is standard output.
]
dnl --
dnl
M5_OPTION_END(  [--], [[<args>]],
  [first verb gets remaining 'args'],[[[
    moo_args=
    shift
    while test "$][#" -gt 0; do
      test "$moo_args" && moo_args="$moo_args,"
      x="$][1"
      moo_args="$moo_args\"$(printf "%s" "$x" | sed 's/\([\\"]\)/\\\1/g')\""
      shift
    done
    set --
    break
  ]]])dnl
[
Include, in the first verb, an assignment to @code{args} that gathers all remaining words of the command line after the @option{--}.  None of these words will be treated as @command{m5run} options even if they would otherwise be valid as such.

If @option{--} is @emph{not} present, then the the first verb begins with @code{args = @{@}} and unrecognized command line words will be treated as errors.

This option can only be used with template databases (@option{-t}).
]
dnl ------------------------
dnl  -e|--expr=<expression>
M5_OPTION_PUSH(  [e], [expr], [[<expression>]],
  [insert expression into first verb],[],
  [[push_code expr]])dnl
[
Insert this @var{expression} into the first verb.  @var{expression} is expected to be a valid @moo language expression or statement.  Semicolon (@samp{;}) will always be inserted before and afterwards, so there will never be any combining of expressions from different @option{-e} options or different @option{-f} files.

This option may be given multiple times and the results are cumulative.

This option can only be used with template databases (@option{-t}).
]
dnl ---------------------------
dnl  -f|--code-file=<filename>
M5_OPTION_PUSH(  [f], [code-file], [[<filename>]],
  [insert file into first verb],[],
  [[push_code file]])dnl
[
Insert this file into the first verb.  @var{filename} is expected to contain a sequence of valid @moo language statements.

The M5 library path (see @option{-L}) is searched if @var{filename} has no directory separators.

This option may be given multiple times and the results are cumulative.

This option can only be used with template databases (@option{-t}).
]
dnl --------------------
dnl  +H|-(-no)-shutdown
M5_OPTION_BOOLEAN(  [H], [shutdown],
  [shutdown after first verb], [-H=no*],
  [[do_shutdown]])dnl
[
Bracket the sequence of expressions/files included in the first verb via @option{-e|--expr} and @option{-f|--code-file} options with a @code{try @dots{} finally shutdown(); endtry} to make the @moo process terminate immediately when the first verb exits.

Default behavior is to shut down @emph{unless} there are one or more listeners active when the first verb exits, whether this be due to explicit @option{-p|--listen} options or @option{-e}/@option{-f} code issuing its own @code{listen()} calls.

This option can only be used with template databases (@option{-t}).
]dnl
_M5_END_TABLE()dnl
[
Expressions (@option{-e|--expr}) and files (@option{-f|--code-file}) are executed in the order they appear on the command line, @emph{after} the setup for the fake player (@option{-P|--player}) and the listening points (@option{-p|--listener}) but (obviously) before any code calling for a shutdown (@option{+H|--shutdown}).
]dnl
dnl ======================================
M5_HELP_SECTION([Informational])
dnl -----------------
dnl  -v|+v|--verbose
M5_OPTION_INFOBOOLEAN(  [v],[verbose],
  [be extra chatty on stderr], [],
  [[do_verbose=:]])dnl
[
Be extra chatty on the standard error output.@footnote{The author not being a natural extrovert, there are currently relatively few situations where this flag makes a difference, but maybe that will change.}
]
dnl -----------------
dnl  -n|+n|--dry-run
M5_OPTION_INFOBOOLEAN(  [n], [dry-run],
  [validate command line and exit],[],
  [[do_dryrun=:]])dnl
[
Validate the full command line and exit.

This includes verifying that any files mentioned actually exist for reading or are writeable in the way you're expecting, and, if we actually get to the point of being able to do anything, output the settings that matter, showing what would happen if @command{m5run} were allowed to preceed beyond this point (which it won't be).

This will also show you command line options set implicitly that might not otherwise have been obvious.
]
dnl -----------------
dnl  -h|+h|-?|--help
M5_OPTION_INFOBOOLEAN(  [h], [help],
  [print this text and exit],[?],
  [[do_help=:]])dnl
[
Print the help text and exit.
]
dnl -----------------
dnl  -V|+V|--version
M5_OPTION_INFOBOOLEAN(  [V], [version],
  [print version info and exit],[],
  [[do_version=:]])dnl
[
Print version information and exit.
]
dnl
dnl  --about
M5_OPTION_INFOBOOLEAN(  [], [about],
  [print detailed version info and exit],[],
  [[do_version=:
    do_verbose=:]])dnl
[
Print the ``about'' box.  This is the same as @option{--version --verbose}.
]dnl
