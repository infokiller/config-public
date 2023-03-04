#!/usr/bin/env sh
#
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1) if ~/.bash_profile or ~/.bash_login exist.
#
# This file must be POSIX compliant and not rely on any bash specific features.
# To test for POSIX compatibility, you can run `dash ~/.profile` and check that
# there are no errors.
#
# The default umask is set in /etc/profile; for setting the umask for ssh
# logins, install and configure the libpam-umask package.

_command_exists() {
  command -v -- "$1" > /dev/null 2>&1
}

# https://kerneltalks.com/linux/all-you-need-to-know-about-hostname-in-linux/
_get_hostname() {
  cat /proc/sys/kernel/hostname
}

# Function stolen from: https://stackoverflow.com/a/8811800
# _contains(string, substring)
# Returns 0 if the specified string contains the specified substring,
# otherwise returns 1.
_contains() {
  string="$1"
  substring="$2"
  if test "${string#*"${substring}"}" != "${string}"; then
    return 0 # ${substring} is in ${string}
  else
    return 1 # ${substring} is not in ${string}
  fi
}

# My benchmarks show that unconditionally calling `mkdir -p` is much slower than
# checking if the directory exists first.
_maybe_create_dir() {
  test -d "$1" || mkdir -p -- "$1"
}

# Check if a PATH-like variable contains a directory in a POSIX shell compliant
# way. This is a faster alternative than grep.
_path_contains_dir() {
  path_var="$1"
  dir="$2"
  case "${path_var}" in
    ${dir}:* | *:${dir} | *:${dir}:*) return 0 ;;
  esac
  return 1
}

_prepend_to_path() {
  if test -z "${PATH-}"; then
    export PATH="$1"
    return
  fi
  if ! _path_contains_dir "${PATH}" "$1"; then
    export PATH="$1:${PATH}"
  fi
}

_prepend_to_manpath() {
  if test -z "${MANPATH-}"; then
    # NOTE: MANPATH must have a colon as a prefix in order to use the default
    # man paths in addition to custom ones defined in the MANPATH variable. See
    # also: https://askubuntu.com/a/693612/368043
    export MANPATH=":$1"
    return
  fi
  if ! _path_contains_dir "${MANPATH}" "$1"; then
    # See note above- MANPATH must have a colon as prefix.
    export MANPATH=":$1:${MANPATH}"
  fi
}

# Log out virtual consoles automatically after 10 minutes of inactivity.
# This decreases the chance that screen-locking will be easily circumvented if I
# forgot to log out from a virtual console.
# Copied from: https://wiki.archlinux.org/index.php/Security#Automatic_logout
_maybe_set_auto_logout() {
  # test -z "${DISPLAY-}" && export TMOUT=600
  case "$(tty)" in
    /dev/tty[0-9]*) export TMOUT=600 ;;
    *) unset TMOUT ;;
  esac
}

_export_path_vars() {
  # Set go variables. See https://golang.org/doc/code.html
  # NOTE: Consider using multiple directories in GOPATH to separate my own
  # packages from other packages. See also:
  # https://stackoverflow.com/q/36017724/1014208
  export GOPATH="${HOME}/.local/pkg/go"
  if test -d "${HOME}/.local/pkg/goroot"; then
    export GOROOT="${HOME}/.local/pkg/goroot/go"
  fi
  # shellcheck disable=SC2236
  if test -n "${GOROOT-}"; then
    _prepend_to_path "${GOROOT}/bin"
  fi
  # User provided binaries- contains my own scripts and symlinks to binaries
  # installed by npm/pip/etc.
  _prepend_to_path "${HOME}/.local/bin"
  _prepend_to_manpath "${XDG_DATA_HOME}/man"
}

_export_xdg_user_dirs() {
  if ! test -r "${XDG_CONFIG_HOME}/user-dirs.dirs"; then
    return
  fi
  # shellcheck source=/.config/user-dirs.dirs
  . "${XDG_CONFIG_HOME}/user-dirs.dirs"
  export \
    XDG_DESKTOP_DIR \
    XDG_DOWNLOAD_DIR \
    XDG_TEMPLATES_DIR \
    XDG_PUBLICSHARE_DIR \
    XDG_DOCUMENTS_DIR \
    XDG_MUSIC_DIR \
    XDG_PICTURES_DIR \
    XDG_VIDEOS_DIR
}

_export_history_vars() {
  # Custom environment variable used by bash, zsh, vim, and others for storing
  # command history for the local host.
  HOST_HIST_DIR="${HOME}/.local/var/hist/$(_get_hostname)"
  export HOST_HIST_DIR
  _maybe_create_dir "${HOST_HIST_DIR}"
  export LESSHISTFILE="${HOST_HIST_DIR}/less"
  export NODE_REPL_HISTORY="${HOST_HIST_DIR}/node_repl_history"
  export NODE_REPL_HISTORY_SIZE=100000
  export SQLITE_HISTORY="${HOST_HIST_DIR}/sqlite_history"
  export PSQL_HISTORY="${HOST_HIST_DIR}/psql_history"
  export MYSQL_HISTFILE="${HOST_HIST_DIR}/mysql_history"
  export TMUXP_CONFIGDIR="${HOST_HIST_DIR}/tmuxp"
  _maybe_create_dir "${TMUXP_CONFIGDIR}"
}

# Set program specific environment variables to increase XDG conformance. The
# downside of this approach is that this clutters the environment. Other
# alternatives are:
# - Creating a wrapper script per program which sets environment variables
#   and/or CLI options. The downsides of this approach are that it increases
#   programs startup time by a few milliseconds, and it requires creating many
#   files.
# - Defining shell aliases. The downside of this approach is that it will
#   typically only work in interactive shell sessions, because aliases are not
#   considered by default in other execution contexts. Hence, this approach
#   should generally be avoided.
#
# References (last review date: 2020-05-30):
# - https://wiki.archlinux.org/index.php/XDG_Base_Directory#Support
# - https://github.com/grawity/dotfiles/blob/master/.dotfiles.notes
_increase_xdg_conformance() {
  export XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
  # XDG_RUNTIME_DIR is guaranteed to be owned by the user, so it should be safer
  # to use than /tmp. However, systemd limits it to 10% of the physical memory
  # by default [1], so it can run out of space when used with large files. It's
  # possible to increase the size of /run/user/uid by configuring logind [2].
  # [1] https://www.freedesktop.org/software/systemd/man/logind.conf.html
  # [2] https://www.golinuxcloud.com/change-tmpfs-partition-size-redhat-linux
  if test -z "${TMPDIR-}" && test -n "${XDG_RUNTIME_DIR-}"; then
    export TMPDIR="${XDG_RUNTIME_DIR}/tmp"
    export TMUX_TMPDIR="${TMPDIR}"
    _maybe_create_dir "${TMPDIR}"
  fi
  export ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME}/zsh}"
  export VIMINIT="source ${XDG_CONFIG_HOME}/vim/vimrc"
  export INPUTRC="${XDG_CONFIG_HOME}/inputrc"
  export GNUPGHOME="${XDG_CONFIG_HOME}/gnupg"
  # https://github.com/rust-lang/cargo/blob/master/src/doc/environment-variables.md
  export CARGO_HOME="${HOME}/.local/pkg/cargo"
  # https://github.com/rust-lang/rustup/blob/ddeda7c13119fe78c50b75914b4729fa7bf82c13/README.md#L138
  export RUSTUP_HOME="${XDG_DATA_HOME}/rustup"
  # When this variable is set, Python 3.8 and later will use it to write .pyc
  # files in a parallel directory tree:
  # https://docs.python.org/3/using/cmdline.html#envvar-PYTHONPYCACHEPREFIX
  export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME}/python"
  # If this is the name of a readable file, the Python commands in that file are
  # executed before the first prompt is displayed in interactive mode. Commented
  # out because I never really use the Python interpreter interactively (IPython
  # is much better), and IPython prints a warning if this file doesn't exist.
  # export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/pythonrc"
  export PYTHON_EGG_CACHE="${XDG_CACHE_HOME}/python-eggs"
  export PIP_CONFIG_FILE="${XDG_CONFIG_HOME}/pip/pip.conf"
  export PIP_LOG_FILE="${XDG_DATA_HOME}/pip/log"
  # Use ~/.config/ipython for ipython configuration. Note that without using this,
  # ipython moves the config files to ~/.ipython. See also:
  # https://ipython.readthedocs.io/en/stable/config/intro.html#the-ipython-directory
  export IPYTHONDIR="${XDG_CONFIG_HOME}/ipython"
  # Same for Jupyter, see also: https://github.com/jupyter/notebook/issues/1355
  export JUPYTER_CONFIG_DIR="${XDG_CONFIG_HOME}/jupyter"
  # Directory for storing persistent pylint data for comparing different runs.
  # By default pylint stores data in ${HOME}/.pylint.d
  export PYLINTHOME="${XDG_CACHE_HOME}/pylint"
  # export PYLINTRC="${XDG_CONFIG_HOME}/pylintrc"
  # https://github.com/deshaw/pyflyby
  # The dash is used to get the default pyflyby value.
  export PYFLYBY_PATH="-:${XDG_CONFIG_HOME}/pyflyby"
  export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npmrc"
  # NPM_CONFIG_CACHE seems unnecessary since it's already set in
  # ${XDG_CONFIG_HOME}/npmrc
  # export NPM_CONFIG_CACHE="${XDG_CACHE_HOME}/npm"
  export YARN_CACHE_FOLDER="${XDG_CACHE_HOME}/yarn"
  export PNPM_HOME="${XDG_DATA_HOME}/pnpm"
  export GEMRC="${XDG_CONFIG_HOME}/gemrc"
  export GEM_HOME="${HOME}/.local/pkg/gem"
  export GEM_SPEC_CACHE="${XDG_CACHE_HOME}/gem"
  # TODO: Using HIGHLIGHT_DATADIR doesn't seem to work.
  export HIGHLIGHT_DATADIR="${XDG_DATA_HOME}/highlight"
  export CUDA_CACHE_PATH="${XDG_CACHE_HOME}/nv"
  export KERAS_HOME="${XDG_CONFIG_HOME}/keras"
  export FASTAI_HOME="${XDG_CONFIG_HOME}/fastai"
  export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/config"
  export WAKATIME_HOME="${XDG_DATA_HOME}/wakatime"
  _maybe_create_dir "${WAKATIME_HOME}"
  export GTK2_RC_FILES="${XDG_CONFIG_HOME}/gtk-2.0/gtkrc"
  export KDEHOME="${XDG_CONFIG_HOME}/kde"
  # NOTE: if ${DOCKER_CONFIG}/config.json doesn't exist, podman has errors [1],
  # so we have an empty file there.
  export DOCKER_CONFIG="${XDG_CONFIG_HOME}/docker"
  export MACHINE_STORAGE_PATH="${XDG_DATA_HOME}/docker-machine"
  export VAGRANT_HOME="${XDG_DATA_HOME}/vagrant"
  export VAGRANT_ALIAS_FILE="${XDG_DATA_HOME}/vagrant/aliases"
  export JULIA_DEPOT_PATH="${XDG_DATA_HOME}/julia:${JULIA_DEPOT_PATH-}"
  export NLTK_DATA="${XDG_DATA_HOME}/nltk"
  export ATHAME_TEST_RC="${XDG_CONFIG_HOME}/athamerc"
  export ICEAUTHORITY="${XDG_CACHE_HOME}/ICEauthority"
  export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=${XDG_CONFIG_HOME}/java -Djavafx.cacheDir=${XDG_CACHE_HOME}/openjfx"
  export GRIPHOME="${XDG_CONFIG_HOME}/grip"
  # https://aesara.readthedocs.io/en/latest/library/config.html#envvar-AESARARC
  export AESARARC="${XDG_CONFIG_HOME}/aesara.ini"
  # NOTE: The variables below are commented out because they're not really used.
  # export RECOLL_CONFDIR="${XDG_CONFIG_HOME}/recoll"
  # export HTTPIE_CONFIG_DIR="${XDG_CONFIG_HOME}/httpie"
  # # https://github.com/molovo/revolver
  # export REVOLVER_DIR="${XDG_CACHE_HOME}/revolver"
  # export ELINKS_CONFDIR="${XDG_CONFIG_HOME}/elinks"
  # export MATHEMATICA_USERBASE="${XDG_CONFIG_HOME}/mathematica"
  # export NUGET_PACKAGES="${XDG_CACHE_HOME}/NuGetPackages"
  # export PARALLEL_HOME="${XDG_CONFIG_HOME}/parallel"
  # _maybe_create_dir "${XDG_CONFIG_HOME}/pg"
  # export PSQLRC="${XDG_CONFIG_HOME}/pg/psqlrc"
  # export PGPASSFILE="${XDG_CONFIG_HOME}/pg/pass"
  # export PGSERVICEFILE="${XDG_CONFIG_HOME}/pg/service.conf"
  # export AWS_CONFIG_FILE="${XDG_CONFIG_HOME}/aws/config"
  # export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME"/aws/credentials
  # export AZURE_CONFIG_DIR="${XDG_DATA_HOME}/azure"
  # export WEECHAT_HOME="${XDG_CONFIG_HOME}/weechat"
  # export RLWRAP_HOME="${XDG_DATA_HOME}/rlwrap"
  # export UNCRUSTIFY_CONFIG="${XDG_CONFIG_HOME}/uncrustify/uncrustify.cfg"
  # export NOTMUCH_CONFIG="${XDG_CONFIG_HOME}/notmuch/notmuchrc"
  # export NMBGIT="${XDG_DATA_HOME}/notmuch/nmbug"
  # export CCACHE_CONFIGPATH="${XDG_CONFIG_HOME}/ccache.config"
  # export CCACHE_DIR="${XDG_CACHE_HOME}/ccache"
  # export BASH_COMPLETION_USER_FILE="${XDG_CONFIG_HOME}/bash/bash-completion"
  # export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}/bundle"
  # export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}/bundle"
  # export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}/bundle"
  # export MOST_INITFILE="${XDG_CONFIG_HOME}/mostrc"
  # export MPLAYER_HOME="${XDG_CONFIG_HOME}/mplayer"
  # _maybe_create_dir "${XDG_DATA_HOME}/wineprefixes"
  # export WINEPREFIX="${XDG_DATA_HOME}/wineprefixes/default"
  # # Directories I may want to sync between machines using git and/or syncthing.
  # # I'll need to decide if I want to keep them in XDG dirs or move them (like
  # # the history files).
  # export PASSWORD_STORE_DIR="${XDG_DATA_HOME}/pass"
  # export LEDGER_FILE="${XDG_DATA_HOME}/hledger.journal"
  # export TASKDATA="${XDG_DATA_HOME}/task"
  # export TASKRC="${XDG_CONFIG_HOME}/task/taskrc"
}

_export_fzf_vars() {
  # I'm not sure what is the default FZF_DEFAULT_COMMAND, but it does not show
  # hidden files. See:
  # https://github.com/junegunn/fzf/issues/337#issuecomment-136383876
  export FZF_DEFAULT_COMMAND='list-searched-files'
  export FZF_DEFAULT_OPTS='--ansi --toggle-sort=ctrl-r'
  # export FZF_ALT_C_COMMAND='list-searched-files --list-dirs'
  if _command_exists bfs; then
    # Changes from upstream [1]:
    # - Use bfs instead of find
    # - Show hidden directories
    # [1] https://github.com/junegunn/fzf/blob/e4c3ecc5/shell/key-bindings.zsh#L73
    export FZF_ALT_C_COMMAND="command bfs -L . -mindepth 1 \\( -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type d -print 2> /dev/null | cut -b3-"
  fi
}

_get_less_version() {
  less --version | head -1 | grep -Eo '[0-9]{3,}'
}

_export_profile_env() {
  _export_path_vars
  _export_xdg_user_dirs
  _export_history_vars
  _export_fzf_vars
  _maybe_set_auto_logout
  _increase_xdg_conformance
  # Using Vim as the default editor and man pager.
  export EDITOR='vim'
  export SUDO_EDITOR="${EDITOR}"
  export MANPAGER='vim-man'
  export BROWSER='sensible-browser'
  # Default options for less. For documentation on the used flags see:
  # http://explainshell.com/explain?cmd=less+-RMiJSux4
  export LESS='--RAW-CONTROL-CHARS --LONG-PROMPT --status-column --ignore-case --chop-long-lines --underline-special --tabs=4'
  less_version="$(_get_less_version)"
  # Add options available in less 580 and later
  # http://greenwoodsoftware.com/less/news.580.html
  # https://unix.stackexchange.com/a/624305/126543
  if test "${less_version}" -ge 580; then
    LESS="${LESS} --line-num-width=4 --status-col-width=1 --incsearch"
  fi
  # Less version 590 added support for reading the source lesskey file, making
  # it unnecessary to generate the binary file.
  # http://greenwoodsoftware.com/less/news.590.html
  if test "${less_version}" -lt 590; then
    export LESSKEY="${XDG_CACHE_HOME}/lesskey_generated"
    if ! test -f "${LESSKEY}"; then
      # The clear-search action is not supported by older versions of less.
      grep -v 'clear-search' "${XDG_CONFIG_HOME}/lesskey" | lesskey -
    fi
  fi
  # Use scope.sh as a less preprocessor to get syntax highlighting and
  # reasonable previews for zip, pdf, etc.
  export LESSOPEN="| SCOPE_TRUECOLOR=1 HIGHLIGHT_OPTIONS='--line-numbers --line-number-length=0 --no-trailing-nl' ${HOME}/.config/ranger/scope.sh %s '80' '' '' False"
  # export LESSOPEN="| lesspipe-highlight %s"
  # Enable modules for packages inside GOPATH starting from go 1.11.
  export GO111MODULE=on
  export TAG_SEARCH_PROG='rg'
  # By default, pipenv stores the environment globally by hashing the project
  # path, which makes it problematic to move project directories. This makes
  # pipenv store the environment data in the project directory.
  export PIPENV_VENV_IN_PROJECT=1
  # Use trash instead of deleting by default.
  export NNN_TRASH=1
  # See https://phoenhex.re/2018-03-25/not-a-vagrant-bug
  export VAGRANT_DISABLE_VBOXSYMLINKCREATE=1
  if test -z "${MAKEFLAGS-}" && nproc="$(nproc)" > /dev/null 2>&1; then
    # Use all available cores by default when running make.
    export MAKEFLAGS="-j${nproc}"
  fi
  # https://github.com/greymd/tmux-xpanes
  export TMUX_XPANES_PANE_BORDER_STATUS='top'
  export TMUX_XPANES_PANE_BORDER_FORMAT='#[fg=yellow] #T#{?pane_pipe,[Log],} #[default]'
  export SEMGREP_SEND_METRICS='off'
}

_profile_main() {
  if test -z "${HOME-}"; then
    # shellcheck disable=SC2016
    echo '.profile: ERROR: $HOME undefined, trying to recover'
    HOME="$(getent passwd "$(id -u)" | cut -d: -f6)" || return
  fi

  # NOTE(infokiller): The default umask is 022 but I changed it following Lynis's
  # recommendations: https://cisofy.com/lynis/controls/AUTH-9328/
  umask 077

  # NOTE: We intentionally only set these variables if they're not already set
  # so that if they are readonly there won't be an error.
  # NOTE: When using `su` without --login, most of the environment is preserved,
  # which means the root user will inherit the XDG variables from the user
  # environment.
  : "${XDG_CONFIG_HOME:=${HOME}/.config}"
  : "${XDG_DATA_HOME:=${HOME}/.local/share}"
  : "${XDG_STATE_HOME:=${HOME}/.local/state}"
  : "${XDG_CACHE_HOME:=${HOME}/.cache}"

  _export_profile_env

  if test -r "${HOME}/.profile_private"; then
    # shellcheck source=/.profile_private
    . "${HOME}/.profile_private"
  fi
}

_profile_main
unset -f _profile_main
