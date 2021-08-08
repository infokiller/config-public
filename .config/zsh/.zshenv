# This file is sourced in every zsh invocation (unless explicitly disabled with
# NO_RCS), so it should be kept efficient.
# Set ZSHENV_DIR to the directory of this file after resolving symlinks, which
# should normally point at "${XDG_CONFIG_HOME}/zsh"
ZSHENV_DIR="${${${(%):-%x}:P}:h}"
export ZDOTDIR="${ZDOTDIR:-${ZSHENV_DIR}}"

# In zeus18 this increases the shell startup time by about 3-4 ms.
emulate sh -c 'source ${ZSHENV_DIR}/../../.profile'

# Skip global config files in /etc since they're probably not useful for me, and
# will increase the startup latency of interactive shells.
# As of 2020-06-02, I enabled global config files, because there's no measurable
# difference in shell startup latency, and looking at /etc/profile and
# /etc/profile.d it seems they may be useful: on my arch system it has VTE
# terminal fixes and PATH settings for flatpak and perl.
# setopt NO_GLOBAL_RCS

# Disable Ubuntu's global compinit call in /etc/zsh/zshrc, which slows down
# shell startup time significantly. Note that this doesn't have an effect
# when NO_GLOBAL_RCS is set, but can't hurt.
skip_global_compinit=1
