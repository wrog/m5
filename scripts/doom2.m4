m4_rename([_m4_divert(BINSH)], [_m4_divert(BINSH-ACTUAL)])dnl
m4_copy(  [_m4_divert(KILL)],  [_m4_divert(BINSH)])dnl
AS_INIT()dnl
m4_divert_text([BINSH-ACTUAL],[@%:@!@CONFIG_SHELL@])dnl
m4_divert_text([HEADER-COMMENT],
[#
CONFIG_SHELL=@CONFIG_SHELL@
m5_legal_msg="$(cat <<'ENDLEGAL'
m4_include([../AUTHOR])
m4_include([../LICENSE])
ENDLEGAL
)"
[m5_version]="@VERSION@"
[m5_website]="@PACKAGE_URL@"
[prefix]="@prefix@"
[bindir]="@bindir@"
[pkgdatadir]="@pkgdatadir@"
])dnl
AS_ME_PREPARE[]dnl
m4_include([optshell.m4])dnl
m4_divert_push([KILL])dnl
m4_include([options.m4])dnl
m4_divert_pop([KILL])dnl
m4_include([doom.m4])dnl
