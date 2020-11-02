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

# shellcheck disable=SC2016,SC1004
# TODO: Consider using a separate preview process that communicates with the
# preview script using a fifo file, which should improve performance by
# eliminating any latency in starting the preview process. For an example see:
# ~/.config/ipython/profile_default/startup/10-keybindings.py
_HISTCAT_FZF_PREVIEW_SCRIPT='
histcat_list_output_path=%q
rg --text --context=5 --fixed-strings --file={+f} < "${histcat_list_output_path}" |
  cut -c 23- |
  highlight --force=sh --out-format=truecolor --quiet
'

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

histcat-select() {
  local XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
  local histcat_cache_dir="${XDG_CACHE_HOME}/histcat"
  mkdir -p -- "${histcat_cache_dir}"
  local histcat_list_output_path="${histcat_cache_dir}/fzf_preview_$$"
  # NOTE: The path variable in trap must be expanded when we run trap because if
  # it runs on EXIT the variable will not be defined.
  # shellcheck disable=SC2064
  trap "\rm -- '${histcat_list_output_path}' &> /dev/null || true" ERR INT HUP EXIT TERM
  local preview_script
  # shellcheck disable=SC2059
  preview_script="$(printf "${_HISTCAT_FZF_PREVIEW_SCRIPT}" \
    "${histcat_list_output_path}")"
  local selector=(fzf '--height=40%' '--reverse' '--no-sort' '--multi'
    '-n3..,..' '--ansi' '--bind=ctrl-r:toggle-sort' '--exact'
    "--preview=${preview_script}" '--preview-window=up:30%:hidden'
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
    tee "${histcat_list_output_path}" |
    "${selector[@]}" "$@" |
    histcat-list-decode) || s=$?
  \rm -- "${histcat_list_output_path}" &> /dev/null
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
    (cd "${REPO_ROOT}" && git submodule update --init "${histcat_dir}")
    (cd "${histcat_dir}" && go build -v cmd/histcat/histcat.go)
  fi
  if ! command_exists histcat && [[ -x "${histcat_dir}/histcat" ]]; then
    ln -srf -- "${histcat_dir}/histcat" "${REPO_ROOT}/.local/bin/histcat"
  fi
}
