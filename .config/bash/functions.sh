# TODO: Replace shebang with `# shellcheck shell=bash` in any non-executable
# scripts once the ALE PR is merged:
# https://github.com/dense-analysis/ale/pull/3216
# Functions and aliases for interactive use shared by bash and zsh.

# Make sure these variables are set.
: "${REPO_ROOT:=$([[ ${CONFIG_GET_ROOT:-0} == 1 ]] && config-repo-root "${BASH_SOURCE[0]:-${(%):-%x}}" || echo "${HOME}")}"
: "${SUBMODULES_DIR:=${REPO_ROOT}/submodules}"

# shellcheck source=../../.my_scripts/lib/base.sh
source "${REPO_ROOT}/.my_scripts/lib/base.sh"
# shellcheck disable=SC2153
# shellcheck source=fzf_select_files.sh
source "${REPO_ROOT}/.config/bash/fzf_select_files.sh"

sensible-xargs() {
  xargs --no-run-if-empty --delimiter='\n' "$@"
}

FZF_SHELL_OPTS=('--height=40%' '--reverse')
fzf-shell() {
  fzf "${FZF_SHELL_OPTS[@]}" "$@"
}

# Make aliases work when prepended by one of these commands. The space at the
# end of the alias value seems to do the trick.
alias sudo='sudo '
alias xargs='sensible-xargs '
alias watch='watch --color -n1 '

# Files and directories {{{

# ls/exa {{{
# Options shared by both ls and exa.
_default_ls_opts=(
  # show datetime as "2000-01-01 20:30"
  '--time-style=long-iso'
  # list directories before files
  '--group-directories-first'
  # display type indicator by file names
  '--classify'
)
if command_exists dircolors; then
  _default_ls_opts+=('--color=auto')
fi
if command_exists exa; then
  # shellcheck disable=SC2139
  alias exa="exa ${_default_ls_opts[*]}"
  alias ls='exa'
  alias lla='ll -a'
  alias lt='exa --tree'
  alias llt='lt -l'
  alias tree='exa --tree'
else
  # We add two more options to make ls more compatible with exa's defaults,
  # which seems more sensible to me:
  # - Hide the file group owner (rarely needed)
  # - Show human readable file sizes
  # shellcheck disable=SC2139
  alias ls="ls ${_default_ls_opts[*]} --no-group --human-readable"
  alias lla='ll -A'
fi
# Aliases shared by both ls and exa.
alias l='ls'
alias ll='ls -l'
alias la='lla'
# Note that exa doesn't support just specifying ls's `-t` (which sorts by time),
# but it requires an explicit sort field. "time" means the same as "modified",
# and is compatible with both GNU ls and exa, while "modified" is clearer but is
# only compatible with exa.
alias lst='ll --reverse --sort=time'
# }}} ls #

# Directory navigation {{{
# Use c instead of z for doing a fasd_cd. Also, cd to the directory if it
# exists in the current directory.
unalias z 2> /dev/null || true
alias c='cd-fasd-fzf'
alias d='cd-ranger'
# Originally I used the alias cdr, but that conflicts with the cdr function from
# zshcontrib.
alias r='git-cd-root'
alias u='builtin cd ..'
alias uu='cd-up-fzf'
alias u2='builtin cd ../..'
alias u3='builtin cd ../../..'
alias u4='builtin cd ../../../..'
alias u5='builtin cd ../../../../..'
alias 2u=u2
alias 3u=u3
alias 4u=u4
alias 5u=u5
alias ..='builtin cd ..'
alias ..2='builtin cd ../..'
alias ..3='builtin cd ../../..'
alias 2..=..2
alias 3..=..2
alias 4..=..2
alias 5..=..2
alias -- -='builtin cd -'
alias -- --='cd-dirstack-fzf'

# Based on:
# https://github.com/ranger/ranger/blob/master/examples/shell_automatic_cd.sh
cd-ranger() {
  local tmpfile
  tmpfile="$(mktemp -t "ranger_cd.XXXXX")"
  ranger --choosedir="${tmpfile}" -- "${@:-${PWD}}"
  if chosen_dir="$(cat -- "${tmpfile}")" && [ -n "${chosen_dir}" ] &&
    [ "${chosen_dir}" != "${PWD}" ]; then
    local s=0
    cd -- "${chosen_dir}" || s=$?
  fi
  rm -f -- "${tmpfile}"
  return "${s}"
}

# Uses fasd's latest directories along with fzf's matching.
cd-fasd-fzf() {
  if (($# == 1)); then
    if [[ -d $1 || $1 == - ]]; then
      # shellcheck disable=SC2164
      cd -- "$@"
      return
    elif [[ -f $1 ]]; then
      # shellcheck disable=SC2164
      cd -- "$(dirname "$1")"
      return
    fi
  fi
  local dir
  if dir="$(fasd -dl |
    fzf_select_dir "${FZF_SHELL_OPTS[@]}" --prompt "cd > " -q "$*" --tac \
      --no-sort)"; then
    cd -- "${dir}" || return
  fi
}

# Uses directory stack along with fzf's matching.
cd-dirstack-fzf() {
  local fzf_cmd=(fzf-shell '--select-1' '--exit-0')
  dir="$(dirs -p | "${fzf_cmd[@]}" --prompt "cd > " -q "$*")" || return
  cd -- "${dir/\~/${HOME}}" || return
}

cd-up-fzf() {
  local dir="${PWD}"
  # dir="$(readlink -f -- "${PWD}")"
  if [[ "${dir}" == '/' ]]; then
    return
  fi
  # TODO: fix the dirname function to maintain the absolute path.
  local dirs_up=()
  while dir="$(command dirname -- "${dir}")"; do
    dirs_up+=("${dir}")
    if [[ "${dir}" == '/' ]]; then
      break
    fi
  done
  local selected
  if selected="$(printf '%s\n' "${dirs_up[@]}" |
    fzf_select_dir "${FZF_SHELL_OPTS[@]}" --prompt "cd > " -q "$*" \
      --no-sort)"; then
    cd -- "${selected}" || return
  fi
}

alias mkdir='mkdir -p'

# mkdir+cd
mkcd() {
  mkdir -p -- "$@"
  cd -- "$@" || return
}

# Unused for now, consider deleting.
# alias uu='ecd ..'
# alias ...='ecd ..'
# alias -- ---='ecd -'
# }}} Directory navigation #

# File copying, moving, and deleting {{{

# Remove to trash by default
alias rm='trash-put'
# Prompt before moving files (-i is the interactive flag)
alias mv='mv -i'

# -a: recurse directories and preserve attributes
# -A: preserve ACLs
# -X: preserve extended attributes
# -u: don't overwrite newer files on the receiver side
# -zz: use new rsync compression
# --info=*: specify what to log
# --partial-dir=*: keep partial transfers to enable resuming
alias rsync='rsync -aAX -u -zz --info=flist2,name,progress --partial-dir=.rsync-partial'
alias rcp='rsync'
alias rcpc='rsync-cont'

# Swap two files
swap-files() {
  local TMPFILE="tmp.$$"
  [[ $# -ne 2 ]] && echo 'swap-files: 2 arguments needed' && return 1
  [[ ! -e $1 ]] && printf 'swap-files: %s does not exist\n' "$1" && return 1
  [[ ! -e $2 ]] && printf 'swap-files: %s does not exist\n' "$2" && return 1
  mv -- "$1" "${TMPFILE}"
  mv -- "$2" "$1"
  mv -- "${TMPFILE}" "$2"
}

# }}} Files copying, moving, and deleting #

# File opening and editing {{{
# Quick files/directories opening with fasd, fzf and viminfo.
alias e='editor-vim-oldfiles-fzf'
alias v='editor-vim-oldfiles-fzf'
# vim open source: vim without corp config.
alias vos='vim --cmd "let g:vimrc_oss_only = 1"'
alias le='less-fasd-fzf'
# Use vim as a pager.
alias vp='vim-less'

alias oo='sensible-open'
alias xo='sensible-open'
alias o='open-fasd-fzf'

# Browser
alias b='google-chrome'

alias pe=path-extractor

# Extract archives. Installed alternatives: unarchive, extract-by-extension.
alias ext=aunpack

# File explorer
alias fe='ranger'

# Uses fasd's latest files along with fzf's matching.
open-fasd-fzf() {
  if (($# == 1)) && [[ -f $1 ]]; then
    sensible-open "$@"
    return 0
  fi
  local file
  if file="$(fasd -fl | fzf_select_file "${FZF_SHELL_OPTS[@]}" \
    --prompt "open > " -q "$*" --tac --no-sort)"; then
    sensible-open "${file}"
  else
    return 1
  fi
}

_viminfo_files() {
  local _viminfo_path="${XDG_DATA_HOME:-${HOME}/.local/share}/vim/viminfo"
  \grep --text '^>' "${_viminfo_path}" | cut -c3-
}

_vim_oldfiles() {
  local tmpfile
  tmpfile="$(mktemp -t vim_oldfiles_XXXXX)" || return
  # Speed up the execution by using athame_mode.
  # Note: we must use the script command here because vim misbehaves when the
  # output is not a terminal.
  script --quiet --command "vim --cmd 'let g:athame_mode = 1' -c 'silent execute writefile(v:oldfiles, \"${tmpfile}\") | q'" /dev/null >> /dev/null
  cat -- "${tmpfile}"
  \rm -- "${tmpfile}"
}

_editor_filter_irrelevant_files() {
  \grep --text -Ev '(^/usr/share/n?vim/.*/doc/.*\.txt)|/share/firenvim/.*\.txt' |
    fast-files-checker
}

# Originally copied from https://github.com/junegunn/fzf/wiki/Examples
# Uses vim's latest files along with fzf's matching.
_editor-fzf() {
  local editor="${EDITOR:-vim}"
  local source_cmd="$1"
  shift
  if [[ ($# -eq 1 && -e $1) || $# -gt 1 ]]; then
    if [[ -d "$1" ]]; then
      file-manager "$1"
      return
    fi
    local resolved=()
    # Zsh doesn't support mapfile.
    local IFS=$'\n'
    # Resolve symlinks so that shellcheck source directives work correctly
    # shellcheck disable=SC2207
    if ! resolved=($(readlink -f -- "$@")) || [[ -z ${resolved[*]} ]]; then
      return 1
    fi
    "${editor}" -- "${resolved[@]}"
    return
  fi
  # NOTE: Zsh doesn't support mapfile, and hangs when using fzf in process
  # substitution, i.e. `cat < <(fzf)`. `cat < =(fzf)` does work, but is not
  # supported by bash. Therefore, we use a temporary file, which works well in
  # both bash and zsh.
  local tmpfile
  tmpfile="$(mktemp -t 'editor_fzf.XXXXX')" || return
  eval -- "${source_cmd}" |
    _editor_filter_irrelevant_files |
    fzf_select_file "${FZF_SHELL_OPTS[@]}" --prompt "${editor} > " --multi \
      -q "$*" |
    # Resolve symlinks so that shellcheck source directives and git hunks work
    sensible-xargs readlink -f >| "${tmpfile}" || return
  local file
  local files=()
  while IFS='' read -r file; do
    files+=("${file}")
  done < "${tmpfile}"
  \rm -- "${tmpfile}"
  # This commented out code is a more complex alternative to read lines into an
  # array in both bash and zsh, which is probably faster with "many" lines.
  # if is_bash; then
  #   mapfile -t files < "${tmpfile}"
  # elif is_zsh; then
  #   IFS=$'\n' read -r -d '' -A files < "${tmpfile}"
  #   # zsh a final newline in $tmpfile as a separator for an empty string, so it
  #   # includes one empty element at the end which we need to remove.
  #   [[ ${files[-1]} == '' ]] && files=(${files[1,-2]})
  # fi
  ((${#files[@]})) || return
  "${editor}" -- "${files[@]}"
}

editor-viminfo-fzf() {
  _editor-fzf '_viminfo_files' "$@"
}

editor-vim-oldfiles-fzf() {
  _editor-fzf '_vim_oldfiles' "$@"
}

editor-fzf() {
  _editor-fzf 'list-searched-files' "$@"
}

less-fasd-fzf() {
  if (($# == 1)) && [[ -f $1 ]]; then
    less -- "$@"
    return 0
  fi
  local file
  # Zsh doesn't support mapfile.
  local IFS=$'\n'
  # shellcheck disable=SC2207
  if files=($(fasd -fl |
    fzf_select_file "${FZF_SHELL_OPTS[@]}" --prompt "less > " --multi \
      -q "$*")) && [[ -n ${files[*]} ]]; then
    less -- "${files[@]}"
  else
    return 1
  fi
}
# }}} File opening #

# Misc {{{

# du shows human readable sizes in binary units (i.e. KiB) instead of decimal
# units (i.e. KB).
duh() {
  du --block-size=1 "$@" | numfmt --field 1 --to iec | sed 's/ /\t/' | column -t
}

# Differences from du:
# - du doesn't count the storage consumed by symlinks.
# - du uses KB instead of KiB with the -h/--human-readable param.
# - du defaults to showing the real disk usage, while this shows apparent size.
# - du doesn't double count hardlink, while this function does.
# - du has many more features.
dirsize() {
  for arg in "$@"; do
    local size
    size="$(find "${arg}" -print0 |
      xargs --null stat -c '%s' |
      awk '{s+=$1} END {print s}' |
      xargs numfmt --to iec)"
    printf "%s\t%s\n" "${size}" "${arg}"
  done | column -t
}
# }}} Misc #

# }}} Files and directories #

# Search {{{
_grep_alias='grep -Ei'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
# alias grep='grep --color=auto'
_grep_alias="${_grep_alias} --color=auto"
# shellcheck disable=SC2139
alias grep="${_grep_alias}"
unset _grep_alias

if command_exists rg; then
  # shellcheck disable=SC2034
  _BEST_GREP=('rg')
else
  # shellcheck disable=SC2034
  _BEST_GREP=(grep -E)
fi

# Grep for a running process
# The spaces around ${_BEST_GREP[*]} are intentional: this way Xorg won't match
# "rg".
alias pg='ps aux | \grep -v --fixed-strings " ${_BEST_GREP[*]} " | ${_BEST_GREP[*]}'
# Grep for an env variable
alias eg='env | ${_BEST_GREP[*]}'
# Grep for a history entry
# shellcheck disable=SC2139
alias hg="conda-run shell_history ${REPO_ROOT}/.config/bash/history/shell_history_choose_line.py --max-entries 100000 --initial-query"

_RG_OR_TAG='rg'
# AG_OR_TAG="ag --path-to-ignore ${REPO_ROOT}/.config/ripgrep/ignore"
if command_exists tag; then
  tag() {
    command tag "$@"
    # shellcheck disable=SC1090
    source "${TAG_ALIAS_FILE:-/tmp/tag_aliases}" 2> /dev/null
  }
  _RG_OR_TAG='tag'
  # AG_OR_TAG='tag'
fi

# shellcheck disable=SC2139
alias rg="${_RG_OR_TAG} --smart-case --hidden"
rgl() {
  # Always use rg and not tag when using a pager.
  "rg" --smart-case --color=always "$@" | less
}
# shellcheck disable=SC2139
alias rgnh="${_RG_OR_TAG} --smart-case --no-hidden"

# shellcheck disable=SC2139
# alias ag="${AG_OR_TAG} --smart-case --hidden"
# Always use ag and not tag for the pager.
# alias agl='"ag" --pager less'
# An ag alias for searching non hidden files only.
# shellcheck disable=SC2139
# alias anh="${AG_OR_TAG} --no-hidden"

# Config search {{{
_cd_config_repo() {
  if [[ "$(git remote get-url origin &> /dev/null)" == *gitlab.com/infokiller/config* ]]; then
    cd -- "$(git rev-parse --show-toplevel)" || return
  else
    cd -- "${HOME}" || return
  fi
}

# TODO: reduce config search latency that stems from the long time it takes to
# list the files. I could use `xargs -n <n>` to batch the files fed into
# ripgrep [1], however that causes an issues when using tag because the results
# are no longer numbered consistently (each batch has its own numbering).
# [1] https://github.com/BurntSushi/ripgrep/discussions/1639

_list_rgc_files() {
  list-searched-files | "${_BEST_GREP[@]}" -v \
    -e '^submodules' \
    -e '^\.local/bin/(archive|doom|git-icdiff|git-open|hostsctl|icdiff|fasd)' \
    -e '^\.local/bin/(lsarchive|org-capture|org-tangle|revolver|tmux-xpanes)' \
    -e '^\.local/bin/(unarchive)' \
    -e '^\.local/share/man' \
    -e '^\.emacs\.d' \
    -e '^install/keyboard/klfc/xkb_output' \
    -e '^\.config/Code - OSS' \
    -e '^\.config/old-preferences' \
    -e '^\.config/sway' \
    -e 'fpath/(async|deer|_lsarchive|prompt_pure_setup|_unarchive)' \
    -e 'vim/spell/en\.utf-8\.add' \
    -e 'plug\.vim' \
    -e 'tex_castel\.snippets' \
    -e 'p10k\.zsh' \
    -e 'generated_completion' \
    -e '\.tmTheme$' \
    -e 'eclipse.*/\.metadata' \
    -e 'external_packages_deps_archive\.txt' \
    -e '^root/usr/share/X11/xkb/(geometry|keycodes|rules)'
  local relevant_submodules=(
    'keydope'
    'desktop/i3-workspace-groups'
    'desktop/i3-scratchpad'
    'vim/vim-errorlist'
    'terminal/histcat'
  )
  # NOTE: The local variable declarations must be outside the loop, or otherwise
  # zsh prints their values. The issue seems to be that local variables are
  # scoped to the function, and re-declaring a local variable without assigning
  # to it prints it. Test case:
  #   zsh -c '() { local a; local a }'
  local escaped_prefix
  for submodule in "${relevant_submodules[@]}"; do
    local dir="submodules/${submodule}/"
    # https://unix.stackexchange.com/a/129063/126543
    escaped_prefix="$(printf '%s' "${dir}" | sed 's%[\\/&]%\\&%g')"
    (
      cd -- "${dir}" || return
      list-searched-files | sed "s/^./${escaped_prefix}&/" &
    )
  done
}
rgc() {
  (
    _cd_config_repo || return
    _list_rgc_files | "${_BEST_GREP[@]}" -v \
      -e 'root/usr/share/X11/xkb/symbols/extend' \
      -e 'xsendkeys' \
      -e '/.corp/' |
      sensible-xargs -- "${_RG_OR_TAG}" --smart-case "$@"
  ) || return
  # shellcheck disable=SC1090
  source -- "${TAG_ALIAS_FILE:-/tmp/tag_aliases}" 2> /dev/null
}
# Search config repo.
# shellcheck disable=SC2139
alias rgcc="rgc --color=always"
rgcl() {
  rgc --color=always "$@" | less
}

rgc-todos() {
  rgc '\bTODO(:|\([a-zA-Z0-9_-]*\))' "$@"
}
rgcl-todos() {
  rgc-todos --color=always "$@" | less
}
rgc-exp() {
  rgc '\bEXP:'
}
rgcl-exp() {
  rgc-exp --color=always "$@" | less
}
# }}} Config search #
# }}} Search #

# Git {{{
git-add-and-push() {
  git add "$@" && git commit && git push
}

git-cd-root() {
  local root
  if root="$(git rev-parse --show-cdup)"; then
    cd -- "${root}" || return
    return
  fi
  return 1
}

# Fetch pull requests and merge requests from Github/Gitlab.
git-fetch-prs() {
  while IFS='' read -r remote; do
    git fetch "${remote}" '+refs/pull/*/head:refs/remotes/origin/pr/*' \
      '+refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*'
  done < <(git remote)
}

# https://gist.github.com/magnetikonline/dd5837d597722c9c2d5dfa16d8efe5b9
git-list-large-objects() {
  local i=0
  while IFS='' read -r sha; do
    git ls-tree -r --long "${sha}"
    ((i += 1))
    if ((i % 100 == 0)); then
      echo 1>&2 "git-list-large-objects: finished processing ${i} commits"
    fi
  done < <(git rev-list --all) |
    sort --key 3 --unique |
    sort --key 4 --numeric-sort --reverse
}

# Sets an environment with a copy of the global git config. Useful for
# temporarily manipulating the git config, but should be used with care (ideally
# in a subshell) because it changes ${XDG_CONFIG_HOME} which may have unintended
# effects on other software exposed to the change.
# Git has the `-c <name>=<value>` param for overriding configuration values,
# however it's not always powerful enough to remove a behavior. For example,
# it's not possible to disable a URL rewriting rule. If you use
# `url.<base>.insteadOf=""`, it won't remove the existing rule but add a new one
# with the empty string as the value.
_git_setenv_global_config_copy() {
  local tmpdir="${TMPDIR:-/tmp}/git-config-tmp"
  mkdir -p -- "${tmpdir}"
  local xdg_config_home="${xdg_config_home:-${HOME}/.config}"
  local fake_xdg_config_home
  fake_xdg_config_home="$(mktemp -d --tmpdir="${tmpdir}" "$$.XXXXX")"
  cp -R -- "${xdg_config_home}/git" "${fake_xdg_config_home}/git"
  echo '# vim: set ft=gitconfig :' >> "${fake_xdg_config_home}/git/config"
  while IFS='' read -r file; do
    ln -s "${xdg_config_home}/${file}" "${fake_xdg_config_home}/${file}"
  done < <(find "${xdg_config_home}" -mindepth 1 -maxdepth 1 -not -name git \
    -exec basename '{}' \;)
  # printf 'temp git config file: %s\n' "${fake_xdg_config_home}/git/config"
  export XDG_CONFIG_HOME="${fake_xdg_config_home}"
}

git-export-https() {
  _git_setenv_global_config_copy
  while IFS='' read -r name; do
    git config --global --unset-all "${name}"
  done < <(git config --global --name-only --list | grep '^url\.(ssh|git)')
  git config --global --add 'url.https://github.com/.insteadOf' \
    'git@github.com:'
  git config --global --add 'url.https://github.com/.insteadOf' \
    'ssh://git@github.com:'
  git config --global --add 'url.https://gitlab.com/.insteadOf' \
    'git@gitlab.com:'
  git config --global --add 'url.https://gitlab.com/.insteadOf' \
    'ssh://git@gitlab.com:'
}

# Sometimes SSH has issues, so this can be used to force using https.
git-https() {
  # Execute in a subshell to avoid modifying the environment.
  (git-export-https && git "$@")
}

git-is-dirty() {
  # This command will always succeed, but should print the modified files if
  # there are any. Therefore, we check if the output is empty.
  [[ -n "$(git status --porcelain --untracked-files=no --ignore-submodules)" ]]
}

git-reset-hard-safe() {
  local is_dirty=0
  git-is-dirty && is_dirty=1
  if ((is_dirty)); then
    echo 'git-reset-hard-safe: repo is dirty, stashing changes'
    git stash push
  fi
  git checkout master || return
  git reset --hard origin/master || return
  # Not sure why, but git can delete a lot of repo files after a hard reset
  # which is needed when the history changed, so we restore them.
  git ls-files --deleted | sensible-xargs git checkout HEAD --
}

_git_ls_staged_files=(git --no-pager diff --name-only --no-renames --staged)
_git_ls_unstaged_files=(git ls-files --modified --full-name)
# TODO: Unify the git pager (delta etc.) used here and in git config. I can
# create a my-git-pager script, but then the git config will be less self
# contained (if I copy my config without my scripts it will break).
_git_diff_index_preview='git diff --color=always -- {} |
  { delta || diff-so-fancy || cat; } 2> /dev/null'
_git_diff_head_preview='git diff --color=always HEAD -- {} |
  { delta || diff-so-fancy || cat; } 2> /dev/null'

git-add-fzf() {
  local repo_root files
  repo_root="$(git rev-parse --show-toplevel)"
  (
    cd -- "${repo_root}" || exit
    # During a merge conflict, _git_ls_unstaged_files return duplicates, so we
    # must dedup the output.
    "${_git_ls_unstaged_files[@]}" |
      dedup |
      fzf-shell --height=80% --multi --preview="${_git_diff_index_preview}" \
        --prompt='Add > ' |
      sensible-xargs git add --
  )
}

git-reset-fzf() {
  local repo_root files
  repo_root="$(git rev-parse --show-toplevel)"
  (
    cd -- "${repo_root}" || exit
    "${_git_ls_staged_files[@]}" |
      fzf-shell --height=80% --multi --preview="${_git_diff_head_preview}" \
        --prompt='Reset > ' |
      sensible-xargs git reset HEAD --
  )
}

_git_select_changed_files_fzf() {
  local repo_root files
  repo_root="$(git rev-parse --show-toplevel)"
  (
    cd -- "${repo_root}" || exit
    (
      # Concatenate the lists of staged and unstaged modified files. See also:
      # https://unix.stackexchange.com/a/176929/126543
      "${_git_ls_unstaged_files[@]}" "${repo_root}"
      "${_git_ls_staged_files[@]}"
    ) | sort -u | fzf-shell --multi --preview="${_git_diff_head_preview}" "$@"
  )
}

git-restore-files-fzf() {
  local repo_root files
  repo_root="$(git rev-parse --show-toplevel)"
  # Zsh doesn't support mapfile.
  local IFS=$'\n'
  # shellcheck disable=SC2207
  if ! files=($(_git_select_changed_files_fzf --prompt='Restore > ')) ||
    [[ -z ${files[*]} ]]; then
    return 1
  fi
  (
    cd -- "${repo_root}" || return
    printf '%s\n' "${files[@]}"
    # Check out other staged files.
    printf '%s\n' "${files[@]}" |
      sensible-xargs "${_git_ls_staged_files[@]}" --diff-filter=A -- |
      sensible-xargs git reset --
    # Reset new staged files.
    printf '%s\n' "${files[@]}" |
      sensible-xargs "${_git_ls_staged_files[@]}" --diff-filter=CDMRTUXB -- |
      sensible-xargs git checkout HEAD --
    # Check out unstaged files.
    printf '%s\n' "${files[@]}" |
      sensible-xargs "${_git_ls_unstaged_files[@]}" -- |
      sensible-xargs git checkout HEAD --
  )
}

# Based on https://github.com/junegunn/fzf/wiki/examples#git
git-select-commits-fzf() {
  local get_commit_sha="sha=\$(printf '%s\n' {} | grep -o '[a-f0-9]\\{7,\\}' | head -1) && [[ -n \${sha} ]]"
  git log --color=always --all --graph |
    fzf-shell --ansi --multi --no-sort --reverse --tiebreak=index \
      --preview-window=right:60% --preview="${get_commit_sha} &&
      git show --color=always \${sha}" "$@" |
    \grep -E --text -o '[a-f0-9]{7,}'
}

git-checkout-commit-fzf() {
  local git_log_format
  if ! git_log_format="$(git config --get pretty.myshort)"; then
    git_log_format='%h %ad %d %s%C [%cn]'
  fi
  if sha="$(git-select-commits-fzf --no-multi --prompt='Checkout > ')" &&
    [[ -n "${sha-}" ]]; then
    git --no-pager log -1 \
      --pretty=format:"Checking out commit ${git_log_format}" \
      --date='format:%Y-%m-%d %H:%M' "${sha}"
    printf '\n'
    git checkout "${sha}"
  fi
}

# shellcheck disable=SC2034
declare -g PUBLIC_CONFIG_GIT_DIR="${HOME}/.local/var/git_dirs/config-public"
# shellcheck disable=SC2034
declare -g PRIVATE_CONFIG_GIT_DIR="${HOME}/.local/var/git_dirs/config-private"
alias config-public='git --git-dir="${PUBLIC_CONFIG_GIT_DIR}" --work-tree="${HOME}"'
alias config-private='git --git-dir="${PRIVATE_CONFIG_GIT_DIR}" --work-tree="${HOME}"'
alias gfexp='export GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}"'
alias gfrexp='export GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}"'

alias scr='sync-config-repos'

git-push-blind() {
  local repo_root
  repo_root="$(git rev-parse --show-toplevel)"
  (cd "${repo_root}" && git add -u .)
  git commit -m 'updates'
  git push
}

config-push-blind() {
  echo 'Blind pushing private config...'
  GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-push-blind
  echo 'Blind pushing public config...'
  GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-push-blind
}
alias cpb='config-push-blind'

# NOTE(infokiller): I used to define the git aliases programmatically in this
# script, but it used eval which was bad for performance. Therefore, I'm now
# generating the aliases "offline" with the script generate_git_aliases.py and
# copy it to this file.

# Autogenerated git aliases {{{
# Generated by generate_git_aliases.py on 2020-08-26 22:12:24 UTC
alias 'g'='git'
alias 'gf'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git'
alias 'gfr'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git'
alias 'ga'='git add'
alias 'gfa'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git add'
alias 'gfra'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git add'
alias 'gap'='git-add-and-push'
alias 'gfap'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-add-and-push'
alias 'gfrap'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-add-and-push'
alias 'gaf'='git-add-fzf'
alias 'gfaf'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-add-fzf'
alias 'gfraf'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-add-fzf'
alias 'gau'='git add --update'
alias 'gfau'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git add --update'
alias 'gfrau'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git add --update'
alias 'gb'='git branch'
alias 'gfb'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git branch'
alias 'gfrb'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git branch'
alias 'gba'='git branch --all'
alias 'gfba'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git branch --all'
alias 'gfrba'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git branch --all'
alias 'gc'='git commit'
alias 'gfc'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git commit'
alias 'gfrc'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git commit'
alias 'gcp'='git commit && git push'
alias 'gfcp'='(export GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}"; git commit && git push)'
alias 'gfrcp'='(export GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}"; git commit && git push)'
alias 'gcl'='git clone'
alias 'gfcl'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git clone'
alias 'gfrcl'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git clone'
alias 'gcm'='git commit --message'
alias 'gfcm'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git commit --message'
alias 'gfrcm'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git commit --message'
alias 'gco'='git checkout'
alias 'gfco'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git checkout'
alias 'gfrco'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git checkout'
alias 'gcof'='git-checkout-commit-fzf'
alias 'gfcof'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-checkout-commit-fzf'
alias 'gfrcof'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-checkout-commit-fzf'
alias 'gcr'='git-cd-root'
alias 'gfcr'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-cd-root'
alias 'gfrcr'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-cd-root'
alias 'gd'='git diff'
alias 'gfd'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git diff'
alias 'gfrd'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git diff'
alias 'gdh'='git diff HEAD'
alias 'gfdh'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git diff HEAD'
alias 'gfrdh'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git diff HEAD'
alias 'gdd'='git diff .'
alias 'gfdd'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git diff .'
alias 'gfrdd'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git diff .'
alias 'gds'='gd --staged'
alias 'gfds'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" gd --staged'
alias 'gfrds'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" gd --staged'
alias 'gdn'='gd --name-only'
alias 'gfdn'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" gd --name-only'
alias 'gfrdn'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" gd --name-only'
alias 'gdt'='git difftool'
alias 'gfdt'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git difftool'
alias 'gfrdt'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git difftool'
alias 'gdts'='gdt --staged'
alias 'gfdts'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" gdt --staged'
alias 'gfrdts'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" gdt --staged'
alias 'gdtn'='gdt --name-only'
alias 'gfdtn'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" gdt --name-only'
alias 'gfrdtn'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" gdt --name-only'
alias 'gg'='git grep'
alias 'gfg'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git grep'
alias 'gfrg'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git grep'
alias 'ggl'='git grep --files-with-matches'
alias 'gfgl'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git grep --files-with-matches'
alias 'gfrgl'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git grep --files-with-matches'
alias 'gim'='nvim -c ":MagitOnly"'
alias 'gfim'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" nvim -c ":MagitOnly"'
alias 'gfrim'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" nvim -c ":MagitOnly"'
alias 'gl'='git log --pretty=myshort'
alias 'gfl'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git log --pretty=myshort'
alias 'gfrl'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git log --pretty=myshort'
alias 'gla'='git log --pretty=myshort --all --graph'
alias 'gfla'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git log --pretty=myshort --all --graph'
alias 'gfrla'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git log --pretty=myshort --all --graph'
alias 'glp'='git log --pretty=mymedium --patch'
alias 'gflp'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git log --pretty=mymedium --patch'
alias 'gfrlp'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git log --pretty=mymedium --patch'
alias 'gls'='git log --pretty=mymedium --stat'
alias 'gfls'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git log --pretty=mymedium --stat'
alias 'gfrls'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git log --pretty=mymedium --stat'
alias 'gop'='git open'
alias 'gfop'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git open'
alias 'gfrop'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git open'
alias 'gpb'='git-push-blind'
alias 'gfpb'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-push-blind'
alias 'gfrpb'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-push-blind'
alias 'gpl'='git pull'
alias 'gfpl'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git pull'
alias 'gfrpl'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git pull'
alias 'gprs'='git-fetch-prs'
alias 'gfprs'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-fetch-prs'
alias 'gfrprs'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-fetch-prs'
alias 'gpu'='git push'
alias 'gfpu'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git push'
alias 'gfrpu'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git push'
alias 'grf'='git-reset-fzf'
alias 'gfrf'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-reset-fzf'
alias 'gfrrf'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git-reset-fzf'
alias 'grmt'='git remote'
alias 'gfrmt'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git remote'
alias 'gfrrmt'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git remote'
alias 'gs'='git status'
alias 'gfs'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git status'
alias 'gfrs'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git status'
alias 'gss'='git status --short'
alias 'gfss'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git status --short'
alias 'gfrss'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git status --short'
# End of generated git aliases
# }}} Autogenerated git aliases #
# }}} Git #

# Job management {{{
alias j='jobs -l'
alias jl='jobs -l'
alias j1='fg %1'
alias j2='fg %2'
alias j3='fg %3'
alias j4='fg %4'
alias j5='fg %5'
alias f1='fg %1'
alias f2='fg %2'
alias f3='fg %3'
alias f4='fg %4'
alias f5='fg %5'
alias k1='kill %1'
alias k2='kill %2'
alias k3='kill %3'
alias k4='kill %4'
alias k5='kill %5'
# }}} Job management #

# Package management {{{
if command_exists apt; then
  # Apt aliases
  alias ai='sudo apt install'
  alias as='apt search'
  # Copied from http://askubuntu.com/a/197532/368043
  # NOTE: This must be kept in sync with ~/.config/bash/completion.sh
  apt-update-repo() {
    for source in "$@"; do
      sudo apt-get update -o Dir::Etc::sourcelist="sources.list.d/${source}" \
        -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
    done
  }
fi

# I used to check for the existence of the pacman command, but it can yield a
# false positive because of the pacman game.
if [[ "${DISTRO-}" == arch ]]; then
  alias pacman='sensible-pacman'
  alias pi='pacman -S'
  alias aur-update='yay -Syu --aur --answerclean=None --answeredit=All --answerdiff=All --noupgrademenu'
  alias arch-update-all='sensible-pacman -Syu; aur-update'
  # This list used to have kmod and *-dkms packages, but based on the discussion
  # below they seem unnecessary:
  # https://bbs.archlinux.org/viewtopic.php?pid=1912472#p1912472
  _KERNEL_PACKAGES=(
    linux linux-lts linux-hardened linux-zen
    linux-headers linux-lts-headers linux-hardened-headers linux-zen-headers
    nvidia nvidia-dkms nvidia-lts nvidia-utils nvidia-settings
  )
  # shellcheck disable=SC2139
  alias arch-update-no-kernel='sensible-pacman -Syu --ignore '"$(join_by ',' "${_KERNEL_PACKAGES[@]}")"'; aur-update'
  unset _KERNEL_PACKAGES
  pacman-pkg-files-fzf() {
    local pkg
    # shellcheck disable=SC2016
    pkg="$(pacman -Qq |
      fzf --preview='pkg={}; pacman -Qi "${pkg}"; pacman -Qlq "${pkg}"')" ||
      return
    printf 'Package: %s\n\n' "${pkg}"
    pacman -Qql "${pkg}" | tovim
  }
fi
# }}} Package management #

# Systemd {{{
alias sc='systemctl'
alias scs='systemctl status'
alias scsys='systemctl --system'
alias scu='systemctl --user'
alias scus='systemctl --user status'
# I disabled --pager-end but that implies -n1000 to guarantee that the pager
# will not buffer logs of unbounded size, which is confusing (since it makes it
# look like there's not many logs).
alias jc='journalctl -o short-iso-precise'
alias jcs='jc --boot=0 --lines=5000'
alias jcsys='jc --system'
alias jcu='jc --user'
# }}} Systemd #

# Clipboard {{{
strip-trailing-newline() {
  printf '%s' "$(</dev/stdin)";
}

alias xclip='xclip -selection c'
# Strip the trailing newline when copying by default to make it easier to paste
# inside text. Use `xcl` for keeping the newline.
alias xc='strip-trailing-newline | xclip'
alias xcl=xclip
alias cpwd='pwd | xclip'

alias yank='yank -- xsel -b'
alias y='yank'
# }}} Clipboard #

# Notifications {{{
# Notify normally if previous command succeeded, otherwise notify about the
# failure.
notify-anyway() {
  # shellcheck disable=SC2181
  if (($? == 0)); then
    notify-success "$* success"
  else
    notify-failure "$* failure"
  fi
}

alias n='notify-anyway'
# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
# alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && printf '%s\n' terminal || printf '%s\n' error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
# }}} Notifications #

# Tmux {{{
alias tmxcs='tmux-switch-session'
alias tmxdc='tmux-detach-client'
alias tmxks='tmux-kill-session'
alias tmxns='tmux-main-or-zsh'

_maybe_run_with_colorterm() {
  if [[ -n "${COLORTERM-}" ]]; then
    printf "env COLORTERM='%s' " "${COLORTERM}"
  fi
}
_fix_terminal_after_ssh_tmux() {
  # TODO: Using tmux in an SSH session leaves the terminal in a strange state
  # after logging out. This can be reproduced by: 
  # 1. Opening a terminal with zsh
  # 2. Running: ssh <hostname> -t "tmux new-session -A -D -s TEST"
  # 3. Disconnecting from SSH using the Enter+tilde key sequence
  # 4. Focusing and defocusing the terminal window a few times
  # 5. Pressing up in zsh, which will show many empty lines
  # 
  # Using the reset command fixes it, but it clear the screen, so instead I'm
  # using nvim which also seems to fix it.
  nvim -u /dev/null -c q
}
_ssh-tmxcs() {
  if (($# < 2)); then
    print_error 'Usage: ssh-tmxcs [SSH_ARGS] REMOTE'
    return 1
  fi
  local use_et="$1"
  local ssh_args=("${@:2:(($# - 2))}")
  # In bash, we could use a string directly with `${*: -1}`, but in zsh that
  # returns the last char, not the last element of the array as a string.
  local remote=("${@: -1}")
  # shellcheck disable=SC2016
  local cmd='s="$(tmux-select-session)" || exit; '
  cmd+="$(_maybe_run_with_colorterm)"
  # shellcheck disable=SC2016
  cmd+='tmux attach -d -t "${s}"'
  if ((use_et)); then
    ssh-et "${ssh_args[@]}" -t "${cmd}" "${remote[*]}"
  else
    ssh "${ssh_args[@]}" -t "${remote[*]}" "${cmd}"
  fi
  _fix_terminal_after_ssh_tmux
}
_ssh-tmxns() {
  if (($# < 3)); then
    print_error 'Usage: ssh-tmxns ET_FLAG [SSH_ARGS] REMOTE TMUX_SESSION'
    return 1
  fi
  local use_et="$1"
  local ssh_args=("${@:2:(($# - 3))}")
  local remote=("${@: -2:1}")
  # In bash, we could use a string directly with `${*: -1}`, but in zsh that
  # returns the last char, not the last element of the array as a string.
  local session_name=("${@: -1}")
  local cmd
  cmd="$(_maybe_run_with_colorterm)"
  cmd+="$(printf "tmux new-session -A -D -s '%s'" "${session_name[*]}")"
  if ((use_et)); then
    ssh-et "${ssh_args[@]}" -t "${cmd}" "${remote[*]}"
  else
    ssh "${ssh_args[@]}" -t "${remote[*]}" "${cmd}"
  fi
  local s=$?
  _fix_terminal_after_ssh_tmux && return $s
}
alias ssh-tmxcs='_ssh-tmxcs 0'
alias ssh-tmxns='_ssh-tmxns 0'
alias ssh-et-tmxcs='_ssh-tmxcs 1'
alias ssh-et-tmxns='_ssh-tmxns 1'
# }}} Tmux #

# Python {{{
# __launch_ipython() {
#   local cmd='ipython'
#   local dev_ipython_cmd="${HOME}/.local/pkg/conda/envs/tools/bin/ipython"
#   if ! command_exists ipython && command_exists "${dev_ipython_cmd}"; then
#     cmd="${dev_ipython_cmd}"
#   fi
#   EDITOR=vim-in-ipython "${cmd}"
# }
# Launch it with the python executable so that it works correctly in virtual
# envs.
# alias ip='EDITOR=vim-in-ipython python -c "import IPython; IPython.terminal.ipapp.launch_new_instance()"'
alias ipy='EDITOR=vim-in-ipython ipython'
alias jnb='jupyter notebook'
alias jlb='jupyter lab'

# NOTE: we can't define a `conda` function or alias because it's already defined
# by the conda.sh script shipped by conda for enabling the `conda activate`
# command.
conda-or-mamba() {
  if [[ ${1-} =~ (activate|deactivate) ]]; then
    command conda "$@"
    return
  fi
  local cmd=conda
  if command_exists mamba; then
    cmd=mamba
  fi
  command "${cmd}" "$@"
}
# "coba" is a mix of conda and mamba
alias coba='conda-or-mamba'

alias pya='conda activate'

# https://github.com/Russell91/pythonpy
alias p=py
alias px='py -x'
# Disabled for now as ptipython is not mature enough for replacing the default
# ipython prompt.
# alias ipython='run_if_executable_exists ptipython ipython'

# Based on:
# https://github.com/wookayin/dotfiles/blob/master/zsh/zsh.d/alias.zsh#L204
pip-list-fzf() {
  pip list "$@" |
    fzf-shell --header-lines 2 --reverse --nth 1 --multi |
    awk '{print $1}'
}

pip-search-fzf() {
  if (($# == 0)); then
    print_error 'pip-search-fzf: argument required'
    return 1
  fi
  pip search "$@" |
    \grep --text '^[a-z]' |
    fzf-shell --reverse --nth 1 --multi --no-sort |
    awk '{print $1}'
}

conda-list-fzf() {
  conda list "$@" |
    fzf-shell --header-lines 3 --reverse --nth 1 --multi |
    awk '{print $1}'
}

conda-reset-env() {
  # Obtained using:
  # - conda search conda --info
  # - pipdeptree -p conda
  # - Creating new env and checking the installed packages
  local manadatory_packages=(conda pycosat pyopenssl python python_abi requests
    certifi chardet idna brotlipy cffi cryptography urllib3 ruamel_yaml yaml
    pycparser pysocks six yaml tqdm setuptools _libgcc_mutex _openmp_mutex
    ca-certificates certifi ld_impl_linux-64 libffi libgcc-ng libgomp
    libstdcxx-ng ncurses openssl python pip python_abi readline setuptools
    sqlite tk wheel xz zlib)
  local packages_regex
  packages_regex="$(printf '^(%s)' \
    "$(join_by '|' "${manadatory_packages[@]}")")"
  conda list |
    \grep --text -E -v -e 'pypi$' -e '^\s*#' -e "${packages_regex}" |
    awk '{print $1}' |
    sensible-xargs conda uninstall
  conda list | \grep --text 'pypi$' | sensible-xargs pip uninstall
}
# }}} Python #

# GPUs {{{
# TODO: Add to each process the used GPU and memory usage. The gpustat library
# actually has all the information needed. I should probably write a python
# script to do that.
# TODO: Add stuff from https://github.com/neighthan/gpu-utils
_format_gpu_pids() {
  sensible-xargs ps -o 'user,pid,start_time,%cpu,rss,cmd' --pid |
    \grep --text -Ev '^(root|gdm|nvidia)' |
    # Show /home/user as ~
    sed -r 's%/home/(\w|-)+%~%g' |
    # Show RSS in human readable units
    numfmt --header --from-unit=1024 --to=iec --field 5 |
    # Print first ps fields (all except cmd) tab separated. Those fields can't
    # have whitespace in them so splitting them by whitespace will work. In
    # contrast, the cmd field may have whitespace in it so we don't want to
    # replace it with tabs because then the `column` command will treat every word
    # in the cmd as a separate column. I used to do this with sed but it became
    # cumbersome with multiple fields:
    # sed -r 's/(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/\1\t\2\t\3\t\4\t\5\t\6/' |
    awk '{
    for (i=1; i <= 5; i++) printf "%s\t", $i
    for (i=6; i <= NF; i++) printf "%s ", $i
    printf "\n"
  }' |
    column -t -s $'\t'
}

nvidia-smi-top-processes() {
  nvidia-smi |
    \grep -E -o '\s+([0-9]|N/A)\s+[0-9]+\s+[CG]' |
    awk '{print $2}' |
    _format_gpu_pids
}
alias nvidia-smi-ps='nvidia-smi-top-processes'
alias nvidia-all-processes='sudo lsof -t /dev/nvidia* | _format_gpu_pids'

# Returns the GPU id that is the least occupied (currently only looks at
# memory). See also:
# https://github.com/wookayin/dotfiles/blob/dd3d08410be1f1c92634817d022ff3ca4330a7cc/zsh/zsh.d/alias.zsh#L314
_gpu_get_best() {
  # The python binary is hardcoded to the conda tools env one since if we're in
  # a virtual env it might not have gpustat installed, but the default python
  # binary used here should have it.
  "${HOME}/.local/pkg/conda/envs/tools/bin/python" -c '
import sys
import gpustat

if len(sys.argv) > 1:
  limited_gpu_indices = [int(i) for i in sys.argv[1].split(",")]
else:
  limited_gpu_indices = None

stats = gpustat.new_query()
if limited_gpu_indices:
  stats = [gpu for gpu in stats if gpu.index in limited_gpu_indices]

best_gpu = max(stats, key=lambda g: g.memory_available)
best_gpu.print_to(sys.stderr)
sys.stderr.write("\n")
print(best_gpu.index)' "$@"
}

_gpu_select_fzf() {
  gpustat --no-header | fzf-shell --tac | sed -r 's/^\[([0-9]+)\].*$/\1/'
}

gpu-select-id() {
  if (($# != 1)); then
    print_error 'gpu-select-id: must provide single argument'
    return 1
  fi
  printf 'Setting default GPU to: %s\n' "$1"
  export CUDA_DEVICE_ORDER=PCI_BUS_ID
  export CUDA_VISIBLE_DEVICES="$1"
}

gpu-select-fzf() {
  local gpu_id
  if ! gpu_id="$(_gpu_select_fzf)" || [[ -z "${gpu_id-}" ]]; then
    return 1
  fi
  gpu-select-id "${gpu_id}"
}

gpu-select-auto() {
  local gpu_id
  if ! gpu_id="$(_gpu_get_best "$@")" || [[ -z "${gpu_id-}" ]]; then
    return 1
  fi
  gpu-select-id "${gpu_id}"
}

# }}} GPUs #

# List all commands {{{
# list-commands outputs the list of all "commands"- binaries, shell functions,
# and shell builtins.
list-commands() {
  if is_zsh; then
    # shellcheck disable=SC2154
    printf '%s\n' "${(k)builtins[@]}" "${(k)commands[@]}" "${(k)functions[@]}" \
      "${(k)aliases[@]}"
  elif is_bash; then
    compgen -A function -bc
  else
    printf >&2 '%s\n' 'Unrecognized shell!'
    return 1
  fi | \grep --text -v '^_'
}

# TODO: Add a command for editing a function/alias/command with fzf completion
# and preview.

# Possible enhancements:
# - Select a command and output it.
# - If it's a shell function or alias, show the function definition in the
#   preview.
# - If it's a binary, show the path in the preview.
select-command() {
  list-commands | sort -u | fzf-tmux --exit-0 "$@"
}
# }}} List all commands #

# Misc {{{
alias t='time'
time-output-lines() {
  "$@" > >(prepend-time) 2> >(prepend-time 1>&2)
}
alias tt='time-output-lines'

benchmark-command() {
  local num_runs="${1:-100}"
  shift
  local before
  before=$(($(date +%s%N) / 1000000))
  printf 'Running command "%s" %d times\n' "$*" "${num_runs}"
  for _ in $(seq 1 "${num_runs}"); do
    eval -- "$@" > /dev/null
  done
  local after
  after=$(($(date +%s%N) / 1000000))
  local per_run
  per_run=$(bc < <(printf 'scale=2; %d/%d\n' $((after - before)) "${num_runs}"))
  print_bold "${per_run} ms per run ($((after - before)) ms total)"
}
alias bm='benchmark-command'

alias rif='run-interactive-function'
alias w='watch run-interactive-function'

run-if-executable-exists() {
  local e1="$1"
  local e2="$2"
  local e
  if command_exists "${e1}"; then
    e="${e1}"
  else
    e="${e2}"
  fi
  shift 2
  "${e}" "$@"
}

retry-forever() {
  while true; do
    "$@" || s="$?"
    echo "Command exit status: ${s}, sleeping and retrying..."
    sleep 5
  done
}

# https://stackoverflow.com/a/11532197
dedup() {
  awk '!seen[$0]++'
}

line-count-by-subfolder-sorted() {
  line-count-by-subfolder "$@" | sort -r -n -k 2 | column -t
}
alias lcs='line-count-by-subfolder-sorted'


if [[ -f "${SUBMODULES_DIR}/terminal/stderred/build/libstderred.so" ]]; then
  alias stderred='LD_PRELOAD=${SUBMODULES_DIR}/terminal/stderred/build/libstderred.so${LD_PRELOAD:+:${LD_PRELOAD}}'
  alias erd="stderred"
fi

alias cht='${SUBMODULES_DIR}/terminal/cheat.sh/share/cht.sh.txt'

if command_exists pydf; then
  alias df='pydf'
else
  alias df='df -h'
fi

# Usage:
#   monitor-slow-pings [ip]
# For a persistent log:
#   monitor-slow-pings 1.1 | tee -a ~/tmp/slow_pings_log.txt
monitor-slow-pings() {
  local get_con="nmcli con show --active | \grep --text -Ev '(vpn|bridge)' | tail -1 | awk '{print \$1}'"
  local py_precmd
  py_precmd="$(printf 'get_con = lambda: subprocess.check_output("%s", shell=True).decode("utf-8").strip()' "${get_con}")"
  py_cmd='print(f"{datetime.datetime.now()}: {get_con()}: {x}", flush=True)'
  # Without using stdbuf the output buffering causes lines to be output after a
  # large delay.
  {
    while true; do
      timeout 3 ping "${1:-1.1}" 2>&1
      (($? == 124)) && echo 'ping command timed out'
    done
  } |
    stdbuf -oL -eL grep --text -E -v 'time=[0-2]?[0-9]{1,2}(\.[0-9]+)? ms' |
    stdbuf -oL -eL py -c "${py_precmd}" -x "${py_cmd}"
}

alias sd=sensible-diff

config-repo-grep-command() {
  local query
  query="$(printf '^\s*(\s*|[^#].*[^a-zA-Z0-9_-])%s([^a-zA-Z0-9_-]|$)' \
    "${1:-git}")"
  "${REPO_ROOT}/.my_scripts/sysadmin/list-config-repo-shell-scripts" |
    sensible-xargs "${_BEST_GREP[@]}" "${query}"
}

alias EX='exit'

# Get rid of the annoying "nohup.out" files.
nohup() {
  command nohup "$@" > /dev/null &
}

# As of 2021-03-14, the man command using vim has issues on Ubuntu 20.04: X11
# clipboard and tmux seamless navigation don't work. It may be related to the
# fact I'm running nvim as an AppImage.
man() {
  nvim -c ":vert Man $1 | silent bd 1"
}

detect-secrets-update-and-audit() {
  local baseline_file="${REPO_ROOT}/.config/detect-secrets/baseline.json"
  detect-secrets scan --update "${baseline_file}" || return
  local new_baseline
  new_baseline="$(jq '.exclude.files = "detect-secrets/baseline\\.json"' \
    "${baseline_file}")"
  printf '%s\n' "${new_baseline}" >| "${baseline_file}"
  detect-secrets audit "${baseline_file}"
}

# }}} Misc #

# Zsh specific  {{{
if is_zsh; then
  # run-help is aliased to man by default, which masks Zsh's built-in run-help
  # command.
  unalias run-help 2> /dev/null || true
  autoload -Uz run-help
  alias help=run-help

  _get_alias_value() {
    printf '%s\n' "${(v)aliases[$1]}"
    # For bash:
    printf '%s\n' "${BASH_ALIASES[$1]}"
  }
  _add_alias_prefix() {
    local prefix="$1"
    local alias_name="$2"
    if alias "${alias_name}" > /dev/null; then
      local alias_value
      alias_value="$(_get_alias_value "${alias_name}")"
      # shellcheck disable=SC2139,SC2140
      alias "${alias_name}"="${prefix} ${alias_value}"
    fi
  }
  _nocorrect_alias() {
    alias_name="$1"
    if alias "${alias_name}" > /dev/null; then
      alias_value="$(_get_alias_value "${alias_name}")"
      # shellcheck disable=SC2139,SC2140
      alias "${alias_name}"="nocorrect ${alias_value}"
    fi
  }

  # Don't try to correct me on the following
  for alias in c o v le; do
    _add_alias_prefix nocorrect "${alias}"
  done

  # NOTE: As of 2020-01-28, noglob is disabled because I find it annoying,
  # especially when trying to use globs to specify multiple files in the file
  # arguments.
  # _add_alias_prefix noglob rg
  # _add_alias_prefix noglob ag

  define_global_alias=(alias)
  if command_exists abbrev-alias; then
    define_global_alias=(abbrev-alias)
  fi
  define_global_alias+=(-g)
  # Global aliases for commands I currently use at the end of pipelines.
  "${define_global_alias[@]}" C='| xsel --input --clipboard'
  "${define_global_alias[@]}" C='| xsel --input --clipboard'
  "${define_global_alias[@]}" G='| rg'
  "${define_global_alias[@]}" GL='| rgl'
  "${define_global_alias[@]}" L="| less"
  "${define_global_alias[@]}" RL="| richpager --"
  "${define_global_alias[@]}" S='| sed -r '
  "${define_global_alias[@]}" XS='| sensible-xargs sed -i -r '
  "${define_global_alias[@]}" H="| head"
  "${define_global_alias[@]}" T="| tail"
  "${define_global_alias[@]}" TT="| prepend-time"
  "${define_global_alias[@]}" Y="| yank"
  "${define_global_alias[@]}" P="| py -x "
  "${define_global_alias[@]}" N='>/dev/null'
  "${define_global_alias[@]}" E='2>/dev/null'
  "${define_global_alias[@]}" NE='&>/dev/null'
  "${define_global_alias[@]}" PE='| pe | fzf --multi'
  # shellcheck disable=SC2016
  "${define_global_alias[@]}" PEE='PE | tr "\\n" " " | sensible-xargs "${EDITOR}" --'
  # Select a field using awk.
  "${define_global_alias[@]}" F1="| awk '{print \$1}'"
  "${define_global_alias[@]}" F2="| awk '{print \$2}'"
  "${define_global_alias[@]}" F3="| awk '{print \$3}'"
  "${define_global_alias[@]}" F4="| awk '{print \$4}'"
  "${define_global_alias[@]}" F5="| awk '{print \$5}'"
  "${define_global_alias[@]}" F6="| awk '{print \$6}'"
  "${define_global_alias[@]}" F7="| awk '{print \$7}'"
  "${define_global_alias[@]}" F8="| awk '{print \$8}'"
  "${define_global_alias[@]}" F9="| awk '{print \$9}'"

  # _expand_lbuffer_aliases() {
  #   local lbuffer_expanded
  #   LBUFFER="$(_expand_command_aliases "$LBUFFER")" && LBUFFER="${lbuffer_expanded}"
  # }
  # zle -N _expand_lbuffer_aliases
  #
  # _expand_aliases_space() {
  #     zle _expand_lbuffer_aliases
  #     zle self-insert
  # }
  # zle -N _expand_aliases_space
  #
  # _expand_aliases_enter() {
  #     zle _expand_lbuffer_aliases
  #     zle accept-line
  # }
  # zle -N _expand_aliases_enter
  #
  # _bindkey_insert_keymaps ' ' _expand_aliases_space
  # _bindkey_insert_keymaps '^M' _expand_aliases_enter
fi
# }}} Zsh  #
