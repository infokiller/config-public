# This file is sourced in every zsh invocation (unless explicitly disabled with
# NO_RCS), so it should be kept efficient.
# Set ZSHENV_DIR to the directory of this file after resolving symlinks, which
# should normally point at "${XDG_CONFIG_HOME}/zsh"
ZSHENV_DIR="${${${(%):-%x}:P}:h}"
export ZDOTDIR="${ZDOTDIR:-${ZSHENV_DIR}}"

_is_ssh() {
  [[ -n ${SSH_CLIENT-} || -n ${SSH_TTY-} || -n ${SSH_CONNECTION-} ]]
}

# As of 2021-08-28, this increases the shell startup time in zeus18 by 20 ms.
# NOTE: As of 2021-09-12, on Archlinux (but not Ubuntu), /etc/zsh/zprofile
# sources /etc/profile. Since /etc/zsh/zprofile is sourced after .zshenv (but
# before .zshrc), it can override environment variables sourced from this file.
# To fix this, I'm now sourcing .profile in .zshrc. This also has the added
# benefit of reducing time before first prompt because it's only done after p10k
# instant prompt.
# NOTE: When using `ssh <host> <command>` it seems that .zshenv is read when zsh
# is configured as the shell for the user. In this case, .profile won't be
# sourced from .zlogin, so we source it here.
if _is_ssh && [[ ! -o INTERACTIVE ]]; then
  _IKL_PROFILE_LOADED=1
  emulate sh -c 'source ${ZSHENV_DIR}/../../.profile'
fi

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
