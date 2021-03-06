#!/usr/bin/env bash
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "${PS1-}" ] && return

###############################################################################
#####                          General settings                           #####
###############################################################################

readonly REPO_ROOT="$([[ ${CONFIG_GET_ROOT:-0} == 1 ]] && config-repo-root "${BASH_SOURCE[0]}" || echo "${HOME}")"
readonly SUBMODULES_DIR="${REPO_ROOT}/submodules"
# shellcheck source=./.profile
source "${REPO_ROOT}/.profile"
# shellcheck source=./.my_scripts/lib/base.sh
source "${REPO_ROOT}/.my_scripts/lib/base.sh"
# shellcheck source=./.my_scripts/lib/platform_detection.sh
source "${REPO_ROOT}/.my_scripts/lib/platform_detection.sh"

SHELL_CONFIG_DIR="${REPO_ROOT}/.config/bash"
# shellcheck source=./.my_scripts/lib/base.sh
# shellcheck source=./.config/bash/settings.sh
source "${SHELL_CONFIG_DIR}/settings.sh"

# Require at least this number of EOF (Ctrl+d) before exiting. Bash specific,
# zsh uses setopt for that.
export IGNOREEOF=1

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the extended pattern matching features described above (see Pattern
# Matching) are enabled.
shopt -s extglob
# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar
# If set, bash includes filenames beginning with a `.' in the results of
# pathname expansion.  The filenames ``.''  and ``..''  must always be matched
# explicitly, even if dotglob is set.
shopt -s dotglob
# If set, bash allows patterns which match no files (see Pathname Expansion
# above) to expand to a null string, rather than themselves.
shopt -s nullglob

# Makes sure that executing previous commands using !prefix will not execute
# "blindly". See:
# http://superuser.com/questions/7414/how-can-i-search-the-bash-history-and-rerun-a-command
shopt -s histverify

# fix spell errors.
shopt -s cdspell
# If set, Bash attempts spelling correction on directory names during word
# completion if the directory name initially supplied does not exist.
shopt -s dirspell
# If set, a command name that is the name of a directory is executed as
# if it were the argument to the cd command. This option is only used by
# interactive shells.
shopt -s autocd

###############################################################################
#####                         History management                          #####
###############################################################################
# shellcheck source=./.config/bash/history/history.sh
source "${SHELL_CONFIG_DIR}/history/history.sh"

# Options set:
# - ignoredups: don't put duplicate lines in the history.
# - ignorespace: if the command begins with a space, don't save it. Useful for
#   commands that have sensitive information.
HISTCONTROL=ignoredups:ignorespace

# Append to the history file, don't overwrite it
shopt -s histappend

HISTFILE="$(get_host_history_dir)/bash_history"
HISTSIZE=100000
HISTFILESIZE=200000
# Only output a Unix timestamp in the `history` builtin. Set this way to
# simplify the parsing of lines for the persistent history file (see below).
# Note that the suffix space is required to separate the timestamp from the
# command.
HISTTIMEFORMAT='%s '

histcat_append_hook() {
  [[ $(history 1) =~ ^\ *[0-9]+\ *[0-9]+\ (.*)$ ]]
  local command="${BASH_REMATCH[1]}"
  if [[ -z "${command-}" ]]; then
    print_error 'History hook could not extract command'
    return 1
  fi
  # TODO: The last argument should be the expanded command (expanding
  # aliases etc.), but I don't know how to do this in bash.
  histcat-verify
  histcat add --typed-command "${command}"
}

PROMPT_COMMAND="histcat_append_hook; ${PROMPT_COMMAND}"

###############################################################################
#####                              Plugins                                #####
###############################################################################

# Set up solarized dircolors from https://github.com/seebi/dircolors-solarized
if [[ -r "${SUBMODULES_DIR}/terminal/dircolors-solarized/dircolors.256dark" ]]; then
  eval -- "$(dircolors "${SUBMODULES_DIR}/terminal/dircolors-solarized/dircolors.256dark")"
fi

# Initialize https://github.com/clvv/fasd
_bashrc_init_fasd() {
  local XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
  local fasd_cache_dir="${XDG_CACHE_HOME}/fasd"
  [ -d "${fasd_cache_dir}" ] || mkdir -p -- "${fasd_cache_dir}"
  local fasd_cache="${fasd_cache_dir}/fasd-init-bash"
  if [[ ! -e "${fasd_cache}" ]] || [[ "$(realpath "$(command -v fasd)")" -nt "${fasd_cache}" ]]; then
    fasd --init bash-hook bash-ccomp >| "${fasd_cache}"
    echo '_fasd_bash_hook_cmd_complete fasd' >> "${fasd_cache}"
  fi
  # shellcheck disable=SC1091
  # shellcheck source=.cache/fasd/fasd-init-bash
  source "${fasd_cache}"
}

_bashrc_init_fasd

# shellcheck source=./.config/bash/functions.sh
source "${SHELL_CONFIG_DIR}/functions.sh"

# shellcheck source=submodules/terminal/fzf/shell/key-bindings.bash
source "${SUBMODULES_DIR}/terminal/fzf/shell/key-bindings.bash"
# Redefine the function __fzf_history__ to use my persistent history.
# Original function is at:
# https://github.com/junegunn/fzf/blob/master/shell/key-bindings.bash
__fzf_history__() {
  # conda-run shell_history \
  #   "$HOME/.config/bash/history/shell_history_choose_line.py"
  output="$(histcat-select "$@")"
  READLINE_LINE=${output#*$'\t'}
  if [ -z "$READLINE_POINT" ]; then
    echo "$READLINE_LINE"
  else
    READLINE_POINT=0x7fffffff
  fi
}

###############################################################################
#####                            Completions                              #####
###############################################################################

# Enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
  # shellcheck disable=SC1091
  source /etc/bash_completion
fi

# Tmux bash completion.
_tmux_completion_path=/usr/share/doc/tmux/examples/bash_completion_tmux.sh
if [[ -f ${_tmux_completion_path} ]]; then
  # shellcheck disable=SC1090
  source "${_tmux_completion_path}"
fi

# Bash completion for updating apt repos.
# shellcheck source=./.config/bash/completion.sh
source "${SHELL_CONFIG_DIR}/completion.sh"

###############################################################################
#####                               Prompt                               #####
###############################################################################

_gitstatus_bash_prompt="${SUBMODULES_DIR}/zsh/powerlevel10k/gitstatus/gitstatus.prompt.sh"
if [[ -f "${_gitstatus_bash_prompt}" ]]; then
  # shellcheck source=./submodules/zsh/powerlevel10k/gitstatus/gitstatus.prompt.sh
  source "${_gitstatus_bash_prompt}"
fi

###############################################################################
#####                               Local                                #####
###############################################################################

if [[ -f "${SHELL_CONFIG_DIR}/bashrc_local.sh" ]]; then
  # shellcheck disable=SC1090
  source "${SHELL_CONFIG_DIR}/bashrc_local.sh"
fi
