# NOTE: I disabled the default profile because I ran into recurring problems
# while trying to define the ranger sandbox. The main issue is that ranger is
# designed to launch other programs, and these program inherits its firejail
# sandbox. Therefore, in principle firejail needs the permissions of all the
# potentially launched problems.

# NOTE: I wanted to use the following options but they prevent from Chromium to
# open from ranger. For testing I can try to start Chromium directly with the
# firejail profile:
# firejail --profile=${HOME}/.config/firejail/ranger.profile /bin/chromium
# caps.drop all
# noroot
# seccomp
# nonewprivs
# The whitelisted caps below are needed for Chrome to open.
caps.keep sys_admin,sys_chroot
net none
# NOTE: As of 2019-06-15, private-dev is disabled because it causes issues with
# bash scripts that use temporary files in /dev/fd.
# private-dev
nodvd
notv

# # inet is required for YouCompleteMe to work inside vim invocations done by
# # ranger when opening text files.
# # unix is required for image previews.
# # NOTE: I disabled this because otherwise chrome can't launch.
# # protocol unix,inet

# # Needed for zathura to be able to read its config file, but possibly also by
# # other programs that are invoked by ranger.
# noblacklist ${HOME}/.config/*
# # Probably needed by these programs.
# noblacklist ${HOME}/.local/share/zathura
# read-write ${HOME}/.local/share/zathura
# noblacklist ${HOME}/.local/share/geeqie
# read-write ${HOME}/.local/share/geeqie

# # Required for trash integration.
# noblacklist ${HOME}/.local/share/Trash

# # Some /etc directories are disabled in common.profile but it can be useful to
# # make them readable when browsing config directories.
# noblacklist /etc/*

# # Perl interpreters are marked as noblacklist in the ranger.profile file from
# # the package for some reason, so this makes sure they stay blacklisted.
# blacklist ${PATH}/perl

# # Needed for opening files in tmux panes/windows.
# noblacklist /tmp/tmux-*

# include /etc/firejail/ranger.profile

# # Needed when invoking a shell from ranger.
# read-write ${HOME}/submodules/zplug/

# include ${HOME}/.config/firejail/enable-vimdirs.inc
