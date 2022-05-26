# TODO: Replace shebang with `# shellcheck shell=bash` in any non-executable
# scripts once the ALE PR is merged:
# https://github.com/dense-analysis/ale/pull/3216
# Functions and aliases for interactive use shared by bash and zsh.

# Make sure these variables are set.
# shellcheck disable=SC2296
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
# }}} ls 

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
  local dirs_up=()
  while dir="$(dirname -- "${dir}")"; do
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
# }}} Directory navigation 

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
# NOTE: -u can cause issues when an incomplete transfer occurs because sync
# wasn't called. For example, when using rsync to transfer file_a to file_b in a
# USB drive, and then removing the drive without sync, file_b will have a newer
# modification time, so a subsequent transfer will not do anything, even though
# file_b is not identical to file_a.
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

# }}} Files copying, moving, and deleting 

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
    return
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
  if [[ ($# -eq 1 && (-f $1 || -L $1 || -p $1)) || $# -gt 1 ]]; then
    less -- "$@"
    return
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
# }}} File opening 

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
# }}} Misc 

# }}} Files and directories 

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
  _BEST_GREP_CMD=('rg')
else
  _BEST_GREP_CMD=(grep -Ei)
fi
_best_grep() {
  "${_BEST_GREP_CMD[@]}" "$@"
}

ps2() {
  local extra_opts=("$@")
  if (($#==0)); then
    extra_opts=(--sort '-%cpu')
  fi
  command ps -e -o 'user,pid,ppid,etime,%cpu,rss,args' "${extra_opts[@]}" |
    numfmt --field 6 --from-unit 1024 --to iec --header=1 |
    # Print first ps fields (all except cmd) tab separated. Those fields can't
    # have whitespace in them so splitting them by whitespace will work. In
    # contrast, the cmd field may have whitespace in it so we don't want to
    # replace it with tabs because then the `column` command will treat every word
    # in the cmd as a separate column. I used to do this with sed but it became
    # cumbersome with multiple fields:
    # sed -r 's/(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/\1\t\2\t\3\t\4\t\5\t\6/' |
    awk '{
  for (i=1; i <= 6; i++) printf "%s\t", $i
  for (i=7; i <= NF; i++) printf "%s ", $i
  printf "\n"
}' | 
  column -t -s $'\t' | 
  # Limit the width of huge command lines
  cut -c -150
}
alias ps2-rss='ps2 --sort -rss'
alias pst='pstree -hpausST'
# Grep for a running process
grep-processes() {
  ps2 --no-headers | 
    # The spaces around ${_BEST_GREP_CMD[*]} are intentional: this way Xorg
      # won't match "rg".
    \grep -v --fixed-strings " ${_BEST_GREP_CMD[*]} " | 
    cut -c -120 |
    _best_grep "$@"
}
alias pg='grep-processes'
# Grep for an env variable
alias eg='env | _best_grep'
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

rgc() {
  (
    _cd_config_repo || return
    list-config-files | sensible-xargs -- "${_RG_OR_TAG}" --smart-case "$@"
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
rgci() {
  local preview
  export SUBMODULES_DIR
  preview="$(cat - <<'EOF'
  bash <<'EOF2'
  IFS=: read -r -a f <<<{}
  "${SUBMODULES_DIR}/vim/fzf-vim/bin/preview.sh" "${f[0]}:${f[1]}"
EOF2
EOF
  )"
  (
    _cd_config_repo || return
    local selected=()
    # Zsh doesn't support mapfile.
    local IFS=$'\n'
    # TODO: support changing the original search query?
    # TODO: use a unicode zero-width separator ('\xe2\x80\x8b' for utf8) in
    # addition to colons so that it works with files containing colons.
    # shellcheck disable=SC2207
    if ! selected=($(list-config-files | 
      sensible-xargs -- "${_RG_OR_TAG}" --smart-case -n --field-match-separator ':' "$@" | 
      fzf -m --toggle-sort=ctrl-r --preview-window=right:60% --exit-0 --preview="${preview}")) || 
      ((!${#selected[@]})); then
      return 1
    fi
    # TODO: open the files in the correct line number
    local files
    # Zsh doesn't support mapfile.
    # shellcheck disable=SC2207
    files=($(printf '%s\n' "${selected[@]}" | cut -d ':' -f 1 | sort -u))
    local editor="${EDITOR:-vim}"
    "${editor}" "${files[@]}"
  ) || return
}

rgc-todos() {
  rgc '\bTODO(:|\([a-zA-Z0-9_-]*\))' "$@"
}
rgcl-todos() {
  rgc-todos --color=always "$@" | less
}
rgc-exp() {
  rgc "$@" '\bEXP:'
}
rgcl-exp() {
  rgc-exp --color=always "$@" | less
}
# }}} Config search 
# }}} Search 

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
  local branch="${1:-master}"
  local is_dirty=0
  git-is-dirty && is_dirty=1
  if ((is_dirty)); then
    echo 'git-reset-hard-safe: repo is dirty, stashing changes'
    git stash push || return
  fi
  local branch_backup_name
  branch_backup_name="old-${branch}-$(uuidgen)"
  # Rename the existing branch
  git branch -m "${branch}" "${branch_backup_name}" || return
  git checkout -b "${branch}" "${branch_backup_name}" || return
  git branch --set-upstream-to="origin/${branch}" "${branch}" || return
  git reset --hard "origin/${branch}" || return
  # Not sure why, but git can delete a lot of repo files after a hard reset
  # which is needed when the history changed, so we restore them.
  git ls-files --deleted | sensible-xargs git checkout HEAD --
  if ((is_dirty)) && ! git stash pop; then
    print_error 'Could not apply stashed changes'
    return 1
  fi
}

# https://stackoverflow.com/a/12704727/1014208
get-remote-git-tags() {
  local remote="$1"
  git ls-remote --refs --tags "${remote}" |
    cut --delimiter='/' --fields=3 |
    grep -v -- '-rc' |
    tr '-' '~' |
    sort --version-sort
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
    # --others --exclude-standard adds untracked files
    "${_git_ls_unstaged_files[@]}" --others --exclude-standard |
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
    {
      # Concatenate the lists of staged and unstaged modified files. See also:
      # https://unix.stackexchange.com/a/176929/126543
      "${_git_ls_unstaged_files[@]}" "${repo_root}"
      "${_git_ls_staged_files[@]}"
    } | sort -u | fzf-shell --multi --preview="${_git_diff_head_preview}" "$@"
  )
}

git-restore-files() {
  if [[ ! -p /dev/stdin ]]; then
    print_error 'git-restore-files: expecting list of files in stdin'
    return 1
  fi
  local repo_root files
  repo_root="$(git rev-parse --show-toplevel)"
  # Zsh doesn't support mapfile.
  local IFS=$'\n'
  # shellcheck disable=SC2207
  files=($(</dev/stdin))
  if [[ -z ${files[*]} ]]; then
    return
  fi
  (
    cd -- "${repo_root}" || return
    printf 'Restoring files:\n'
    printf -- '- %s\n' "${files[@]}"
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

git-restore-files-fzf() {
  local files
  # Zsh doesn't support mapfile.
  local IFS=$'\n'
  # shellcheck disable=SC2207
  if ! files=($(_git_select_changed_files_fzf --prompt='Restore > ')) ||
    [[ -z ${files[*]} ]]; then
    return 1
  fi
  printf '%s\n' "${files[@]}" | git-restore-files
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

# Like env (the external command), but works in the current shell environment
# shenv() {
#   if (($# == 0)); then
#     env
#     return
#   fi
#   # Escape each argument so that we can
#   # https://github.com/koalaman/shellcheck/wiki/SC2294
#   local cmd_escaped=()
#   for arg in "$@"; do
#     cmd_escaped+=("$(printf '%q' "${arg}")")
#   done
#   eval "${cmd_escaped[*]}"
# }

gfexp() {
  if (($# == 0)); then
    export GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}"
    return
  fi
  eval GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" "$*"
}
gfrexp() {
  if (($# == 0)); then
    export GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}"
    return
  fi
  eval GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" "$*"
}

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

# Github/Gitlab {{{
gh-gist-select() {
  gh gist list --limit 100 | 
    column -t -s $'\t' | 
    fzf --preview='gh gist view {1}' | 
    awk '{print $1}'
}
gh-gist-edit() {
  local gist_id
  gist_id="$(gh-gist-select)" || return
  [[ -n "${gist_id}" ]] || return 1
  gh gist edit "${gist_id}"
}
# }}} Github/Gitlab

# NOTE(infokiller): I used to define the git aliases programmatically in this
# script, but it used eval which was bad for performance. Therefore, I'm now
# generating the aliases "offline" with the script generate_git_aliases.py and
# copy it to this file.

# Autogenerated git aliases {{{
# Generated by generate_git_aliases.py on 2021-04-12 05:40:40 UTC
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
alias 'gbv'='git branch -vv'
alias 'gfbv'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git branch -vv'
alias 'gfrbv'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git branch -vv'
alias 'gba'='git branch --all'
alias 'gfba'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git branch --all'
alias 'gfrba'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git branch --all'
alias 'gbav'='git branch --all -vv'
alias 'gfbav'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git branch --all -vv'
alias 'gfrbav'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git branch --all -vv'
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
alias 'grv'='git remote -v'
alias 'gfrv'='GIT_DIR="${PUBLIC_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git remote -v'
alias 'gfrrv'='GIT_DIR="${PRIVATE_CONFIG_GIT_DIR}" GIT_WORK_TREE="${HOME}" git remote -v'
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
# }}} Autogenerated git aliases 

## }}} Git 

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
# }}} Job management 

# Archlinux {{{
# I used to check for the existence of the pacman command, but it can yield a
# false positive because of the pacman game.
if [[ "${DISTRO-}" == arch ]]; then
  # shellcheck disable=SC2262,SC2032
  alias pacman='pacmate'
  alias pi='pacman -S'
  alias aur-update='yay -Syu --aur --answerclean=None --answeredit=All --answerdiff=All --noupgrademenu'
  alias arch-update-all='pacmate -Syu; aur-update'
  # This list used to have kmod and *-dkms packages, but based on the discussion
  # below they seem unnecessary:
  # https://bbs.archlinux.org/viewtopic.php?pid=1912472#p1912472
  _KERNEL_PACKAGES=(
    linux linux-lts linux-hardened linux-zen
    linux-headers linux-lts-headers linux-hardened-headers linux-zen-headers
    nvidia nvidia-dkms nvidia-lts nvidia-utils nvidia-settings
  )
  # shellcheck disable=SC2139
  alias arch-update-no-kernel='pacmate -Syu --ignore '"$(join_by ',' "${_KERNEL_PACKAGES[@]}")"'; aur-update'
  unset _KERNEL_PACKAGES
  pacman-pkg-files-fzf() {
    local pkg
    # shellcheck disable=SC2016,SC2263
    pkg="$(pacman -Qq |
      fzf --preview='pkg={}; pacman -Qi "${pkg}"; pacman -Qlq "${pkg}"')" ||
      return
    printf 'Package: %s\n\n' "${pkg}"
    # shellcheck disable=SC2263
    pacman -Qql "${pkg}" | tovim
  }
  pacman-pkg-description-fzf() {
    # shellcheck disable=SC2033,SC2016
    pacman -Qq | 
      fzf --preview='pkg={}; pacman -Qi "${pkg}"' | 
      xargs pacman -Qi | 
      grep -E '^Description' | 
      sed -E 's/^Description\s*:\s*(.*)/\1/'
  }
fi
# }}} Archlinux

# Debian {{{
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
# }}} Debian

# Systemd {{{
alias sc='systemctl'
alias scs='systemctl status'
alias scsys='systemctl --system'
alias scu='systemctl --user'
alias scus='systemctl --user status'
sclf() {
  echo Checking system services
  systemctl list-units --state=failed "$@"
  printf '\nChecking user services\n'
  systemctl --user list-units --state=failed "$@"
}
# I used to enable --pager-end but that implies -n1000 to guarantee that the
# pager will not buffer logs of unbounded size, which is confusing (since it
# makes it look like there's not many logs).
alias jc='journalctl -o short-iso-precise --since=-7d'
alias jcs='jc --boot=0 --lines=5000'
alias jcsys='jc --system'
alias jcu='jc --user'
# }}} Systemd 

# Clipboard {{{
strip-trailing-newline() {
  printf '%s' "$(</dev/stdin)";
}

alias xclip='xclip -selection c'
# Strip the trailing newline when copying by default to make it easier to paste
# inside text. Use `xcl` for keeping the newline.
alias xc='strip-trailing-newline | xclip'
alias xcl=xclip
alias cpwd='pwd | xclip' # pragma: allowlist secret

alias yank='yank -- xsel -b'
alias y='yank'
# }}} Clipboard 

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
# }}} Notifications 

# Tmux {{{
alias tmxcs='tmux-switch-session'
alias tmxdc='tmux-detach-client'
alias tmxks='tmux-kill-session'
alias tmxns='tmux new-session -A -s'

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
  local s=0
  if ((use_et)); then
    ssh-et "${ssh_args[@]}" -t "${cmd}" "${remote[*]}" || s=$?
  else
    ssh "${ssh_args[@]}" -t "${remote[*]}" "${cmd}" || s=$?
  fi
  _fix_terminal_after_ssh_tmux && return $s
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
  local s=0
  if ((use_et)); then
    ssh-et "${ssh_args[@]}" -t "${cmd}" "${remote[*]}" || s=$?
  else
    ssh "${ssh_args[@]}" -t "${remote[*]}" "${cmd}" || s=$?
  fi
  _fix_terminal_after_ssh_tmux && return $s
}
alias ssh-tmxcs='_ssh-tmxcs 0'
alias ssh-tmxns='_ssh-tmxns 0'
alias ssh-et-tmxcs='_ssh-tmxcs 1'
alias ssh-et-tmxns='_ssh-tmxns 1'

# Reads bash shell commands from a file and runs them from tmux
ssh-xpanes-script() {
  if (($# < 2)); then
    print_error 'Usage: ssh-xpanes-script SCRIPT REMOTE...'
    return 1
  fi
  src="$(printf '%s' "$(<"$1")")"
  printf 'Running bash commands:\n%s\n' "${src}"
  # Quote the source to pass it as a shell argument
  src="$(printf '%q' "${src}")"
  # We can pipe the script to ssh which will forward it to bash, but the problem
  # with that approach is that stdin of bash is no longer connected to the
  # terminal, which means that things like sudo and terminal pin entries won't
  # work.
  # To avoid this issue (and trying to figure out how to restore stdin to the
  # terminal) We pass the source as an argument and then eval it.
  local main='eval "$*"'
  # Quote twice, because both SSH and tmux-xpanes seem to split words.
  main="$(printf '%q' "$(printf '%q' "${main}")")"
  # NOTE: The space before the ssh command is intentional- it avoids saving the
  # command in the shell history (which can get very long because of src).
  tmux-xpanes -t -c " ssh -t {} bash -c ${main} my-ssh-script ${src}" "${@:2}"
}

# # Accepts shell commands in stdin and passes them to ssh in tmux-xpanes
# ssh-xpanes-stdin() {
#   # I already wasted too much time fighting with tmux-xpanes to make this work,
#   # so I'm using ssh-xpanes-script for now.
#   if (($# < 1)); then
#     print_error 'Usage: cmd | ssh-xpanes-stdin [XPANES_ARGS] REMOTE...'
#     return 1
#   fi
#   if [[ ! -t 1 ]]; then
#     print_error 'ssh-xpanes-stdin: stdout must be connected to tty'
#     return 1
#   fi
#   local src s=0
#   read -r -d '' -t 1 src || s=$?
#   if [[ -z "${src}" ]]; then
#     print_error 'ssh-xpanes-stdin: expecting standard input'
#     return 1
#   fi
#   printf '# Script start\n%s\n# Script end\n' "${src}"
#   # NOTE: Restore stdin to terminal?
#   # exec &</dev/tty
#   # Quote the source to pass it as a shell argument
#   src="$(printf '%q' "${src}")"
#   # We can pipe the script to ssh which will forward it to bash, but the problem
#   # with that approach is that stdin of bash is no longer connected to the
#   # terminal, which means that things like sudo and terminal pin entries won't
#   # work.
#   # To avoid this issue (and trying to figure out how to restore stdin to the
#   # terminal) We pass the source as an argument and then eval it.
#   local main='eval "$*"'
#   # Quote twice, because both SSH and tmux-xpanes seem to split words.
#   main="$(printf '%q' "$(printf '%q' "${main}")")"
#   # main="$(printf '%q' "${main}")"
#   # We must redirect the stdin of tmux-xpanes to the tty so that it doesn't use
#   # "pipe mode" (see tmux-xpanes docs).
#   local tty
#   tty="$(tty)" || tty="/dev/$(ps --no-headers -o 'tty' $$)" || {
#     echo 'No TTY detected'
#     return 1
#   }
#   echo "Detected TTY: ${tty}"
#   tmux-xpanes -t -c "ssh -t {} bash -c ${main} my-ssh-script ${src}" "$@" < "${tty}"
#   # for host in "$@"; do
#   #   ssh -t "${host}" bash -c "${main}" my-ssh-script "${src}" < "${tty}"
#   # done
#   # local script
#   # script="$(mktemp -t 'a.XXXXXXXX')"
#   # cat - >> "${script}"
#   # # We must redirect the stdin of tmux-xpanes to the tty so that it doesn't use
#   # # "pipe mode" (see tmux-xpanes docs).
#   # tmux-xpanes -t -c "ssh {} -t bash -s < $(printf '%q' "${script}")" "$@"
#   # tmux-xpanes -t -c "ssh -t {} zsh -c ${quoted_cmds}" "$@" < /dev/tty
# }
# }}} Tmux 

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
alias ipy='hash -r && EDITOR=vim-in-ipython ipython'
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
alias pyd='conda deactivate'

# https://github.com/infokiller/pythonpy
# Formerly:
# https://github.com/Russell91/pythonpy
alias py='PYTHONPATH="${SUBMODULES_DIR}/terminal/pythonpy" conda-run pythonpy "${SUBMODULES_DIR}/terminal/pythonpy/main.py"'
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
# }}} Python 

# Docker {{{ #
alias db='docker build'
# Using "-it" instead of "--interactive --tty" causes the zsh completions to
# complete external commands instead of docker images.
alias dr='docker run --rm --interactive --tty --init'
# }}} Docker #

# Bazel {{{ #
# Run Bazel in a container. There is an official container [1] but as of
# 2021-11-12 it doesn't support Bazel 4.0+.
# [1] https://docs.bazel.build/versions/main/bazel-container.html
# TODO: support specifying the bazel version using .bazeliskrc or .bazelversion
# which are used by bazelisk:
# https://github.com/bazelbuild/bazelisk#how-does-bazelisk-know-which-bazel-version-to-run
_build_bazel_oci_image() {
  if [[ -z "${USE_BAZEL_VERSION-}" ]]; then
    USE_BAZEL_VERSION="$(get-remote-git-tags https://github.com/bazelbuild/bazel |
      grep -v '~' | tail -1)"
  fi
  if [[ -z "${BAZELISK_VERSION-}" ]]; then
    BAZELISK_VERSION="$(get-remote-git-tags 'https://github.com/bazelbuild/bazelisk' |
      tail -1)"
  fi
  local build_args=(
    --build-arg="BAZEL_DIR=${BAZEL_DIR:-/bazel}"
    --build-arg="USE_BAZEL_VERSION=${USE_BAZEL_VERSION}"
    --build-arg="BAZELISK_VERSION=${BAZELISK_VERSION}"
  )
  docker build "${build_args[@]}" "$@" - << 'EOF'
  FROM debian:11
  # To build the python interpreter from source:
  # https://devguide.python.org/setup/#linux
  # https://superuser.com/a/1412976/407543
  # https://realpython.com/installing-python/#step-2-prepare-your-system
  RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NOWARNINGS=yes && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
      -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" \
      curl ca-certificates build-essential golang \
      build-essential gdb lcov pkg-config \
      libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
      libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
      lzma lzma-dev tk-dev uuid-dev zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/python3 /usr/bin/python
  ARG BAZEL_DIR=/bazel
  RUN useradd --create-home --home-dir="${BAZEL_DIR}" --user-group bazel
  USER bazel
  # Bazel uses TEST_TMPDIR for the output directory:
  # https://docs.bazel.build/versions/main/output_directories.html
  # ENV TEST_TMPDIR=${BAZEL_DIR}/output
  ARG BAZELISK_VERSION
  RUN curl -fsSL "https://github.com/bazelbuild/bazelisk/releases/download/$BAZELISK_VERSION/bazelisk-linux-amd64" \
    -o "${BAZEL_DIR}/bazel" && chmod a+x "${BAZEL_DIR}/bazel"
  # Run bazelisk once to download and cache bazel in the image
  ARG USE_BAZEL_VERSION
  ENV USE_BAZEL_VERSION=${USE_BAZEL_VERSION}
  RUN "${BAZEL_DIR}/bazel" version
  ENTRYPOINT ["/bazel/bazel"]
EOF
}
bazel-in-docker() {
  : "${BAZEL_DIR:=/bazel}"
  local nproc
  nproc="$(nproc)" || return
  local image_id
  image_id="$(_build_bazel_oci_image -q -t bazel)"
  # https://docs.bazel.build/versions/main/output_directories.html#current-layout
  local host_cache_dir="${XDG_CACHE_HOME}/bazel/_bazel_${USER}"
  # local container_cache_dir="${BAZEL_DIR}/.cache/bazel/_bazel_bazel"
  local docker_run_opts=(
    --rm -it
    --cpus="$((nproc - 4))" --memory=8g
    -u="$(id -u)"
    --volume="${host_cache_dir}:${host_cache_dir}"
    --volume="${PWD}:${PWD}"
    --workdir="${PWD}"
  )
  # NOTE: running the a python binary may fail because the python from the host
  # (usually from a virtualenv) is different from the python used in the build,
  # which can cause issues with libraries like numpy.
  # The best solution is to build the python interpreter from source in bazel,
  # and then both the build and run will use the same interpreter..
  docker run "${docker_run_opts[@]}" "${image_id}" --output_user_root="${host_cache_dir}" "$@"
}
alias bid=bazel-in-docker
# }}} Bazel #

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

# }}} GPUs 

# List all commands {{{
# list-commands outputs the list of all "commands"- binaries, shell functions,
# and shell builtins.
list-commands() {
  local shell_type
  shell_type="$(get_shell_type)" || return
  eval "_list_commands_${shell_type}" | \grep --text -v '^_'
}

_list_commands_bash() {
  compgen -A function -bc
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
# }}} List all commands 

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
  for ((i = 0; i < num_runs; i++)); do
    eval -- "$*" > /dev/null
  done
  local after
  after=$(($(date +%s%N) / 1000000))
  local per_run
  per_run=$(bc < <(printf 'scale=2; %d/%d\n' $((after - before)) "${num_runs}"))
  print_bold "${per_run} ms per run ($((after - before)) ms total)"
}
alias bm='benchmark-command'

# rif is now a regular executable to make it easier to type when executing it
# via SSH and other contexts in which we can't run aliases directly.
# alias rif='run-interactive-function'
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

# Works for both libvirt and quickemu ones
qemu-ls() {
  pgrep -f '.*/bin/qemu-system-.*' | 
    xargs ps -o command= | 
    sed -E 's%.*bin/qemu.* -name[ =](guest=)?([^ ,]+).*$%\2%'
}

# https://github.com/dylanaraps/pure-bash-bible#strip-pattern-from-end-of-string
rstrip() {
    # Usage: rstrip "string" "pattern"
    printf '%s\n' "${1%%"$2"}"
}

quickemu-vm-dir() {
  if (($# != 1)); then
    print_error 'Usage: quickemu-vm-dir <VM_CONF_PATH>'
    return 1
  fi
  local vm_conf="$1"
  # Run in subshell to avoid modifying the global envrionment
  printf '%s' "$(
    # shellcheck disable=SC1090
    source -- "${vm_conf}" || return
    if [[ -z "${disk_img-}" ]]; then
      print_error "disk_img not set in ${vm_conf}"
      return 1
    fi
    local disk_img_dir
    disk_img_dir="$(dirname -- "${disk_img}")" || return 1
    if [[ ! -d "${disk_img_dir}" ]]; then
      print_error "disk_img dir does not exist: ${disk_img_dir}"
      return 1
    fi
    if [[ "${disk_img:0:1}" == /* ]]; then

      dirname -- "${disk_img}"
      return
    fi
    local vm_conf_dir
    vm_conf_dir="$(dirname -- "${vm_conf}")" || return 1
    printf '%s/%s' "${vm_conf_dir}" "${disk_img_dir}"
  )"
}

quickemu-port() {
  if (($# < 1 || $# > 2)); then
    print_error 'Usage: quickemu-port <VM_CONF_PATH> [<PORT_NAME>]'
    return 1
  fi
  local vm_conf="$1"
  local port_name="${2-}"
  local vm_name
  vm_name="$(rstrip "$(basename -- "${vm_conf}")" .conf)"
  local vm_dir
  # Run in subshell to avoid modifying the global envrionment
  vm_dir="$(quickemu-vm-dir "${vm_conf}")" || return
  local vm_ports="${vm_dir}/${vm_name}.ports"
  if [[ -n "${port_name}" ]]; then
    grep "^${port_name}," "${vm_ports}" | cut -d, -f2
    return
  fi
  cat -- "${vm_ports}"
}

spicy-quickemu() {
  if (($# < 1)); then
    print_error 'spicy-quickemu: missing arguments'
    return 1
  fi
  local vm_conf="$1"
  local vm_dir
  # Run in subshell to avoid modifying the global envrionment
  vm_dir="$(quickemu-vm-dir "${vm_conf}")" || return
  local vm_name
  vm_name="$(rstrip "$(basename -- "${vm_conf}")" .conf)"
  local spice_port
  spice_port="$(quickemu-port "${vm_conf}" spice)"
  spicy --title "${vm_name}" --port "${spice_port}" --spice-shared-dir ~/media/public "${@:2}"
}

alias ssh-tmp='ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'

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
  local get_con="nmcli con show --active | \grep --text -Ev '(vpn|bridge|tun)' | tail -1 | awk '{print \$1}'"
  local py_precmd
  py_precmd="$(printf 'get_con = lambda: subprocess.check_output("%s", shell=True).decode("utf-8").strip()' "${get_con}")"
  py_cmd='print(f"{datetime.datetime.now()}: {get_con()}: {x}", flush=True)'
  # Without using stdbuf the output buffering causes lines to be output after a
  # large delay.
  local s=0
  {
    while true; do
      s=0
      timeout 3 ping -c 1 "${1:-1.1}" 2>&1 || s=$?
      ((s == 124)) && echo 'ping command timed out'
      sleep 1
    done
  } |
    stdbuf -oL -eL grep --text -E -v \
      -e 'time=[0-2]?[0-9]{1,2}(\.[0-9]+)? ms' \
      -e 'PING|ping statistics|packets transmitted|rtt min/avg|^\s*$' |
    stdbuf -oL -eL rif py -c "${py_precmd}" -x "${py_cmd}"
}

alias sd=sensible-diff

config-repo-grep-command() {
  (
    _cd_config_repo || return
    local query
    query="$(printf '^\s*(\s*|[^#].*[^a-zA-Z0-9_-])%s([^a-zA-Z0-9_-]|$)' \
      "${1:-git}")"
    "${REPO_ROOT}/.my_scripts/sysadmin/list-config-repo-shell-scripts" |
      sensible-xargs "${_BEST_GREP_CMD[@]}" "${query}"
  ) || return
}

upgrade-local-packages() {
  "${REPO_ROOT}/install/install-crossdistro-local-packages" upgrade --all --parallel && {
    for sub in $(git diff-index --name-only HEAD | rg '^submodules/.*(keydope|i3-workspace-groups|i3-scratchpad|selfspy)$'); do
      (
        cd -- "${sub}" && git status
        if [[ -n "$(git diff-index --name-only --ignore-submodules=all --diff-filter=AM HEAD '*requirements*')" ]]; then
          git add -- '*requirements*' && git commit -m 'update deps'
        fi
      )
    done
  }
}

alias EX='exit'

# Get rid of the annoying "nohup.out" files.
nohup() {
  command nohup "$@" > /dev/null &
}

# NOTE: This function is disabled because it breaks calling the man command with
# options, such as "man -k '^printf'". I'm not sure why I needed this function
# in the first place, since vim/nvim will be used as the pager anyway when
# setting MAN_PAGER. 
# As of 2021-03-14, the man command using vim has issues on Ubuntu 20.04: X11
# clipboard and tmux seamless navigation don't work. It may be related to the
# fact I'm running nvim as an AppImage.
# man() {
#   nvim -c ":vert Man $* | silent bd 1"
# }
# https://github.com/kristopolous/mansnip
alias ms='mansnip'

detect-secrets-update-and-audit() {
  local baseline_file="${REPO_ROOT}/.config/detect-secrets/baseline.json"
  detect-secrets scan --update "${baseline_file}" || return
  local new_baseline
  new_baseline="$(jq '.exclude.files = "detect-secrets/baseline\\.json"' \
    "${baseline_file}")"
  printf '%s\n' "${new_baseline}" >| "${baseline_file}"
  detect-secrets audit "${baseline_file}"
}

ocr-screenshot() {
  local tmpdir
  tmpdir="$(mktemp -d -t 'screenshot_ocr.XXXXXX')"
  maim -s > "${tmpdir}/ss.png" 
  # Pipe stderr to /dev/null to avoid the line "Estimating resolution as..."
  tesseract "$@" "${tmpdir}/ss.png" "${tmpdir}/ocr" 2> /dev/null
  cat -- "${tmpdir}/ocr.txt"
}

ocr-screenshot-app() {
  local text
  text="$(ocr-screenshot "$@")"
  if [[ -z "${text}" ]]; then
    return 1
  fi
  local tmpfile
  printf '%s' "${text}" >| "${tmpfile}"
  if sensible-terminal --window-name vim-ocr -- \
    vim -c 'set filetype=text textwidth=0 wrapmargin=0' "${tmpfile}"; then
    xclip -selection clipboard < "${tmpfile}"
  fi
}

# }}} Misc 

# Private includes {{{
if [[ -r "${REPO_ROOT}/.config/bash/functions_private.sh" ]]; then
  # shellcheck source=../../.config/bash/functions_private.sh
  source "${REPO_ROOT}/.config/bash/functions_private.sh" 
fi
# }}} Private includes
