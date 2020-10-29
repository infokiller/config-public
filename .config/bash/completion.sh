#!/usr/bin/env bash
# Completion functions shared by bash and zsh.
#
# Requires:
# - SUBMODULES_DIR
# - is_bash

# shellcheck disable=SC1091
_add_local_gcloud_completions() {
  local gcloud_sdk_dir="${HOME}/.local/pkg/standalone/google-cloud-sdk"
  if [[ ! -d ${gcloud_sdk_dir} ]]; then
    return 1
  fi
  if is_zsh; then
    # shellcheck source=../../.local/pkg/standalone/google-cloud-sdk/path.zsh.inc
    source "${gcloud_sdk_dir}/completion.zsh.inc"
  elif is_bash; then
    # shellcheck source=../../.local/pkg/standalone/google-cloud-sdk/path.bash.inc
    source "${gcloud_sdk_dir}/completion.bash.inc"
  fi
  return 0
}

_add_gcloud_completions() {
  if _add_local_gcloud_completions; then
    return
  fi
  # gcloud bash completion.
  local _system_gcloud_completion_paths=(/etc/bash_completion.d/gcloud)
  for p in "${_system_gcloud_completion_paths[@]}"; do
    # shellcheck disable=SC1090
    source "${p}" &> /dev/null
  done
}

_ppa_lists() {
  local cur
  if [[ -n ${BASH_VERSION-} ]]; then
    _init_completion || return
  fi
  mapfile -t COMPREPLY < <(find /etc/apt/sources.list.d/ -name "*${cur}*.list" \
    -exec basename {} \; 2> /dev/null)
  return 0
}

# https://github.com/donnemartin/gitsome/blob/master/scripts/gh_complete.sh
# shellcheck disable=SC2207,SC2086
_gh_completion() {
  COMPREPLY=($(env COMP_WORDS="${COMP_WORDS[*]}" \
    COMP_CWORD=$COMP_CWORD \
    _GH_COMPLETE=complete $1))
  return 0
}

_add_completions() {
  _add_gcloud_completions
  # shellcheck source=../../submodules/hostsctl/hostsctl.bash-completion
  source "${SUBMODULES_DIR}/hostsctl/hostsctl.bash-completion"
  if [[ -d /etc/apt/sources.list.d/ ]]; then
    # NOTE: This must be kept in sync with ~/.config/bash/functions.sh
    complete -F _ppa_lists apt-update-repo
  fi
  # NOTE: In zsh this used to only works if sourced after compinit. It's unused
  # for now, but if I enable it again I should test it.
  # complete -F _gh_completion -o default gh;
}

_add_completions
