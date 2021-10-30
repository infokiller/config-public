# If not running interactively, don't do anything
[ -z "${PS1}" ] && return

# The `:P` modifier is similar to realpath and will canonicalize the path,
# including resolving it to an absolute one.
: "${REPO_ROOT:="${$(print -r -- "${ZSHENV_DIR}/../.."):P}"}"
readonly REPO_ROOT
: "${SUBMODULES_DIR:="${REPO_ROOT}/submodules"}"
readonly SUBMODULES_DIR
: "${PLUGINS_DIR:="${SUBMODULES_DIR}/zsh"}"
readonly PLUGINS_DIR
: "${XDG_CACHE_HOME:=${HOME}/.cache}"
readonly XDG_CACHE_HOME
: "${XDG_DATA_HOME:="${HOME}/.local/share"}"
readonly XDG_DATA_HOME
: "${ZSH_CACHE_DIR:="${XDG_CACHE_HOME}/zsh"}"
readonly ZSH_CACHE_DIR
: "${SHELL_CONFIG_DIR:="${REPO_ROOT}/.config/bash"}"
readonly SHELL_CONFIG_DIR

# References:
# - https://stackoverflow.com/a/4351664/1014208
# - https://jb-blog.readthedocs.io/en/latest/posts/0032-debugging-zsh-startup-time.html
# - https://esham.io/2018/02/zsh-profiling
if ((${ZSHRC_ENABLE_PROFILING_BY_LINE:-0})); then
  if ((ZSHRC_ENABLE_PROFILING_BY_LINE == 2)); then
    # Duplicate stderr to a new file descriptor stderr_fd_dup and duplicate
    # stdout to stderr (including trace output). 
    # The end result is that the trace output will be written to stdout, and we
    # can later restore stderr to its original file using stderr_fd_dup.
    exec {stderr_fd_dup}>&2 2>&1
    setopt XTRACE
  else
    zmodload -F zsh/datetime +p:EPOCHREALTIME
    declare -g ZSHRC_START_TIME="${EPOCHREALTIME}"
    # %x expands to the executed file, and %N expands to the enclosing
    # function or file, so they can be the same if the code is not running within
    # a function. To make the output more readable, I tried to only echo %N if
    # it's different than %x, but that caused a major slowdown to the profiled
    # process, so I gave up.
    PS4='$((EPOCHREALTIME-ZSHRC_START_TIME)) %x:%I [%N] > '
    logfile="zsh_startup_by_line.$$.log"
    echo "zshrc: Writing per line timing data to file: ${logfile}"
    # Duplicate stderr to a new file descriptor stderr_fd_dup and redirect
    # stderr (including trace output) to the log file.
    # The end result is that the trace output will be written to the log file,
    # and we can later restore stderr to its original file using stderr_fd_dup.
    exec {stderr_fd_dup}>&2 2>"${logfile}"
    # Set options to turn on tracing and expansion of variables, commands, and
    # prompt sequences contained in the prompt.
    setopt XTRACE PROMPT_SUBST PROMPT_PERCENT
  fi
elif ((${ZSHRC_ENABLE_PROFILING:-0})); then
  echo 'zshrc: Enabling high level profiling\n'
  zmodload zsh/zprof
elif ((${ZSHRC_DISABLE_P10K_INSTANT_PROMPT:-0})); then
  echo 'zshrc: P10K instant prompt is disabled'
else
  # Enable Powerlevel10k instant prompt. Should stay close to the top of
  # ~/.zshrc.  Initialization code that may require console input (password
  # prompts, [y/n] confirmations, etc.) must go above this block, everything
  # else may go below.
  if [[ -r "${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi
fi

# If ZSH_RUN_TRACKED is non zero, define maybe-run-tracked as a function that
# calls run-tracked with the provided args. Otherwise, define maybe-run-tracked
# as a function that normally runs the given command, ignore the run-tracked
# options which precede the double dash.
# Example calls to maybe-run-tracked:
# 1. maybe-run-tracked -- printf '%s\n' 1
# 2. maybe-run-tracked -b +f -- printf '%s\n' 2
if ((${ZSH_RUN_TRACKED:-0})); then
  autoload -Uz run-tracked
  maybe-run-tracked() {
    local -a run_tracked_args
    while [[ $# -gt 0 && "$1" != "--" ]]; do
      run_tracked_args+=("$1")
      shift 1
    done
    run-tracked "${run_tracked_args[@]}" "${@:2}"
  }
else
  maybe-run-tracked() {
    # See comment above.
    while [[ $# -gt 0 && "$1" != "--" ]]; do
      shift 1
    done
    "${@:2}"
  }
fi

# We don't always want to use `emulate -L zsh` because it can cause issues if
# code running sets or depend on particular global options. Therefore, we use a
# separate function for this. See also:
# https://github.com/romkatv/powerlevel10k/issues/496
maybe-run-tracked-emulate() {
  emulate -L zsh
  maybe-run-tracked "$@"
}

source_compiled() {
  [[ $# -eq 0 ]] && { source; return $?; }
  local filepath="$1"
  shift 1
  local args=("$@")
  if ((${ZSHRC_DISABLE_ZCOMPILE:-0})); then
    [[ -w "${filepath}.zwc" ]] && rm -- "${filepath}.zwc"
    builtin source -- "${filepath}" "$@"
    return
  fi
  # This function was originally placed in `base.sh` so that I could use it in
  # scripts that work with both bash and zsh. I ended up not using it outside my
  # zsh setup, so I dropped it for now.
  # if is_bash; then
  #   # ${var@Q} gives value of var quoted in a format that can be reused as input
  #   builtin source -- "${filepath}" "${args@Q}"
  #   return $?
  # fi
  # Canonicalize filepath.
  filepath="${filepath:P}"
  # We don't want to clutter the directories of the source files, so we
  # centralize all the compiled files in ${ZSH_CACHE_DIR}/zwc. In addition,
  # putting the zwc in another directory has the advantage of not requiring the
  # source file to be in a writable directory.
  # However, for this to work, we must symlink to the original files in order to
  # use the compiled file. The reason is that I couldn't find a way to source
  # compiled files directly. Zsh will automatically uses the compiled file if
  # it exists in the same directory and has the same name (with the zwc
  # extension).
  # NOTE: no slash needed before ${filepath} because it's a full path.
  local symlink="${ZSH_CACHE_DIR}/zwc${filepath}"
  local symlink_dir="${symlink:h}"
  if [[ ! -d "${symlink_dir}" ]]; then
    mkdir -p -- "${symlink_dir}"
  fi
  if [[ ! -f "${symlink}" ]]; then
    ln --symbolic --relative -- "${filepath}" "${symlink}"
  fi
  # We use zrecompile to figure out which files need recompilation. This is
  # better than comparing the modification time because it also accounts for
  # compiled files that need recompilation because they were compiled in an
  # incompatible zsh version.
  autoload -Uz zrecompile
  # The `-q` option makes zrecompile quiet.
  local zrecompile_options=(-q)
  if [[ ! -f "${symlink}.zwc" ]]; then
    # The `-p` flag ensures that compilation occurs even if there's no existing
    # compiled file yet.
    zrecompile_options+=(-p)
  fi
  zrecompile "{zrecompile_options[@]}" -- "${symlink}"
  # # If there is a compiled filepath newer than the source filepath.
  # if [[ ! ${symlink}.zwc -nt ${filepath} ]]; then
  #   zcompile -R -- "${symlink}"
  # fi
  # shellcheck disable=SC2154
  # ZERO is used to by some zsh plugins to set the path for the main plugin
  # file, which is then used to get the paths of additional files. This is used,
  # for example, by fast-syntax-highlighting.
  ZERO="${filepath}" builtin source -- "${symlink}" "${(q)args[@]}"
}

# See note in .zshenv about sourcing .profile.
emulate sh -c 'source ${ZSHENV_DIR}/../../.profile'
source "${REPO_ROOT}/.my_scripts/lib/base.sh"
source "${REPO_ROOT}/.my_scripts/lib/platform_detection.sh"

################################################################################
#                               General settings                               #
################################################################################
# Print hex/oct numbers as 0xFF/077 instead of 16#FF/8#77.
setopt C_BASES

# The command name to assume if a redirection is specified with no command
# NULLCMD=/dev/null

# Try to correct spelling of commands.
setopt CORRECT
# Try to correct the spelling of all arguments in a line.
# Disabled because it tries to correct arguments of misc commands (g4, tmux,
# etc) to paths and it is usually wrong.
# TODO: Identify and whitelist specific commands for auto correction
# where it will work well.
# setopt CORRECT_ALL

# Print the exit value of programs with non-zero exit status.
# Disabled for now as it adds some clutter.
# setopt PRINT_EXIT_VALUE

# Report the status of background and suspended jobs before exiting a shell with
# job control
setopt CHECK_JOBS
# Don't send the HUP signal to running jobs when the shell exits.
setopt NO_HUP

# Resume when executing the same name command as suspended process name
setopt AUTO_RESUME

# Perform path search even on command names with slashes.
setopt PATH_DIRS

source_compiled "${SHELL_CONFIG_DIR}/settings.sh"

# update_environment_from_tmux is defined in settings.sh.
autoload -Uz add-zsh-hook
add-zsh-hook preexec update_environment_from_tmux

maybe-run-tracked-emulate -- source_compiled \
  "${PLUGINS_DIR}/oh-my-zsh/plugins/command-not-found/"*.plugin.zsh

################################################################################
#                 Bash compatibility and interactive scripting                 #
################################################################################
# Allow comments even in interactive shells.
setopt INTERACTIVE_COMMENTS

# Don't interpret escape sequences in echo unless the -e option is given.
# This is the same behavior as in bash.
setopt BSD_ECHO

# Perform implicit tees or cats when multiple redirections are attempted.
# As of 2020-08-03, this is disabled because I don't use this feature and I have
# concerns it may break something.
# setopt MULTIOS
# If any command in a pipeline failed, set an error code.
setopt PIPE_FAIL
# When this option is not set, the effect of break and continue commands may
# propagate outside function scope.
setopt LOCAL_LOOPS

# Makes regex matching more similar to bash. Useful for sharing code between zsh
# and bash like the persistent history stuff.
# NOTE: As of 2020-03-05, this is disabled because I'm worried it may break zsh
# code. If I will actually use this feature in zsh (which isn't the case right
# now), I can enable it locally to the function that uses it.
# setopt BASH_REMATCH

# Other options to consider setting with identified issues as of 2020-08-03:
# NO_UNSET: breaks p10k.
# POSIX_IDENTIFIERS: breaks p10k.
# KSH_ARRAYS: breaks multiple things.
# POSIX_CD, GLOB_SUBST, KSH_GLOB, POSIX_JOBS, LOCAL_TRAPS, POSIX_ALIASES,
# POSIX_BUILTINS, POSIX_STRINGS, POSIX_TRAPS, SH_FILE_EXPANSION, SH_NULLCMD,
# SH_OPTION_LETTERS, SH_WORD_SPLIT

################################################################################
#                          Files navigation/management                         #
################################################################################
# Do not overwrite existing files with > and >>. Use >! and >>! to bypass.
setopt NO_CLOBBER
# If append redirection (>>) is used on a non-existing file, create it.
# This is the same behavior as in bash.
setopt APPEND_CREATE

# If a command is issued that can’t be executed as a normal command, and the
# command is the name of a directory, perform the cd command to that directory
setopt AUTO_CD
# Make cd push the old directory onto the directory stack.
setopt AUTO_PUSHD
# Push to home directory when no argument is given.
setopt PUSHD_TO_HOME
# Exchanges the meanings of '+' and '-' when used with a number to specify a
# directory in the stack.
setopt PUSHD_MINUS
setopt PUSHD_SILENT
# Do not store duplicates in the stack.
setopt PUSHD_IGNORE_DUPS
# Change directory to a path stored in a variable.
# This was previously turned off since it's currently unused and also enables
# users completion which was very slow at work. See also:
# http://www.zsh.org/mla/users/2006/msg00776.html
setopt CDABLE_VARS

# Make globbing (filename generation) sensitive to case
setopt CASE_GLOB
# Treat the ‘#’, ‘~’ and ‘^’ characters as part of patterns for filename
# generation, etc.
setopt EXTENDED_GLOB
# Enable ** and *** in globbing.
setopt GLOB_STAR_SHORT
# Do not require a leading ‘.’ in a filename to be matched explicitly.
setopt GLOB_DOTS

# Confirm when executing 'rm *'
setopt RM_STAR_WAIT

# If the path is directory, add '/' to path tail when generating path by glob
setopt MARK_DIRS

# An array (colon-separated list) of directories specifying the search path for
# the cd command
# cdpath=(. ${HOME})

# zmv is awesome. You can do "mmv *.cc *.cpp" to rename all .cc files to .cpp.
# Type "zmv" for more info.
autoload -Uz zmv zcp zln

function {
  local XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
  local fasd_cache_dir="${XDG_CACHE_HOME}/fasd"
  mkdir -p -- "${fasd_cache_dir}"
  local fasd_cache="${fasd_cache_dir}/fasd-init-zsh"
  local fasd="$(command -v fasd 2> /dev/null)" || return
  if [[ ! -e "${fasd_cache}" || "${fasd:P}" -nt "${fasd_cache}" ]]; then
    fasd --init zsh-hook zsh-wcomp >| "${fasd_cache}"
  fi
  source "${fasd_cache}"
}

# Persistent recent directories from zshcontrib.
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ':chpwd:*' recent-dirs-max 500
zstyle ':chpwd:*' recent-dirs-default true
zstyle ':chpwd:*' recent-dirs-file "${ZSH_CACHE_DIR}/chpwd-recent-dirs"
zstyle ':chpwd:*' recent-dirs-pushd true

################################################################################
#                                   History                                    #
################################################################################
source_compiled "${SHELL_CONFIG_DIR}/history/history.sh"
HISTFILE="$(get_host_history_dir)/zsh_history"
HISTSIZE=100000000
SAVEHIST=100000000

# Whenever the user enters a line with history expansion, don’t execute the line
# directly; instead, perform history expansion  and  reload  the  line into the
# editing buffer.
setopt HIST_VERIFY
# Perform textual history expansion, csh-style, treating the character ‘!’
# specially.
setopt BANG_HIST

# Save beginning time and runtimes for commands in the history file.
setopt EXTENDED_HISTORY
# Remove superfluous blanks from each command line being added to the history
# list.
# NOTE: As of 2020-02-11, HIST_REDUCE_BLANKS is disabled because it reduces all
# the indentation in multi line commands.
# setopt HIST_REDUCE_BLANKS
# Do not enter command lines into the history list if they are duplicates of the
# previous event.
setopt HIST_IGNORE_DUPS
# Do not add commands to this history if the begin with a space. Useful for
# commands that have sensitive information.
setopt HIST_IGNORE_SPACE
# When writing out the history file, older commands that duplicate newer ones
# are omitted.
setopt HIST_SAVE_NO_DUPS
# Expire duplicate entries first when trimming history.
setopt HIST_EXPIRE_DUPS_FIRST
# Don't show duplicates when searching history.
setopt HIST_FIND_NO_DUPS

# NOTE: INC_APPEND_HISTORY, INC_APPEND_HISTORY_TIME, and SHARE_HISTORY are
# mutually exclusive according to the zsh manual.
# Write to the history file immediately, not when the shell exits.
# setopt INC_APPEND_HISTORY
# Write the command after the command is finished so that execution time is
# recorded as well.
setopt INC_APPEND_HISTORY_TIME
# Share history between all sessions.
# setopt SHARE_HISTORY

_histcat_preexec_hook() {
  emulate -L zsh
  # The first argument in the preexec hook is the command as typed by the user,
  # while the third one has aliases expanded. See also:
  # http://zsh.sourceforge.net/Doc/Release/Functions.html
  local typed_cmd="$1"
  local expanded_cmd="$3"
  # Respect HIST_IGNORE_SPACE: if the expanded command starts with a space,
  # don't add it to the persistent history. Useful for commands that have
  # sensitive information.
  if [[ -o HIST_IGNORE_SPACE &&
      ("${typed_cmd}" == ' '* || "${expanded_cmd}" == ' '*) ]]; then
    return
  fi
  histcat-verify
  histcat add --typed-command "${typed_cmd}" \
    --expanded-command "${expanded_cmd}"
}

autoload -Uz add-zsh-hook
# NOTE: There's also the zshaddhistory hook, but we don't use it because it
# unlike preexec it doesn't forward the actual command that will be executed,
# which we save to our custom history. Additionally, there's no clear advantage
# in using it for our use case, though that may change if we start using `fc` to
# manipulate the history.
add-zsh-hook preexec _histcat_preexec_hook

################################################################################
#                                  Completion                                  #
################################################################################
# zshcompsys man page says to load this module if using menu select.
# This must be done before the call to compinit.
zmodload zsh/complist

setopt AUTO_LIST
setopt AUTO_MENU
# Ask whether to list matches only if the top of the listing would scroll off
# the screen.
LISTMAX=0
# When the completion is ambiguous, show me the menu immediately.
setopt NO_LIST_AMBIGUOUS
# When listing files that are possible completions, show the type of each file
# with a trailing identifying mark.
setopt LIST_TYPES
# When the last character resulting from a completion is a slash and the next
# character typed is a word delimiter, a slash, or a character that ends a
# command (such as a semicolon or an ampersand), remove the slash.
setopt AUTO_REMOVE_SLASH
setopt GLOB_COMPLETE
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
# If completed parameter is a directory, add a trailing slash.
setopt AUTO_PARAM_SLASH
# Enable filename completion for command arguments in the form of `--arg=` after
# the equal sign. Does not override existing argument completion, only used if
# there is no completion defined.
setopt MAGIC_EQUAL_SUBST

function {
  # NOTE: Before 2019-05-21 I didn't use auto selection of the first result, so
  # it if annoys me I can get back to the previous behavior with the commented
  # out code below.
  local AUTOSELECT_FIRST_COMPLETION=1
  # Use menu completion and autoselect the first result.
  if ((AUTOSELECT_FIRST_COMPLETION)); then
    setopt MENU_COMPLETE
    zstyle ':completion:*' menu true select
  # Use menu completion but do NOT autoselect the first result, even when there
  # are multiple options.
  # Instead, list the completions and only if I hit tab a second time select the
  # completion (and iterate over the others).
  else
    setopt NO_MENU_COMPLETE
    zstyle ':completion:*' menu select
  fi
}

function {
  # Smart case: lowercase letters in the input also match uppercase letters in
  # the completion candidates (but not vice versa), and a single dash at the
  # start of the string matches a double dash at the start of the string.
  local smartcase='m:{[:lower:]}={[:upper:]} l:|-=--'
  # Try to complete in the following matching order (stop when there's at least
  # one match):
  # NOTE(infokiller): I used to use the '+' prefix in the every matcher except
  # the first one to make the completion strictly more general, but that caused
  # an issue because it seems that sometimes the smartcase matcher must be at
  # the end. For example, the following matcher lists are not equivalent:
  # - 'm:{[:lower:]}={[:upper:]} r:-||?=*'
  # - 'r:-||?=* m:{[:lower:]}={[:upper:]}'
  # To see their difference, test a completion with the input "ab" and the
  # candidates "A-Ab" and "axb".
  local matcher_list=(
    "${smartcase}"
    # Dashes in the input that are NOT at the start of the string match
    # underscores in the completion candidates, and similarly underscores match
    # dashes.
    'l:?|-=_ l:?|_=- '"${smartcase}"
    # Matches any abbreviation between the delimiters in the square brackets, so
    # for example 'a.b' matches 'acc.bdd', and 'a-b' matches 'acc-bdd'.
    'r:|[.,%$#@/_-]=* r:|=* '"${smartcase}"
    # Like the former, but doesn't require inputting the delimiters explicitly.
    # For example, 'ab' will match 'acc-bdd'.
    # NOTE: This currently matches 'xxx-acc-bdd' as well, i.e. it does not
    # require to provide a prefix for every delimited word.
    'r:[.,%$#@/_-]||?=* '"${smartcase}"
    # Substring match: 'bc' matches 'abcd'.
    'l:|=*' "${smartcase}"
    # Fuzzy completion: 'abc' matches 'axbxcx'.
    'r:?||?=** '"${smartcase}"
    # Ignore case: match uppercase letters and underscores in the input to
    # lowercase letters and hyphens in the completion candidates.
    '+m:{[:upper:]}={[:lower:]} m:{_\-}={\-_}'
  )
  zstyle ':completion:*' matcher-list "${matcher_list[@]}"
}

# Fuzzy match mistyped completions.
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*:*:*' original only
# zstyle ':completion:*:approximate:*' max-errors 1 numeric
# Allow up to N/3 errors for a completion query of length N, with a max of 5.
zstyle -e ':completion:*:approximate:*:*:*' max-errors \
  'reply=($((($#PREFIX+$#SUFFIX)/3 < 5 ? ($#PREFIX+$#SUFFIX)/3 : 5))numeric)'
# Use a cache for faster completion
zstyle ':completion:*' use-cache true
zstyle ':completion:*' cache-path "${ZSH_CACHE_DIR}"
zstyle ':completion:*' single-ignored menu

# Group and describe matches.
zstyle ':completion:*:matches' group true
zstyle ':completion:*:options' description true
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose true

# Rehash before matching external commands to pick up new/removed commands.
zstyle ':completion:*' rehash true

# Files and directories
function {
  # Try to complete non-hidden files/dirs first, but if there are no matches try
  # completing hidden files as well.
  # NOTE: the general form is disabled because it unconditionally overrides the
  # behavior of the `_files` completer, causing it to ignore the patterns given to
  # it from completion functions. For example, it makes unzip and zathura complete
  # any file (instead of only completing zip files and pdf files respectively).
  # Therefore, I define it only for specific commands.
  # zstyle ':completion:*' file-patterns '[^.]*:non-hidden-files' '.*:hidden-files'
  local generic_file_completers=(ls exa cd-ranger cd-fasd-fzf ranger dirsize 
    vim-less swap-files)
  local generic_file_completers_context="$(printf ':completion:*:*:%s:*' \
    "("$(join_by '|' "${generic_file_completers[@]}")")")"
  zstyle "${generic_file_completers_context}" file-patterns \
    '[^.]*:non-hidden-files' '.*:hidden-files'

  zstyle ':completion:*:*:cd:*' \
    tag-order local-directories directory-stack path-directories
  zstyle ':completion:*:-tilde-:*' group-order \
    'named-directories' 'path-directories' 'users' 'expand'
  zstyle ':completion:*' squeeze-slashes true
  zstyle ':completion:*' ignore-parents parent pwd
  # Completion settings for the `cdr` function from zshcontrib.
  zstyle ':completion:*' recent-dirs-insert both

  # Video & audio
  local video_exts=(mkv avi mp4 m4p m4v mpg mpeg mov wmv qt giv gifv 3gp 3gpp
    3gpp2 ogg ogv vnd webm)
  local video_patterns="$(printf '(.|)*.{%s}' $(join_by , "${video_exts[@]}"))"
  zstyle ':completion:*:complete:(vlc|mpv):*' file-patterns \
    "${video_patterns}"':videos *(-/):directories'
  zstyle ':completion:*:*:mpg123:*' file-patterns \
    '(.|)*.(mp3|MP3):mp3-files *(-/):directories'
  zstyle ':completion:*:*:mpg321:*' file-patterns \
    '(.|)*.(mp3|MP3):mp3-files *(-/):directories'
  zstyle ':completion:*:*:ogg123:*' file-patterns \
    '(.|)*.(ogg|OGG|flac):ogg-files *(-/):directories'
  zstyle ':completion:*:*:mocp:*' file-patterns \
    '(.|)*.(wav|WAV|mp3|MP3|ogg|OGG|flac):ogg-files *(-/):directories'
  # Images
  zstyle ':completion::complete:(geeqie|pqiv|pinta|gimp):*' file-patterns \
    '(.|)*.{gif,png,jpeg,jpg,svg,bmp,tiff,tif}:images *(-/):directories'
}

# Don't complete commands starting with an underscore.
# zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

# Array completion element sorting.
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# History
zstyle ':completion:*:history-words' stop true
zstyle ':completion:*:history-words' remove-all-dups true
zstyle ':completion:*:history-words' list false

# Environment variables
zstyle ':completion::*:(-command-|export):*' fake-parameters \
  ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}

# Populate hostname completion.
# NOTE: I disabled completions from /etc/hosts since it contains a large number
# of hosts that are blocked because they serve ads. See git log for how to
# revert this change.
zstyle -e ':completion:*:hosts' hosts 'reply=(
  ${=${=${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
  ${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'

# Don't complete uninteresting users.
zstyle ':completion:*:users' ignored-patterns \
  adm amanda apache avahi beaglidx bin brltty cacti canna clamav colord cups \
  daemon dbus dhcpcd distcache dnsmasq dnscrypt-proxy dovecot earlyoom fax \
  flatpak ftp games geoclue gdm git gitlab-runner gkrellmd gluster gopher \
  hacluster haldaemon halt hsqldb http ident junkbust keydope ldap lightdm lp \
  mail mailman mailnull miniflux mldonkey mysql nagios named netdump news \
  nfsnobody nm-openconnect nobody nscd nvidia-persistenced ntp nut nx openvpn \
  operator pcap polkitd postfix postgres privoxy pulse pvm quagga radvd rpc \
  rpcuser rpm rtkit shutdown squid sshd sync 'systemd-*' tor transmission tss \
  usbmux uucp uuidd vcsa xfs '_*'

# Don't complete words that are already on the line for these commands.
zstyle ':completion:*:(rm|trash-put|kill|diff):*' ignore-line other
# zstyle ':completion:*:(rm|trash-put):*' file-patterns '*:all-files'

zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single

zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# SSH/SCP/rsync
zstyle ':completion:*:(ssh|scp|rsync):*' tag-order \
  'hosts:-host:host hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' \
  group-order files all-files hosts-domain hosts-host
zstyle ':completion:*:ssh:*' group-order hosts-host
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns \
  '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns \
  '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns \
  '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' \
  '255.255.255.255' '::1' 'fe80::*'

# Git
zstyle ':completion:*:git-*:argument-rest:heads'        ignored-patterns '(FETCH_|ORIG_|)HEAD'
zstyle ':completion:*:git-*:argument-rest:heads-local'  ignored-patterns '(FETCH_|ORIG_|)HEAD'
zstyle ':completion:*:git-*:argument-rest:heads-remote' ignored-patterns '*/HEAD'

function {
  local dephell
  dephell="$(command -v dephell 2> /dev/null)" || return
  dephell_comp_file="${XDG_DATA_HOME}/dephell/_dephell_zsh_autocomplete"
  if [[ ! -e "${dephell_comp_file}" ||
    "${dephell:P}" -nt "${dephell_comp_file}" ]]; then
    # dephell will fail because it can't find zshrc, but that's fine.
    dephell self autocomplete 2> /dev/null || true
  fi
}

# Add completions from plugins. Completions from dotfiles repo are already added
# by now.
fpath=(
  "${ZDOTDIR}/fpath"
  ${fpath}
  # z4h functions
  "${PLUGINS_DIR}/zsh4humans/fn"
  # Completions from external repos
  "${PLUGINS_DIR}/conda-zsh-completion"
  "${PLUGINS_DIR}/go-zsh-completion/src"
  "${PLUGINS_DIR}/zsh-completions/src"
  # Update 2018-12-07: looks like it's already included in zsh 5.6.2, keeping
  # it in case old systems need it.
  "${PLUGINS_DIR}/oh-my-zsh/plugins/cargo"
)

if command_exists nix; then
  fpath=(
    ${fpath}
    "${PLUGINS_DIR}/nix-zsh-completions"
  )
fi

# Run `compinit`. It should be run:
# - After all dirs with completion files were added to `fpath`
# - After loading `zsh/complist`
# - After defining all completion widgets
# - Before any `compdef` function calls
#
# The code below is used to speed up `compinit`. See:
# https://gist.github.com/ctechols/ca1035271ad134841284
function {
  emulate -L zsh -o extendedglob
  autoload -Uz compinit zrecompile
  local zcompdump="${ZSH_CACHE_DIR}/zcompdump-${ZSH_VERSION}"
  # Globbing params:
  # - `#q` is an explicit glob qualifier that makes globbing work within zsh's
  #   [[ ]] construct.
  # - `N` makes the glob pattern evaluate to nothing when it doesn't match
  #   (rather than throw a globbing error).
  # - 'mh+6' matches files (or directories or whatever) that are older than 6
  #   hours.
  if [[ -n "${ZSHRC_REFRESH_COMP-}" || -n ${zcompdump}(#qNmh+6) ]]; then
    compinit -i -d "${zcompdump}"
    # compinit is reported to not update the timestamp if zcompdump wasn't
    # changed, so we do it manually.
    touch "${zcompdump}"
    # Recompile zcompdump in the background, since it doesn't affect the
    # current session (we already ran `compinit`).
    # `-q` makes zrecompile quiet.
    # `-p` ensures that compilation occurs even if there's no existing
    # compiled file yet.
    zrecompile -q -p -- "${zcompdump}" &!
  else
    compinit -C -d "${zcompdump}"
  fi
}

# Understand completions written for bash.
autoload -Uz bashcompinit && bashcompinit
source_compiled "${SHELL_CONFIG_DIR}/completion.sh"

function {
  # Newer versions of zsh already come with npm completions.
  if command_exists _npm; then
    return
  fi
  local npm="$(command -v npm 2> /dev/null)" || return
  # `npm completion` outputs bash code for completion that needs to be executed
  # directly, not added to the fpath. We cache this call since it's slow.
  local _npm_comp_file="${ZSH_CACHE_DIR}/npm_completion"
  if [[ ! -e "${_npm_comp_file}" || "${npm:P}" -nt "${_npm_comp_file}" ]]; then
    npm completion >| "${_npm_comp_file}"
  fi
  maybe-run-tracked-emulate -- source_compiled "${_npm_comp_file}"
}

_fzf_complete_vim() {
  # To return only text files I can use the following command:
  # find . -type f -exec grep -Iq . {} \; -and -print
  # However it's much slower than just returning every file without checking, so
  # I'm going with the speed now.
  list-searched-files | _fzf_complete --multi "$@"
}
_fzf_complete_v() { _fzf_complete_vim "$@" }
_fzf_complete_e() { _fzf_complete_vim "$@" }

_fzf_complete_cd() {
  find -L '!' -readable -prune -o -type d -print 2> /dev/null |
    _fzf_complete --multi "$@"
}
_fzf_complete_cd-fasd-fzf() { _fzf_complete_cd "$@" }
_fzf_complete_c()           { _fzf_complete_cd "$@" }
_fzf_complete_cd-ranger()   { _fzf_complete_cd "$@" }

_fzf_complete_git() {
  git-list-files 2> /dev/null | _fzf_complete --multi "$@"
}
_fzf_complete_g()     { _fzf_complete_git "$@" }
_fzf_complete_gf()    { _fzf_complete_git "$@" }
_fzf_complete_gfr()   { _fzf_complete_git "$@" }
_fzf_complete_gd()    { _fzf_complete_git "$@" }
_fzf_complete_gfd()   { _fzf_complete_git "$@" }
_fzf_complete_gfrd()  { _fzf_complete_git "$@" }
_fzf_complete_gdt()   { _fzf_complete_git "$@" }
_fzf_complete_gfdt()  { _fzf_complete_git "$@" }
_fzf_complete_gfrdt() { _fzf_complete_git "$@" }
_fzf_complete_gl()    { _fzf_complete_git "$@" }
_fzf_complete_gfl()   { _fzf_complete_git "$@" }
_fzf_complete_gfrl()  { _fzf_complete_git "$@" }
_fzf_complete_gla()   { _fzf_complete_git "$@" }
_fzf_complete_gfla()  { _fzf_complete_git "$@" }
_fzf_complete_gfrla() { _fzf_complete_git "$@" }
_fzf_complete_glp()   { _fzf_complete_git "$@" }
_fzf_complete_gflp()  { _fzf_complete_git "$@" }
_fzf_complete_gfrlp() { _fzf_complete_git "$@" }
_fzf_complete_gls()   { _fzf_complete_git "$@" }
_fzf_complete_gfls()  { _fzf_complete_git "$@" }
_fzf_complete_gfrls() { _fzf_complete_git "$@" }

_fzf_complete_ga()    {
  git ls-files --modified 2> /dev/null | _fzf_complete --multi "$@"
}
_fzf_complete_gfa()   { _fzf_complete_ga "$@" }
_fzf_complete_gfra()  { _fzf_complete_ga "$@" }
_fzf_complete_gap()   { _fzf_complete_ga "$@" }
_fzf_complete_gfap()  { _fzf_complete_ga "$@" }
_fzf_complete_gfrap() { _fzf_complete_ga "$@" }

FZF_COMPLETION_TRIGGER='jk'
fzf_default_completion='complete-word'
# This plugin rebinds tab to use fzf completion if the completion trigger is
# found, and otherwise fall back to ${fzf_default_completion} which defaults to
# expand-or-complete.
# +b means not to print warnings when rebinding keys.
maybe-run-tracked-emulate +b -- source_compiled \
  "${SUBMODULES_DIR}/terminal/fzf/shell/completion.zsh"

# NOTE: As of 2018-12-29, the pip zsh completion doesn't work so I'm using the
# bash completion (see below).
# The following pip completion was generated using:
# pip completion --zsh
#
# # pip zsh completion start
# function _pip_completion {
#   local words cword
#   read -Ac words
#   read -cn cword
#   reply=( $( COMP_WORDS="${words}[*]" \
#              COMP_CWORD=$(( cword-1 )) \
#              PIP_AUTO_COMPLETE=1 ${words}[1] ) )
# }
# compctl -K _pip_completion pip
# # pip zsh completion end

# The following pip completion was generated using:
# pip completion --bash
# pip bash completion start
_pip_completion()
{
    COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \
                   COMP_CWORD=${COMP_CWORD} \
                   PIP_AUTO_COMPLETE=1 $1 ) )
}
complete -o default -F _pip_completion pip
# pip bash completion end

# Depends on compdef, so must be sourced after compinit was called.
maybe-run-tracked-emulate -- source_compiled \
  "${SUBMODULES_DIR}/lastpass-cli/contrib/lpass_bash_completion"
# Depends on compdef, so must be sourced after compinit was called.
# NOTE: This slows down shell initialization considerably and I'm not really
# using it anyway, so disabling it.
# if command_exists pipenv; then
#   eval "$(pipenv --completion)"
# fi

# Completions for the new nix shell based on bash and slightly modified from:
# https://github.com/spwhitt/nix-zsh-completions/issues/32#issuecomment-705315356
# https://github.com/NixOS/nix/blob/master/misc/zsh/completion.zsh
# TODO: Make this work in a separate file in fpath.
_nix() {
  emulate -L zsh
  local ifs_bk="$IFS"
  local input=("${(Q)words[@]}")
  local IFS=$'\n\t'
  local res=($(NIX_GET_COMPLETIONS=$((CURRENT - 1)) "$input[@]"))
  IFS="$ifs_bk"
  local tpe="${${res[1]}%%>	*}"
  local -a suggestions
  declare -a suggestions
  for suggestion in ${res:1}; do
    # FIXME: This doesn't work properly if the suggestion word contains a `:`
    # itself
    suggestions+="${suggestion/	/:}"
  done
  if [[ "$tpe" == filenames ]]; then
    compadd -f
  fi
  _describe 'nix' suggestions
}
compdef _nix nix

# Set completion for commands and functions
function {
  # On hera17 it seems that these definitions must be after the compinit call,
  # otherwise zsh complains that `rg` is not defined.
  _set_same_completion() {
    # If the command doesn't exist compdef will print an error.
    command_exists "$1" && compdef "$2=$1"
  }
  local cmd
  for cmd in rgc rgcc rgcl rgl rgc-todos rgcl-todos tag; do
    _set_same_completion rg "${cmd}"
  done
  # _set_same_completion ssh ssh-et-tmxcs
  _set_same_completion git git-https
  _set_same_completion xargs sensible-xargs
  if [[ "${DISTRO}" == arch ]]; then
    _set_same_completion pacman pacnanny
    _set_same_completion pacman sensible-pacman
  fi
  _set_same_completion ssh ssh-et
  _set_same_completion ssh-et ssh-et-tmxcs
  _set_same_completion ssh-et ssh-et-tmxns
  _set_same_completion du duh
  _set_same_completion conda mamba
  _set_same_completion conda conda-or-mamba
}

# NOTE(2018-11-09): Disabled because it's unused.
# zplug "zsh-users/zaw"

################################################################################
#                              Line editor utils                               #
################################################################################
_bindkey_insert_keymaps() {
  bindkey -M emacs "$@"
  bindkey -M viins "$@"
}

_bindkey_vi_keymaps() {
  bindkey -M viins "$@"
  bindkey -M vicmd "$@"
  # Should this be enabled too?
  # bindkey -M viopp "$@"
  bindkey -M visual "$@"
}

_bindkey_all_keymaps() {
  bindkey -M emacs "$@"
  _bindkey_vi_keymaps "$@"
}

_is_key_bound() {
  [[ "$(bindkey "$1")" != *undefined-key* ]]
}

################################################################################
#                         Line editor general settings                         #
################################################################################
# Chars that define a word boundary for the line editor. Used by the following
# widgets: backward-word, forward-word, backward-delete-word,
# forward-delete-word. Not used by the vi variants (vi-backward-word etc.).
# WORDCHARS='*?+_-.[]~=;!#$%^(){}<>:@,\\'
WORDCHARS='*?+_-.~=!#$%^@\\'
# WORDCHARS='?+_-.~=!@#$%^&*\\|'
# Disable exiting with EOF (Ctrl+d).
setopt IGNOREEOF

# Set the default line editing command early so that it won't override
# keybindings defined later.
bindkey -v
# bindkey -e

# As of zsh 5.1, bracketed paste should work out of the box.
# source "${PLUGINS_DIR}/oh-my-zsh/plugins/safe-paste/"*.plugin.zsh
# /usr/share/zsh/functions/Zle/bracketed-paste-magic
# autoload -Uz bracketed-paste-magic
# zle -N bracketed-paste bracketed-paste-magic

# Disable the default keybindings of zsh-system-clipboard, we'll rebind only
# what we need. The default keybindings copy every deletion (including for a
# single char) to the system clipboard, which I find annoying.
# NOTE: As of 2020-02-06, zsh-system-clipboard is not used so it's disabled. I
# wanted to use it in order to define delete commands that are copied to the
# system clipboard (similar to the M command I have set up in vim), but didn't
# have time to do it yet.
# export ZSH_SYSTEM_CLIPBOARD_DISABLE_DEFAULT_MAPS=1
# maybe-run-tracked-emulate -- source \
#   "${PLUGINS_DIR}/zsh-system-clipboard/"*.plugin.zsh

# NOTE: The 5th feature mentioned in the zsh-autopair README[1] needs to rebind
# the space character, but that conflicts with the zsh-abbrev-alias plugin.
# Therefore, I'm reverting the space rebinding.
# [1] https://github.com/hlissner/zsh-autopair#zsh-autopair
AUTOPAIR_INHIBIT_INIT=1
maybe-run-tracked-emulate -- source_compiled "${PLUGINS_DIR}/zsh-autopair/"*.plugin.zsh
unset 'AUTOPAIR_PAIRS[ ]'
# +b means not to print warnings when rebinding keys.
maybe-run-tracked-emulate +b -- autopair-init

# source_compiled "${PLUGINS_DIR}/zsh-directory-history/"*.plugin.zsh

# Should be loaded last.
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=1
# I originally used fg=10 but this make the autosuggestion color identical to
# comments, while this one is slightly different.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=fg=242
# Copied from: https://github.com/romkatv/zsh4humans/blob/ed3ac2b25829865ca702ba088df06f59062e15f9/.zshrc#L274
# Disable a very slow obscure feature
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
maybe-run-tracked-emulate -- \
  source_compiled "${PLUGINS_DIR}/zsh-autosuggestions/"*.plugin.zsh

# +b means we allow this plugin to bind keys.
maybe-run-tracked-emulate +b -- \
  source_compiled "${SUBMODULES_DIR}/terminal/fzf/shell/key-bindings.zsh"
# Redefine the widget function fzf-history-widget to use my persistent history.
# Original function is at:
# https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh
fzf-history-widget() {
  emulate -L zsh
  local selected
  # NOTE: I replaced the expression "${(qqq)LBUFFER}" with "${LBUFFER//$/\\$}"
  # because otherwise I got two quotation marks in the initial query.
  # selected=$(conda-run shell_history \
  #     "$HOME/.config/bash/history/shell_history_choose_line.py" \
  #     --initial-query "${LBUFFER//$/\\$}")
  # selected="$(histcat select --initial-query "${LBUFFER//$/\\$}")"
  selected="$(histcat-select --query="${LBUFFER//$/\\$}")"
  local ret=$?
  if [[ -n $selected ]]; then
    LBUFFER="$selected"
    # RBUFFER=""
  fi
  zle reset-prompt
  return $ret
}
zle -N fzf-history-widget
_bindkey_all_keymaps '^R' fzf-history-widget

# Undo/Redo with Alt+Shift+{_,+} in all modes.
_bindkey_all_keymaps '^[_' undo
_bindkey_all_keymaps '^[+' redo
# Make CTRL-U kill to the beginning of the line (like bash), rather than the
# whole line.
_bindkey_all_keymaps '^U' backward-kill-line
# Cycle quoting on the current word with ALT-'.
autoload -Uz cycle-quotes  # in .zsh/functions/
zle -N cycle-quotes
_bindkey_all_keymaps "^['" cycle-quotes
# C-x C-e to edit command-line in EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
_bindkey_all_keymaps '\C-x\C-e' edit-command-line
# Save current command line, type another command then get back to the saved
# command line.
_bindkey_all_keymaps '^[s' push-line-or-edit
# For compatibility with bash.
_bindkey_all_keymaps '^[#' push-line-or-edit

if command_exists fzf-completion; then
  _default_completion=fzf-completion
else
  >&2 print -Pr -- '%F{yellow}fzf completions not available%f'
  _default_completion=complete-word
fi

# When tab-completing, show dots. For fast tab completes, they will be
# overwritten instantly, for long tab-completions, you have feedback.
# I originally used the smam/rmam terminfo commands from [1] (used to be copied
# from [2] and [3]), but they're not supported in tmux [4] and it seems that
# zsh4humans switched to a new method [5] which I'm now using.
# [1] https://github.com/romkatv/zsh4humans/blob/ed3ac2b25829865ca702ba088df06f59062e15f9/.zshrc#L199-L207
# [2] https://github.com/romkatv/dotfiles-public/blob/6e57a9fe4c47061bdf51704005810e3b633f6fe9/dotfiles/bindings.zsh#L76
# [3] http://code.stapelberg.de/git/configfiles/tree/zshrc
# [4] https://github.com/tmux/tmux/issues/969
# [5] https://github.com/romkatv/zsh4humans/blob/v5/fn/-z4h-show-dots
_complete_with_dots() {
  # NOTE: no "emulate -L zsh" because otherwise my custom completion settings
  # won't work.
  # zmodload zsh/terminfo
  # if (( $+terminfo[rmam] && $+terminfo[smam] )); then
  #   echoti rmam
  #   print -Pn "%B%F{white}...%f%b"
  #   echoti smam
  # fi
  -z4h-cursor-hide() {}
  autoload -Uz -- -z4h-show-dots
  -z4h-show-dots "${LBUFFER}"
  zle "${_default_completion}"
  zle redisplay
}
zle -N _complete_with_dots
_bindkey_insert_keymaps '\t' _complete_with_dots

# General file completion.
_bindkey_all_keymaps '^F' fzf-file-widget

# NOTE: As of 2019-11-04, I don't think I actually need this, but I'm keeping it
# just in case. Will remove it after a few months.
# is_valid_aliases_cmd() {
#   [ $# -eq 1 ] || return 1
#   local cmd="$1"
#   unset 'functions[__expand_aliases_tmp]'
#   local err
#   err=$(functions[__expand_aliases_tmp]="${cmd}" 2>&1 >> /dev/null)
#   \grep -q '[a-zA-Z]' <<< "${err}" && return 2
#   return 0
# }

# See https://unix.stackexchange.com/q/150649/126543
_expand_command_aliases() {
  cmd="$1"
  functions[__expand_aliases_tmp]="${cmd}"
  print -rn -- "${functions[__expand_aliases_tmp]#$'\t'}"
  unset 'functions[__expand_aliases_tmp]'
}

_expand_aliases_widget() {
  local expanded_cmd
  expanded_cmd=$(_expand_command_aliases "${BUFFER}")
  if [[ $? -eq 0 ]]; then
    BUFFER="${expanded_cmd}"
    CURSOR=$#BUFFER
  fi
}
zle -N _expand_aliases_widget
_bindkey_all_keymaps '^[^E' _expand_aliases_widget

# Make sure that the terminal is in application mode when zle is active, since
# only then values from $terminfo are valid. Based on:
# [1] https://github.com/romkatv/dotfiles-public/blob/393aa0bcb6524f4de060610f66485a40ee3435d1/dotfiles/bindings.zsh#L95
# [2] https://github.com/robbyrussell/oh-my-zsh/blob/486fa1010df847bfd8823b4492623afc7c935709/lib/key-bindings.zsh#L5
# NOTE: As of 2020-03-05, this is disabled in favor of directly using terminal
# escape codes that are valid in both modes. See also:
# https://github.com/romkatv/zsh4humans/issues/7
# function {
#   zmodload zsh/terminfo
#   if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
#     function enable-term-application-mode() { emulate -L zsh; echoti smkx }
#     function disable-term-application-mode() { emulate -L zsh; echoti rmkx }
#     #   This seems more robust than the code below but causes infinite recursion
#     #   in my setup.
#     #   autoload -Uz add-zle-hook-widget
#     #   zle -N enable-term-application-mode
#     #   zle -N disable-term-application-mode
#     #   add-zle-hook-widget line-init enable-term-application-mode
#     #   add-zle-hook-widget line-finish disable-term-application-mode
#     zle -N zle-line-init enable-term-application-mode
#     zle -N zle-line-finish disable-term-application-mode
#   fi
# }

# Set terminal specific bindings
function {
  declare -A term_keys
  # zmodload zsh/terminfo
  # NOTE: As of 2020-03-05, I'm using terminal escape codes directly instead of
  # using terminfo, since terminfo entries are only valid in application mode.
  # See also: https://github.com/romkatv/zsh4humans/issues/7
  # See https://github.com/romkatv/zsh4humans/issues/7
  # backspace is hardcoded to "^?" because that's what works in all the terminal
  # emulators that I tested (termite, kitty, urxvt), while terminfo[kbs] is set
  # to '^H'.
  # term_keys[backspace]="${terminfo[kbs]}"
  # term_keys[home]="${terminfo[khome]}"
  # term_keys[end]="${terminfo[kend]}"
  # The default escape sequences used are for xterm, and we override them for
  # specific terminals below.
  term_keys[backspace]='^?'
  term_keys[delete]='^[[3~'
  term_keys[up]='^[[A'
  term_keys[down]='^[[B'
  term_keys[left]='^[[D'
  term_keys[right]='^[[C'
  term_keys[home]='^[[H'
  term_keys[end]='^[[F'
  term_keys[ctrl_delete]='^[[3;5~'
  term_keys[ctrl_backspace]='^H'
  term_keys[shift_tab]='^[[Z'
  # These values worked in kitty, termite, terminator, xterm, and alacrity,
  # inside and outside of tmux, and in both application and normal modes (for
  # xterm-like terminals).
  term_keys[ctrl_right]='^[[1;5C'
  term_keys[ctrl_left]='^[[1;5D'
  term_keys[pageup]='^[[5~'
  term_keys[pagedown]='^[[6~'
  if [[ ${TERM} == xterm-kitty ]]; then
    :
  elif [[ ${TERM} == (screen|tmux)* || ${TERM} == linux ]]; then
    term_keys[home]='^[[1~'
    term_keys[end]='^[[4~'
  elif [[ ${TERM} == rxvt* ]]; then
    term_keys[home]='^[[7~'
    term_keys[end]='^[[8~'
    term_keys[ctrl_delete]='^[[3^'
    term_keys[ctrl_right]='^[Oc'
    term_keys[ctrl_left]='^[Od'
  fi

  # Translate the escape code generated in my keyboard layout from
  # CapsLock+Alt+d (for Ctrl+Delete) to Ctrl+Delete.
  if [[ ${TERM} == (screen|tmux)* || ${TERM} == xterm-kitty ]]; then
    _bindkey_all_keymaps -s '^[[3;3~' "${term_keys[ctrl_delete]}"
  elif [[ ${TERM} == xterm-termite ]]; then
    _bindkey_all_keymaps -s '^[[3;7~' "${term_keys[ctrl_delete]}"
  fi

  # If NumLock is off, translate keys to make them appear the same as with NumLock on.
  bindkey -s '^[OM' '^M'  # enter
  bindkey -s '^[Ok' '+'
  bindkey -s '^[Om' '-'
  bindkey -s '^[Oj' '*'
  bindkey -s '^[Oo' '/'
  bindkey -s '^[OX' '='

  # Translate escape codes in xterm's application mode (smkx) to the escape
  # code in raw mode (rmkx). This way, if an xterm-like terminal is switched
  # to application mode, the keybindings will keep working.
  # NOTE: I used to only define these when $TERM is xterm* but it is also needed
  # when SSHing to DGX machines.
  bindkey -s '^[OA' '^[[A'  # up
  bindkey -s '^[OB' '^[[B'  # down
  bindkey -s '^[OD' '^[[D'  # left
  bindkey -s '^[OC' '^[[C'  # right
  bindkey -s '^[OH' '^[[H'  # home
  bindkey -s '^[OF' '^[[F'  # end

  (( ${+term_keys[backspace]} )) &&
      _bindkey_insert_keymaps "${term_keys[backspace]}" backward-delete-char-or-up-line
  (( ${+term_keys[delete]} )) &&
      _bindkey_insert_keymaps "${term_keys[delete]}" delete-char
  # NOTE: The zsh-history-substring-search plugin is loaded near the end of the
  # zshrc file since it must be loaded after zsh-syntax-highlighting, which is
  # only loaded later.
  # NOTE: We need to define these widgets, which we initially set to the zsh
  # builtin history widgets, since the fast-syntax-highlighting widget tries to
  # rebind all widgets, and if we don't define them it will complain about an
  # incomplete widget being discovered.
  zle -N history-substring-search-up up-line-or-search
  zle -N history-substring-search-down down-line-or-search
  # Up/down will use the entered text as a substring constraint.
  (( ${+term_keys[up]} )) &&
      _bindkey_all_keymaps "${term_keys[up]}" history-substring-search-up
  (( ${+term_keys[down]} )) &&
      _bindkey_all_keymaps "${term_keys[down]}" history-substring-search-down
  (( ${+term_keys[home]} )) &&
      _bindkey_all_keymaps "${term_keys[home]}" beginning-of-line
  (( ${+term_keys[end]} )) &&
      _bindkey_all_keymaps "${term_keys[end]}" end-of-line
  (( ${+term_keys[ctrl_delete]} )) &&
      _bindkey_all_keymaps "${term_keys[ctrl_delete]}" delete-word
  (( ${+term_keys[ctrl_backspace]} )) &&
      _bindkey_all_keymaps "${term_keys[ctrl_backspace]}" backward-delete-word
  (( ${+term_keys[shift_tab]} )) &&
      _bindkey_insert_keymaps "${term_keys[shift_tab]}" reverse-menu-complete
  (( ${+term_keys[ctrl_left]} )) &&
      _bindkey_all_keymaps ${term_keys[ctrl_left]} backward-word
  (( ${+term_keys[ctrl_right]} )) &&
      _bindkey_all_keymaps ${term_keys[ctrl_right]} forward-word
  # Do nothing on pageup and pagedown. Better than printing '~'.
  (( ${+term_keys[pageup]} )) &&
      _bindkey_all_keymaps -s "${term_keys[pageup]}" ''
  (( ${+term_keys[pagedown]} )) &&
      _bindkey_all_keymaps -s "${term_keys[pagedown]}" ''
}

# Copied from https://github.com/dp12/dotfiles/blob/master/zsh/.zshrc#L135
# Make Ctrl-Z toggle between the shell and the last process.
_ctrl_z_widget () {
  if [[ -n "${PREBUFFER}${BUFFER}" ]]; then
    zle push-input
    zle clear-screen
  else
    BUFFER='fg'
    zle accept-line
  fi
}
zle -N _ctrl_z_widget
_bindkey_all_keymaps '^Z' _ctrl_z_widget

_DO_ENTER_CMD=(ll)
_newline_widget() {
  if [[ -z "${PREBUFFER}${BUFFER}" ]]; then
    BUFFER="${_DO_ENTER_CMD[@]}"
  fi
  zle accept-line
}
zle -N _newline_widget
_bindkey_all_keymaps '^M' _newline_widget

_copy_buffer_to_clipboard() {
 print -rn -- "${PREBUFFER}${BUFFER}" | xsel --input --clipboard
 [ -n "${TMUX}" ] && tmux display-message 'Line copied to clipboard!'
}
zle -N _copy_buffer_to_clipboard

# Unbound C-Q which is bound by default and will collide with the copy to
# clipboard binding.
_is_key_bound '^Q' && bindkey -r '^Q'
_bindkey_all_keymaps '^Qy' _copy_buffer_to_clipboard

# Tracks the argument position for the other widgets below.
typeset -g _insert_last_word_offset=-1
_reset_insert_last_word_offset() {
  _insert_last_word_offset=-1
}
add-zsh-hook precmd _reset_insert_last_word_offset

_bindkey_all_keymaps '^[.' insert-last-word

# The reverse of _insert-last-word-widget: puts back the last word from
# the previous line. Useful if I invoke insert-last-word too many times
# accidentally and miss the argument I was targeting.
_insert-last-word-reverse-widget() {
  emulate -L zsh
  zle insert-last-word -- +1 "${_insert_last_word_offset}"
}
zle -N _insert-last-word-reverse-widget
_bindkey_all_keymaps '^[>' _insert-last-word-reverse-widget

_insert-left-hist-word-widget() {
  emulate -L zsh
  ((_insert_last_word_offset -= 1))
  zle insert-last-word -- 0 "${_insert_last_word_offset}"
}
zle -N _insert-left-hist-word-widget
_bindkey_all_keymaps '^[,' _insert-left-hist-word-widget

_insert-right-hist-word-widget() {
  emulate -L zsh
  ((_insert_last_word_offset += 1))
  zle insert-last-word -- 0 "${_insert_last_word_offset}"
}
zle -N _insert-right-hist-word-widget
_bindkey_all_keymaps '^[/' _insert-right-hist-word-widget


# NOTE: After implementing this function, I discovered zsh has a function
# `split-shell-arguments` which can be used for similar purposes, but also
# respects true shell arguments (so spaces inside of quotes are considered part
# of a word).
# Examples for the line editing state and expected selected word , where "$"
# marks the end of BUFFER:
#
# BUFFER |$
# CURSOR |0
# Word   |""
#
# BUFFER |a$
# CURSOR |0
# Word   |"a"
#
# BUFFER |a$
# CURSOR | 1
# Word   |"a"
#
# BUFFER |ab$
# CURSOR | 1
# Word   |"ab"
#
# BUFFER |a $
# CURSOR |  2
# Word   |""
#
# BUFFER |a b  c$
# CURSOR |    4
# Word   |""
_get_zle_cursor_word_bounds() {
  emulate -L zsh
  local b=${CURSOR}
  local e=${CURSOR}
  # >&2 echo
  # >&2 echo "CURSOR=$CURSOR, #BUFFER=$#BUFFER, BUFFER[CURSOR]=${BUFFER:${CURSOR}:1}, b=$b, BUFFER[b]=${BUFFER:${b}:1}" | cat -A
  while ((b > 0)) && [[ "${BUFFER:$((b-1)):1}" =~ [a-zA-Z_-] ]]; do
    ((b -= 1))
  done
  while ((e < $#BUFFER)) && [[ "${BUFFER:$((e)):1}" =~ [a-zA-Z_-] ]]; do
    ((e += 1))
  done
  # >&2 echo "b=$b, e=$e, word=${BUFFER:${b}:$((e-b))}" | cat -A
  echo "${b} ${e}"
}

_replace_arg_with_selected_command() {
  local selected
  if selected="$(select-command --query="$1")" && [[ -n "${selected}" ]]; then
    REPLY="${selected}"
    return 0
  fi
  return 1
}

# I tried implemnting _select_command_widget using modify-current-argument, but
# it doesn't work well as is because it always tries to match an argument, even
# if the cursor is not on it, in which case I actually don't want to modify it,
# but instead insert a new word.
# autoload -Uz modify-current-argument
# zle -N modify-current-argument
_select_command_widget() {
  emulate -L zsh
  # zle modify-current-argument _replace_arg_with_selected_command
  local bounds
  bounds=($(_get_zle_cursor_word_bounds)) || return $?
  local b="${bounds[1]}"
  local e="${bounds[2]}"
  local query="${BUFFER:${b}:$((e-b))}"
  # Sometimes select-command returns success although the selection was
  # canceled, and I can't reproduce this when running it in isolation.
  if selected="$(select-command --query="${query}")" &&
      [[ -n "${selected}" ]]; then
    BUFFER="${BUFFER:0:${b}}${selected}${BUFFER:${e}}"
    ((CURSOR = b + ${#selected}))
  fi
}
zle -N _select_command_widget
# Select command using fzf
_bindkey_all_keymaps '\C-x\C-x' _select_command_widget

backward-delete-char-or-up-line() {
  emulate -L zsh
  if [[ -n "${LBUFFER}" ]]; then
    zle backward-delete-char
  elif [[ -n "${PREBUFFER}" ]]; then
    local len=$(( ${#PREBUFFER} -1 ))
    # Based on /usr/share/zsh/functions/Zle/edit-command-line
    print -Rz - "${PREBUFFER:0:${len}}"
    zle send-break
  fi
}
zle -N backward-delete-char-or-up-line

# This widget is a finer version of backward-delete-work that behaves similarly
# to the vi movements.
# The default backward-delete-word is too aggressive. For example, if the chars
# beyond the cursor are "abc:cde", it will delete all the characters instead of
# stopping at the colons.
# NOTE: As of 2020-03-01, this doesn't seem to be needed, since I can just use
# vi-backward-kill-word directly.
# _soft_backward_delete_word() {
#   emulate -L zsh
#   zle vi-backward-kill-word -K vicmd
# }
# zle -N _soft_backward_delete_word
# _bindkey_all_keymaps '^W' _soft_backward_delete_word

backward-delete-word-multiline() {
  emulate -L zsh
  if [[ -n "${LBUFFER}" ]]; then
    local len=${#LBUFFER}
    if [[ "${LBUFFER:$((len-1)):${len}}" == $'\n' ]]; then
      zle backward-delete-char
    fi
    # NOTE: after send-break, vi-backward-kill-word no longer works until the
    # current editing is aborted.
    # zle _soft_backward_delete_word
    # zle vi-backward-kill-word
    zle backward-delete-word
  elif [[ -n "${PREBUFFER}" ]]; then
    local len=${#PREBUFFER}
    # Based on /usr/share/zsh/functions/Zle/edit-command-line
    print -Rz - "${PREBUFFER:0:${$((len-1))}}"
    # send-break is required to break from a multiline editing mode.
    zle send-break
  fi
}
zle -N backward-delete-word-multiline
_bindkey_all_keymaps '^W' backward-delete-word-multiline

# Copied from:
# https://github.com/romkatv/dotfiles-public/blob/73c8fc684a3a0b51463d5f0d344acc4ade5daf79/dotfiles/bindings.zsh#L75-L88
redraw-prompt() {
  emulate -L zsh
  local chpwd=${1:-0} f
  if (( chpwd )); then
    for f in chpwd $chpwd_functions; do
      (( $+functions[$f] )) && $f &>/dev/null
    done
  fi
  for f in precmd $precmd_functions; do
    (( $+functions[$f] )) && $f &>/dev/null
  done
  zle .reset-prompt
  zle -R
}
zle -N redraw-prompt

_cd_ranger_widget() {
  local saved_buffer="${BUFFER}"
  local saved_cursor="${CURSOR}"
  BUFFER=''
  # Defined in functions.sh
  cd-ranger < "${TTY}" > "${TTY}"
  BUFFER="${saved_buffer}"
  CURSOR="${saved_cursor}"
  zle redraw-prompt 1
}
zle -N _cd_ranger_widget
_bindkey_all_keymaps '^[d' _cd_ranger_widget

# https://github.com/Vifon/deer
autoload -Uz deer
declare -Ag DEER_KEYS
# Use ijkl for navigation
DEER_KEYS[down]=k
DEER_KEYS[up]=i
DEER_KEYS[page_down]=K
DEER_KEYS[page_up]=I
DEER_KEYS[leave]=j
DEER_KEYS[append_path]=p
DEER_KEYS[append_abs_path]=P
DEER_KEYS[toggle_hidden]=h
DEER_KEYS[rifle]=o
DEER_KEYS[chdir]=q
DEER_KEYS[quit]=Q
# Define a new widget that refreshes the prompt after deer exists since we may
# have changed the working directory.
my-deer-widget() {
  zle deer
  zle redraw-prompt 1
}
zle -N deer
zle -N my-deer-widget
bindkey '^[e' my-deer-widget

# NOTE 2018-12-08: the fasd plugin seems to have a significant load time (0.2s
# on zeus18) and it's not really used, so disabling for now.
# source_compiled "${SUBMODULES_DIR}/terminal/fasd/"*.plugin.zsh
# # C-x C-f to do fasd-complete-f (only files)
# _bindkey_insert_keymaps '^X^F' fasd-complete-f
# # C-x C-d to do fasd-complete-d (only dirs)
# _bindkey_insert_keymaps '^X^D' fasd-complete-d

################################################################################
#                             Line editor vi modes                             #
################################################################################
# Commands copied from the default emacs keymap.
_bindkey_vi_keymaps '^P' up-history
_bindkey_vi_keymaps '^N' down-history
_bindkey_vi_keymaps '^A' beginning-of-line
_bindkey_vi_keymaps '^E' end-of-line
_bindkey_vi_keymaps '^Y' yank
# bindkey -M viins '^W'    _soft_backward_delete_word
bindkey -M viins '^K'    kill-line
bindkey -M viins '^U'    backward-kill-line
# NOTE: As of 2019-06-05, I don't use <C-d>, and the default of
# delete-char-or-list is confusing for me, so I'm unmapping it.
# bindkey -M viins '^D'    delete-char-or-list
_is_key_bound '^D' && bindkey -r '^D'
bindkey -M viins '^G'    send-break
bindkey -M viins '^V'    quoted-insert

bindkey -M vicmd '/'     vi-history-search-forward
bindkey -M vicmd '?'     vi-history-search-backward
bindkey -M vicmd 'w'     backward-word
bindkey -M vicmd 'W'     vi-backward-blank-word
bindkey -M vicmd 'e'     forward-word
bindkey -M vicmd 'E'     vi-forward-blank-word
bindkey -M vicmd 'Y'     vi-yank-eol
bindkey -M vicmd 'yy'    vi-yank-whole-line

# Navigation with ijkl
# bindkey -M vicmd 'i'    up-line-or-history
bindkey -M vicmd  'i'    history-beginning-search-backward
bindkey -M visual 'i'    history-beginning-search-backward
bindkey -M vicmd  'j'    backward-char
bindkey -M visual 'j'    backward-char
# bindkey -M vicmd 'k'     down-line-or-history
bindkey -M vicmd  'k'    history-beginning-search-forward
bindkey -M visual 'k'    history-beginning-search-forward
bindkey -M vicmd  'l'    forward-char
bindkey -M visual 'l'    forward-char

bindkey -M vicmd ' i'    vi-insert

# Undo/Redo with {,Alt}+u in vicmd mode.
bindkey -M vicmd 'u'     undo
bindkey -M vicmd '^[u'   redo

# NOTE: I wasn't able to bind key sequences of 3 characters or more, so I had to
# deviate from my vim convention of using Space+i as a replacement for i in
# visual mode.

# Based on: /usr/share/zsh/functions/Zle/surround
autoload -Uz surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround
bindkey -M vicmd sc change-surround
bindkey -M vicmd sd delete-surround
bindkey -M vicmd sa add-surround

# Copied from: /usr/share/zsh/functions/Zle/select-quoted
autoload -Uz select-quoted
zle -N select-quoted
for m in visual viopp; do
  for c in {a,i}{\',\",\`}; do
    bindkey -M ${m} ${c} select-quoted
  done
done

# Copied from: /usr/share/zsh/functions/Zle/select-bracketed
autoload -Uz select-bracketed
zle -N select-bracketed
for m in visual viopp; do
	for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
	  bindkey -M ${m} ${c} select-bracketed
	done
done

# Vim-like escaping jj/jk keybind
# bindkey -M viins 'jj' vi-cmd-mode
# bindkey -M viins 'jk' vi-cmd-mode

# Remove all vi insert mode keybindings that start with ESC so that there's no
# delay when switching to command mode (otherwise zle will wait to verify the
# entered command).
# bindkey -rpM viins '^['

################################################################################
#                                  Appearance                                  #
################################################################################
# Set up solarized dircolors from https://github.com/seebi/dircolors-solarized
function {
  local file="${SUBMODULES_DIR}/terminal/dircolors-solarized/dircolors.256dark"
  if [[ -r "${file}" ]]; then
    eval -- "$(dircolors --sh -- "${file}")"
  fi
}
# Must be executed after the dircolors call.
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'

zstyle ':completion:*:*:*:*:processes' \
  command 'ps -w -u ${USER} -o pid,%cpu,%mem,command '
zstyle ':completion:*:*:kill:*' format ' %F{yellow}PID | CPU | RAM | COMMAND%f'
zstyle ':completion:*:*:kill:*:processes' list-colors \
  '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'

# Commands whose combined user and system execution times (measured in seconds)
# are greater than this value have timing statistics printed for them.
REPORTTIME=10
# The format of process time reports with the time keyword. %J is the name of
# the job.
TIMEFMT="%J | %*E total | %U user | %S system | %P cpu | %M MB memory"
# Show process ID when listing jobs.
setopt LONG_LIST_JOBS

# Enable the default highlighting plus highlighting of matching brackets.
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZSH_HIGHLIGHT_MAXLENGTH=1024
# run-tracked flags:
# - +w means not to print warnings when redefining widgets.
#   This plugin redefines all widgets to add a hook for syntax highlighting.
# - +a means not to print warnings when defining aliases.
#   This plugin defines `alias fsh-alias=fast-theme`, which I don't use but
#   doesn't bother me either.
# - +f means not to print warnings when redefining functions.
#   Needed only if this plugin is loaded after zsh-history-substring-search,
#   since the latter defines two functions with the same name
#   (`_zsh_highlight` and `_zsh_highlight_bind_widgets`), though according to
#   its source code it's on purpose for their integration. Note that the
#   documentation for the plugin says to load zsh-history-substring-search
#   after zsh-syntax-highlighting, though it still worked for me when I
#   reversed their order.
# NOTE: This plugin must be loaded before zsh-history-substring-search.
# NOTE 2018-05-24: I ran into an issue where typing something and then "*" (for
# example "printf *") freezes the input typing, so I downgraded to 0.5.0 and it
# was solved.
# UPDATE 2018-11-18: That issue is still unresolved, but I now switched to
# fast-syntax-highlighting.
# As of 2020-05-16, I switched back to zsh-syntax-highlighting because the issue
# above is no longer reproducible and fast-syntax-highlighting is very slow
# after I type 'hub' in zeus18.
# As of 2020-05-19, I switched back to fast-syntax-highlighting because
# zsh-syntax-highlighting doesn't recognize the "pg" alias correctly, and I
# found a workaround for the hub issue.
# As of 2021-08-02, I switch back to zsh-syntax-highlighting because: 
# - I found a workaround to the "pg" alias issue 
# - zsh4humans uses it
# - It seems better maintained when looking at recent history
# - fast-syntax-highlighting messes up the input typing after the following 
#   command: "git --format='%(a=)'"
# As of 2021-10-30, the fast-syntax-highlighting upstream repo disappeared from
# github: 
# https://www.reddit.com/r/zsh/comments/qinb6j/httpsgithubcomzdharma_has_suddenly_disappeared_i/
maybe-run-tracked +w +a -- \
  source_compiled "${PLUGINS_DIR}/zsh-syntax-highlighting/"*.plugin.zsh
# maybe-run-tracked +w +a -- \
#   source_compiled "${PLUGINS_DIR}/fast-syntax-highlighting/"*.plugin.zsh
# fast-syntax-higlighting is very slow for hub which causes typing delays, but
# the git one is fine.
if [[ -n "${FAST_HIGHLIGHT-}" ]]; then
  FAST_HIGHLIGHT[chroma-hub]="${FAST_HIGHLIGHT[chroma-git]-}"
fi
# FAST_HIGHLIGHT[chroma-hub]="${FAST_HIGHLIGHT[chroma-git]}"
# Without this, comments are not visible with my terminal colors.
command_exists fast-theme && fast-theme XDG:overlay.ini
# NOTE: This plugin must be loaded after zsh-syntax-highlighting.
# +w means not to print warnings when redefining widgets.
# We added initial definitions for the widgets this plugin uses because they
# were bounded to keys and fast-syntax-highlighting requires all bound widgets
# to be fully defined.
maybe-run-tracked +w -- source_compiled \
  "${PLUGINS_DIR}/zsh-history-substring-search/"*.plugin.zsh

maybe-run-tracked -- source_compiled "${ZSHENV_DIR}/p10k.zsh"
# Settings when running as root.
if ((EUID == 0)); then
  # Show the background of the whole prompt in dark red. Ugly, but effective.
  typeset -g POWERLEVEL9K_BACKGROUND=124
  # Show the context (user@hostname) and filler between left and right prompts
  # in red to make it hard to miss.
  # declare -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=196
  # declare -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND=196
fi
typeset -g POWERLEVEL9K_RANGER_VISUAL_IDENTIFIER_EXPANSION='  ranger:'
# This makes the VCS status signs look better.
# POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=false
# +o means not to print warnings when setting options.
maybe-run-tracked +o -- source_compiled \
  "${PLUGINS_DIR}/powerlevel10k/powerlevel10k.zsh-theme"

################################################################################
#                                Notifications                                 #
################################################################################
# Let me know immediately when terminating job
setopt NOTIFY

# Notifications are only supported with X11. In other cases such as the Linux
# console, sourcing the plugin will output an error which we want to avoid.
if uses_local_graphics && [[ -n "${DISPLAY-}" ]]; then
  maybe-run-tracked-emulate -- source_compiled \
    "${PLUGINS_DIR}/zsh-notify/notify.plugin.zsh"
fi

_zsh_notify_format_duration() {
  emulate -L zsh
  local total_seconds="$1"
  local hours minutes seconds
  hours=$((total_seconds / (60 * 60)))
  minutes=$(((total_seconds - hours * 60 * 60) / 60))
  seconds=$((total_seconds % 60))
  if ((hours > 0)); then
    printf '%sh:%sm:%ss' "${hours}" "${minutes}" "${seconds}"
  elif ((minutes > 0)); then
    printf '%sm:%ss' "${minutes}" "${seconds}"
  else
    printf '%ss' "${seconds}"
  fi
}

_zsh_notify_custom_notifier() {
  emulate -L zsh
  # lib provides format-time and notification-title
  # source "${PLUGINS_DIR}/zsh-notify/lib"
  # local type time_elapsed title message
  # type="$1"
  # time_elapsed="$(format-time "$2")"
  local result="$1"
  local full_command title_command message
  full_command="$(<&0)"
  if ((${#full_command} > 20)); then
    title_command="$(printf '%s...' "${full_command:0:17}")"
    message="${full_command}"
  else
    title_command="${full_command}"
    message=''
  fi
  local duration="$(_zsh_notify_format_duration "$2")"
  local title
  title="$(printf '%s : %s after %s' \
    "${title_command}" "${result}" "${duration}")"

  if [[ "${result}" == 'success' ]]; then
    local notify_cmd='notify-success'
  else
    local notify_cmd='notify-failure'
  fi
  command "${notify_cmd}" "$title" "$message"
}

# NOTE: zstyle options must be set after sourcing the plugin.
zstyle ':notify:*' notifier _zsh_notify_custom_notifier
zstyle ':notify:*' command-complete-timeout 20
zstyle ':notify:*' always-notify-on-failure false
zstyle ':notify:*' always-check-active-window true
zstyle ':notify:*' enable-on-ssh false
function {
  emulate -L zsh
  if [[ "${HOST_ALIAS-}" == hera11 ]]; then
    local blacklist_regex='.'
  else
    local blacklisted_cmds=('editor' 'vim' 'nvim' 'less' 'git' 'ranger' 'bash'
      'zsh' 'gqui' '.*[iI][pP]ython' 'g3python' 'man' 'tmux' 'fg' 'fpp' 'yank'
      'iblaze' 'ovpn' 'ssh' 'zsh' 'fzf' 'dmesg' 'journalctl')
    local blacklist_regex='\b('"$(join_by '|' "${blacklisted_cmds[@]}")"')\b'
  fi
  zstyle ':notify:*' blacklist-regex "${blacklist_regex}"
}

################################################################################
#                      Interactive functions and aliases                       #
################################################################################

# This plugin needs to rebind space to expand aliases.
# +b means not to print warnings when rebinding keys.
maybe-run-tracked-emulate +b -- source_compiled \
  "${PLUGINS_DIR}/zsh-abbrev-alias/"*.plugin.zsh
# NOTE: alias-tips doesn't work with source_compiled/zcompile, only with regular
# sourcing.
maybe-run-tracked-emulate -- source \
  "${PLUGINS_DIR}/alias-tips/"*.plugin.zsh
# maybe-run-tracked-emulate -- source_compiled "${PLUGINS_DIR}/zpy/"*.plugin.zsh
# +a means not to print warnings when defining aliases.
maybe-run-tracked-emulate +a -- source_compiled \
  "${SHELL_CONFIG_DIR}/functions.sh"

################################################################################
#                                Local settings                                #
################################################################################

if [[ -f "${ZSHENV_DIR}/zshrc_local.zsh" ]]; then
  source_compiled "${ZSHENV_DIR}/zshrc_local.zsh"
fi

################################################################################
#                                End debugging                                 #
################################################################################
if [[ -n ${ZSHRC_ENABLE_PROFILING_BY_LINE} ]]; then
  unsetopt XTRACE
  # Restore stderr to the file description saved in stderr_fd_dup.
  exec 2>&"${stderr_fd_dup}" {stderr_fd_dup}>&-
  unset stderr_fd_dup
elif [[ -n ${ZSHRC_ENABLE_PROFILING} ]]; then
  profiling_log_file="${HOME}/zsh_startup.$$.log"
  printf 'Writing profiling data to file: %s\n' "${profiling_log_file}"
  zprof > "${profiling_log_file}"
fi
