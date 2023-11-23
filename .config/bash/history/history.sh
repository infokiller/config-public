# History functions shared by bash and zsh.
#
# Requires:
# - get_hostname
# - REPO_ROOT

_get_base_history_dir() {
  echo "${HOME}/.local/var/hist"
}

get_host_history_dir() {
  echo "${HOME}/.local/var/hist/$(get_hostname)"
}

histcat-list-decode() {
  cut -c 23- | sed -r 's/↵/\n/g'
}

_get_histcat_multihosts_cmd() {
  local this_hostname
  this_hostname="$(get_hostname)"
  local cmd=(histcat)
  while IFS='' read -r -d '' host_dir; do
    if [[ "$(basename "${host_dir}")" != "${this_hostname}" ]] &&
      [[ -d "${host_dir}/shell" ]]; then
      cmd+=("--extra-data-dir=${host_dir}/shell")
    fi
  done < <(find "$(_get_base_history_dir)" -mindepth 1 -maxdepth 1 -type d -print0)
  printf '%s\n' "${cmd[@]}"
}

# https://superuser.com/a/380778
_remove_escape_chars() {
  sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'
}

histcat-select() {
  local XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
  local histcat_cache_dir="${XDG_CACHE_HOME}/histcat"
  mkdir -p -- "${histcat_cache_dir}"
  local cache_file="${histcat_cache_dir}/fzf_preview_$$"
  # NOTE: The path variable in trap must be expanded when we run trap because if
  # it runs on EXIT the variable will not be defined.
  # shellcheck disable=SC2064
  trap "\rm -- '${cache_file}' &> /dev/null || true" ERR INT HUP EXIT TERM
  local preview_script="${REPO_ROOT}/.config/bash/history/fzf-preview"
  local selector=(
    'fzf-tmux' '-p' '80%' '--' '--scheme=history' '--reverse' '--no-sort' '--multi'
    '-n3..,..' '--ansi' '--bind=ctrl-r:toggle-sort' '--exact'
    "--preview=$(printf '%s %q {+}' "${preview_script}" "${cache_file}")" 
    '--preview-window=up:50%:hidden'
    '--bind=ctrl-t:toggle-preview'
  )
  local histcat_cmd=()
  while IFS='' read -r line; do
    histcat_cmd+=("$line")
  done < <(_get_histcat_multihosts_cmd)
  # NOTE: the name "status" can't be used in zsh because it's set to a readonly
  # variable with the value of $?.
  local s=0
  ("${histcat_cmd[@]}" list --max-entries 500000 |
    # Remove escape characters when piping to the file caching the list, otherwise
    # searching for a line that originally had newlines will fail.
    tee >(_remove_escape_chars > "${cache_file}") |
    "${selector[@]}" "$@" |
    histcat-list-decode) || s=$?
  \rm -- "${cache_file}" &> /dev/null
  # Delete files older than a week in case a previous cleanup was missed
  # (process was killed with -9, power loss, etc.).
  \find "${histcat_cache_dir}" -type f -mtime +7 -exec rm {} \;
  return $s
}

histcat-verify() {
  mkdir -p -- "$(get_host_history_dir)/shell"
  local histcat_dir="${SUBMODULES_DIR}/terminal/histcat"
  # TODO: Remove these checks after all machines are migrated.
  if [[ -e "$(_get_base_history_dir)/bash_history" ]]; then
    printf 'Migrating history\n'
    conda-run shell_history \
      "$HOME/.config/bash/history/migration-tool.py"
    while IFS='' read -r -d '' file; do
      printf 'Moving file %s to host directory\n' "${file}"
      mv "${file}" "$(get_host_history_dir)"
    done < <(find "$(_get_base_history_dir)" -mindepth 1 -maxdepth 1 -not -name "$(get_hostname)" -print0)
  fi
  if command_exists go && [[ ! -x "${histcat_dir}/histcat" ]]; then
    printf 'Building histcat\n'
    # TODO: Using `git submodule update` can change the checked out commit. We
    # should instead make sure it's initialized and checked out.
    (cd "${REPO_ROOT}" && git submodule update --init "${histcat_dir}")
    (cd "${histcat_dir}" && go build -v cmd/histcat/histcat.go)
  fi
  if ! command_exists histcat && [[ -x "${histcat_dir}/histcat" ]]; then
    ln -srf -- "${histcat_dir}/histcat" "${REPO_ROOT}/.local/bin/histcat"
  fi
}
