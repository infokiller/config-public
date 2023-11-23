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

# TODO: Consider using a separate preview process that communicates with the
# preview script using a fifo file, which should improve performance by
# eliminating any latency in starting the preview process. For an example see:
# ~/.config/ipython/profile_default/startup/10-keybindings.py
IFS='' read -r -d '' _HISTCAT_FZF_PREVIEW_SCRIPT << 'EOF'
  lines=({+})
  highlight_cmd=(bat --color=always --paging=never '--wrap=character' 
    "--terminal-width=${FZF_PREVIEW_COLUMNS}" '--language=sh' '--highlight-line=4')
  is_multi_select=$((${#lines[@]} > 1))
  if ((is_multi_select)); then
    highlight_cmd+=(--style=grid,header)
  else
    highlight_cmd+=(--style=plain)
  fi
  for line in "${lines[@]}"; do
    matches=()
    while IFS='' read -r match; do
      matches+=("${match}")
    done < <(rg --text --context=3 --fixed-strings "${line}" < "${histcat_list_output_path}")
    if ((${#matches[@]} == 0)); then
      echo "ERROR: no matches for line: ${line}"
      continue
    fi
    # When there are multiple lines we need to match, print the datetime of the first
    # line so we can see the context.
    extra_args=()
    if ((is_multi_select)); then
      first_match="${matches[@]:0:1}"
      extra_args+=('--file-name' "${first_match:0:20}")
      # printf '# %s\n' "${first_match:0:20}"
    fi
    printf '%s\n' "${matches[@]}" |
      cut -c 23- |
      "${highlight_cmd[@]}" "${extra_args[@]}"
  done 
EOF

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
  local histcat_list_output_path="${histcat_cache_dir}/fzf_preview_$$"
  # NOTE: The path variable in trap must be expanded when we run trap because if
  # it runs on EXIT the variable will not be defined.
  # shellcheck disable=SC2064
  trap "\rm -- '${histcat_list_output_path}' &> /dev/null || true" ERR INT HUP EXIT TERM
  local preview_script
  preview_script="$(printf 'histcat_list_output_path=%q\n%s' "${histcat_list_output_path}" "${_HISTCAT_FZF_PREVIEW_SCRIPT}")"
  local selector=(
    'fzf-tmux' '-p' '80%' '--' '--scheme=history' '--reverse' '--no-sort' '--multi'
    '-n3..,..' '--ansi' '--bind=ctrl-r:toggle-sort' '--exact'
    "--preview=${preview_script}" '--preview-window=up:50%:hidden'
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
    tee >(_remove_escape_chars > "${histcat_list_output_path}") |
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
    # TODO: Using `git submodule update` can change the checked out commit. We
    # should instead make sure it's initialized and checked out.
    (cd "${REPO_ROOT}" && git submodule update --init "${histcat_dir}")
    (cd "${histcat_dir}" && go build -v cmd/histcat/histcat.go)
  fi
  if ! command_exists histcat && [[ -x "${histcat_dir}/histcat" ]]; then
    ln -srf -- "${histcat_dir}/histcat" "${REPO_ROOT}/.local/bin/histcat"
  fi
}
