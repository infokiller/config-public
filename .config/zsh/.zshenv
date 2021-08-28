# This file is sourced in every zsh invocation (unless explicitly disabled with
# NO_RCS), so it should be kept efficient.
# Set ZSHENV_DIR to the directory of this file after resolving symlinks, which
# should normally point at "${XDG_CONFIG_HOME}/zsh"
ZSHENV_DIR="${${${(%):-%x}:P}:h}"
export ZDOTDIR="${ZDOTDIR:-${ZSHENV_DIR}}"

# As of 2021-08-28, this increases the shell startup time in zeus18 by 20 ms.
# NOTE: Since some environment variables that are set in .profile are being
# overridden in /etc/profile (which is sourced after it but before .zshrc), I'm
# now sourcing .profile in .zshrc. This also has the added benefit of reducing
# time before first prompt because it's only done after p10k instant prompt.
# emulate sh -c 'source ${ZSHENV_DIR}/../../.profile'

# Skip global config files in /etc since they're probably not useful for me, and
# will increase the startup latency of interactive shells.
# As of 2020-06-02, I enabled global config files, because there's no measurable
# difference in shell startup latency, and looking at /etc/profile and
# /etc/profile.d it seems they may be useful: on my arch system it has VTE
# terminal fixes and PATH settings for flatpak and perl.
# As of 2021-08-11, I ran into an issue where settings from ~/.profile are
# being reset by files in /etc/profile.d because they run after ~/.zshenv.
# setopt NO_GLOBAL_RCS

# Disable Ubuntu's global compinit call in /etc/zsh/zshrc, which slows down
# shell startup time significantly. Note that this doesn't have an effect
# when NO_GLOBAL_RCS is set, but can't hurt.
skip_global_compinit=1
