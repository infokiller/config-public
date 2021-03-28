quiet

# The settings below are copied from the default profile with disable-common and disable-programs
# commented out, as it blacklists paths of config files that I may want
# to see with highlight.
# include /etc/firejail/highlight.profile

# Enable lua for plugins
include allow-lua.inc

# include disable-common.inc
include disable-devel.inc
include disable-interpreters.inc
include disable-passwdmgr.inc
# include disable-programs.inc

caps.drop all
net none
no3d
nodbus
nodvd
nogroups
nonewprivs
noroot
nosound
notv
nou2f
novideo
protocol unix
seccomp
shell none
tracelog
x11 none

private-bin highlight
private-cache
private-dev
private-tmp

# vim: set ft=conf :
