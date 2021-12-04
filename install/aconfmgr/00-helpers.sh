# shellcheck shell=bash

AconfNeedProgram dmidecode dmidecode n
AconfNeedProgram lshw lshw n
AconfNeedProgram git git n
AconfNeedProgram grep grep n
AconfNeedProgram awk gawk n
AconfNeedProgram id coreutils n
AconfNeedProgram jq jq n

# shellcheck disable=SC2155
readonly REPO_ROOT="$([[ ${CONFIG_GET_ROOT:-0} == 1 ]] && config-repo-root "${BASH_SOURCE[0]}" || echo "${HOME}")"
# shellcheck disable=SC2034
readonly SUBMODULES_DIR="${REPO_ROOT}/submodules"
# shellcheck disable=SC2034
readonly ACONF_LIB="${REPO_ROOT}/install/aconfmgr/lib"
# shellcheck disable=SC2034
readonly PRIVATE_CONFIG_GIT_DIR="${HOME}/.local/var/git_dirs/config-private"
# shellcheck source=../../.my_scripts/lib/platform_detection.sh
source "${REPO_ROOT}/.my_scripts/lib/platform_detection.sh"
# shellcheck source=../../install/setup_installation_env
source "${REPO_ROOT}/install/setup_installation_env"

command_exists() {
  command -v -- "$1" &> /dev/null
}

function_exists() {
  declare -f -- "$1" > /dev/null
}

print_warning() {
  local warning normal
  # Yellow color
  warning="$(tput setaf 3 2> /dev/null)" || true
  normal="$(tput sgr0 2> /dev/null)" || true
  printf >&2 '%s\n' "${warning}${*}${normal}"
}

prepend_to_file() {
  local file="$1"
  local content
  content="$(printf '%s\n' "${@:2}")"
  printf '%s\n%s' "${content}" "$(<"${file}")" >| "${file}"
}

# When using CopyFile on a symlink, aconfmgr will copy the symlink. This forces
# it to copy the file content.
CopySymlinkAsFile() {
  # shellcheck disable=SC2154
  cat -- "${config_dir}/files/$1" > "$(CreateFile "$1")"
}
