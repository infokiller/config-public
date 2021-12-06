#!/usr/bin/env bash
# Environment and terminal settings shared by bash and zsh.
# Requires:
# - is_bash
# - is_zsh
# - is_wsl{1,2,}
# - print_error

# A list of environment variables that are updated from the parent tmux session
# on every prompt, if running in tmux.
# Tmux maintains a list of environment variables for every session that
# affect the environment of new processes started in that session. The list of
# variables is configured using the `update-environment` option and can
# be shown using `tmux show-options -g update-environment`.
# Tmux sets the values of these variables from clients that create a session or
# attach to an existing one.
# I used to set/unset all the tmux session environment variables which can be
# done using: `eval "$(tmux show-environment -s)"`.  However, I now don't
# really see a reason to set all the variables when I can set only the ones
# that are relevant for my setup.
declare -g ENV_VARS_UPDATED_FROM_TMUX=(
  DISPLAY
  # KRB5CCNAME
  # SSH_ASKPASS
  # NOTE: As of 2020-04-15, I stopped setting SSH_AUTH_SOCK because I ran into
  # cases where tmux unsets it when I'm connecting using SSH.
  # TODO: Figure this out.
  # SSH_AUTH_SOCK
  # As of 2020-05-06, I enabled SSH_CONNECTION because otherwise zsh won't
  # pick up that we're on an SSH connection, and the prompt won't be updated
  # properly.
  # SSH_AGENT_PID
  SSH_CONNECTION
  WINDOWID
  XAUTHORITY
  COLORTERM
)

: "${REPO_ROOT:=$([[ ${CONFIG_GET_ROOT:-0} == 1 ]] && config-repo-root "${BASH_SOURCE[0]:-${(%):-%x}}" || echo "${HOME}")}"
# shellcheck source=../../.my_scripts/lib/base.sh
source "${REPO_ROOT}/.my_scripts/lib/base.sh"

_is_ssh() {
  [[ -n ${SSH_CLIENT-} || -n ${SSH_TTY-} || -n ${SSH_CONNECTION-} ]]
}

_is_tmux() {
  [[ -n ${TMUX-} ]]
}

_get_real_terminal() {
  if _is_tmux; then
    tmux display-message -p '#{client_termname}'
  else
    printf '%s' "${TERM}"
  fi
}

declare -g _update_env_from_tmux_on="${_update_env_from_tmux_on:-1}"

# Updates environment variables from tmux when SSH is detected.
# This propagates the correct value of environment variables to shells in
# tmux that are connected to via SSH.
# TODO: This is slow because of the call to `tmux show-environment`. I measured
# about 10ms in zeus18.
update_environment_from_tmux() {
  if ((!_update_env_from_tmux_on)) || ! _is_tmux; then
    return 0
  fi
  if is_zsh; then
    emulate -L zsh -o BASH_REMATCH -o KSH_ARRAYS
  fi
  declare -A var_to_cmd
  while IFS='' read -r cmd; do
    if [[ "${cmd}" =~ unset\ ([a-zA-Z_][a-zA-Z_0-9]+)\;? ]] ||
      [[ "${cmd}" =~ ([a-zA-Z_][a-zA-Z_0-9]+)= ]]; then
      var_to_cmd["${BASH_REMATCH[1]}"]="${cmd}"
    else
      # I ran into an issue with the command returning successfully but echoing
      # "server version is too old for client"
      print_error 'update_environment_from_tmux: unexpected command' \
        "'${cmd}', disabling env update"
      _update_env_from_tmux_on=0
      break
    fi
  done < <(tmux show-environment -s)
  # if [[ -z "${var_to_cmd[SSH_CONNECTION]-}" ]]; then
  #   return 0
  # fi
  for var in "${ENV_VARS_UPDATED_FROM_TMUX[@]}"; do
    eval -- "${var_to_cmd["${var}"]-}"
  done
}

# Sets the TTY variable if it's not already set.
_maybe_set_tty() {
  [[ -n ${TTY-} ]] && return
  # zsh already defines the TTY variable if it's connected to a tty, so if the
  # TTY var is not set it means it's not connected to a tty.
  is_zsh && return 1
  local tty
  # I originally tried to use `tty --quiet` to only get the exit code, but I ran
  # into a bug when running it from a shell spawned from a firejailed ranger. In
  # this environment, `tty` had an exit code of 1 and printed "not a tty", while
  # `tty --quiet` exited with 0.
  if ! tty="$(tty)"; then
    return 1
  fi
  declare -g TTY="${tty}"
}

# https://gist.github.com/XVilka/8346728#now-supporting-true-color
_maybe_set_colorterm() {
  if ((${VTE_VERSION:-0} >= 3600)); then
    export COLORTERM='truecolor'
  else
    local terminal
    terminal="$(_get_real_terminal)"
    case "${terminal}" in
      # NOTE: tmux-256color can be reported as the real terminal when
      # I'm SSHing from a tmux session in my local machine.
      xterm-kitty | xterm-termite | tmux-256color)
        export COLORTERM='truecolor'
        ;;
    esac
  fi
  if [[ -n "${COLORTERM-}" ]] && _is_tmux; then
    tmux set-environment COLORTERM "${COLORTERM}"
  fi
}

# Settings specific to terminals running under x (xterm, terminator, guake,
# urxvt, etc).
_set_x11_terminal_settings() {
  # Set terminal title.
  if is_zsh; then
    emulate -L zsh
    _set_terminal_title_to_cmd() {
      # The (V) parameter expansion flag makes special chars printable, similar
      # to `cat -v`.
      printf '\e]0;%s\a' "${(V)1}" > "${TTY}"
    }
    _set_terminal_title_to_pwd() {
      printf '\e]0;%s\a' "${(%):-%~}" > "${TTY}"
    }
    autoload -Uz add-zsh-hook
    add-zsh-hook preexec _set_terminal_title_to_cmd
    # When no command is running, show the current directory.
    add-zsh-hook precmd _set_terminal_title_to_pwd
  elif is_bash; then
    # NOTE As of 2018-5-26, this started breaking the prompt on Arch, see:
    # https://unix.stackexchange.com/questions/104018/set-dynamic-window-title-based-on-command-input#comment159209_104026
    # the bash trap builtin is a hook to run a custom command before executing any command.
    # NOTE: As of 2019-06-15, this seems to work again.
    trap 'printf "\e]0;%s\a" "$(printf "%s" "${BASH_COMMAND}" | cat -v)" > "${TTY}"' DEBUG
  else
    printf >&2 'Unrecognized shell!\n'
  fi
}

_set_terminal_settings() {
  if is_zsh; then
    # Do not use Ctrl-s/Ctrl-q as flow control.
    setopt NO_FLOW_CONTROL
  elif is_bash; then
    # Disables terminal flow-control in bash to enable the Ctrl+S key for
    # forward history search. See:
    # http://ruslanspivak.com/2010/11/25/bash-history-incremental-search-forward/
    stty --file="${TTY}" -ixon
  else
    printf >&2 'Unrecognized shell!\n'
  fi
  if [[ -n "${DISPLAY-}" ]]; then
    _set_x11_terminal_settings
  fi
  # SSH does not set the COLORTERM variable by default. The `SendEnv` can be
  # used to send it, but the server must be configured to accept it using the
  # AcceptEnv in sshd_config. This ensures that COLORTERM is set for some
  # terminals that are known to support it.
  if [[ -z "${COLORTERM-}" ]] && _is_ssh; then
    _maybe_set_colorterm
  fi
}

_setup_ssh_agent() {
  # TODO: Use an alternative SSH agent since gpg agent doesn't respect the
  # identity files order.
  # Set SSH_AUTH_SOCK so that gpg-agent can be used as an SSH agent. See also:
  # https://wiki.archlinux.org/index.php/GnuPG#Set_SSH_AUTH_SOCK
  unset SSH_AGENT_PID
  if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
    SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    export SSH_AUTH_SOCK
  fi
  # eval "$(ssh-agent -s)" > /dev/null

  # Set SSH_AUTH_SOCK if connecting via SSH. This is done to make SSH forwarding
  # work in tmux. See also: https://gist.github.com/martijnvermaat/8070533
  if [[ -S ${SSH_AUTH_SOCK-} && ! -L ${SSH_AUTH_SOCK-} ]]; then
    [[ -d "${HOME}/.ssh" ]] || mkdir -p -- "${HOME}/.ssh/"
    local ssh_auth_sock="${HOME}/.ssh/ssh_auth_sock"
    # Only export if the ln command succeeds. It can fail from firejail.
    if ln -sf -- "${SSH_AUTH_SOCK}" "${ssh_auth_sock}"; then
      export SSH_AUTH_SOCK="${ssh_auth_sock}"
    fi
  fi
}

_setup_gpg_agent() {
  # man gpg-agent says to put this in shell initialization files. Also
  # mentioned in:
  # https://wiki.archlinux.org/index.php/GnuPG#Configure_pinentry_to_use_the_correct_TTY
  # Note that we use the `$TTY` variable instead of calling the `tty` command
  # since the former is much faster in zsh, and works with instant prompt. See:
  # https://github.com/romkatv/zsh4humans/issues/8#issuecomment-595730984
  export GPG_TTY="${TTY}"
  # See comments in ~/.local/bin/ssh and ~/.local/bin/sensible-pinentry.
  gpg-connect-agent updatestartuptty /bye &> /dev/null
}

# For WSL1 see: https://github.com/romkatv/dotfiles-public/blob/eb1b3813baf5288c22aacf33d39e40330a18b1a2/.zshrc#L54
# For WSL2 see: https://github.com/microsoft/WSL/issues/4106
_set_wsl_display() {
  export NO_AT_BRIDGE=1
  export LIBGL_ALWAYS_INDIRECT=1
  if is_wsl1; then
    export DISPLAY=:0
  elif is_wsl2; then
    local host_ip
    # host_ip="$(grep --max-count=1 --only-matching --perl-regexp \
    #   '(?<=nameserver ).+' /etc/resolv.conf)"
    # NOTE: As of 2020-01-27, the above command doesn't work for me but the one
    # below does. See : https://github.com/microsoft/WSL/issues/4106#issuecomment-577895076
    host_ip="$(dig +noall +answer "$(hostname -s)" | tail -1 | awk '{print $5}')"
    export DISPLAY="${host_ip}:0"
  fi
}

_setup_conda() {
  if [[ -r "${HOME}/.local/pkg/conda/etc/profile.d/conda.sh" ]]; then
    # Setting CONDA_SHLVL prevents the script from modifying the PATH variable.
    CONDA_SHLVL=0
    # shellcheck source=../../.local/pkg/conda/etc/profile.d/conda.sh
    source "${HOME}/.local/pkg/conda/etc/profile.d/conda.sh"
  fi
}

_do_common_shell_setup() {
  _setup_conda

  if _maybe_set_tty; then
    _set_terminal_settings
    _setup_ssh_agent
    _setup_gpg_agent
  fi

  if [[ -z ${DISPLAY-} ]] && is_wsl; then
    _set_wsl_display
  fi
}

_do_common_shell_setup
