# Based on /etc/firejail/shellcheck.profile
# Customizations are needed because the default profile is too restrictive. For
# example, the ~/.xsession file can't be checked with it.

quiet
noblacklist ${HOME}/.local/bin
noblacklist ${HOME}/.my_scripts
noblacklist ${HOME}/.config
noblacklist ${HOME}/.config/fasd
noblacklist ${HOME}/.config/git
noblacklist ${HOME}/.config/git/hooks
noblacklist ${HOME}/.config/google
noblacklist ${HOME}/.config/i3
noblacklist ${HOME}/.config/ranger
noblacklist ${HOME}/.xsession
ignore memory-deny-write-execute
include /etc/firejail/shellcheck.profile
