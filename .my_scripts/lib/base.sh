# Library with functionality common to many bash/zsh scripts.
# It should not depend on any other script other than config-repo-root.

if [[ -n "${__sh_base_loaded-}" ]]; then
  return
fi
__sh_base_loaded=1

is_bash() {
  [[ -n "${BASH_VERSION-}" ]]
}

is_zsh() {
  [[ -n "${ZSH_VERSION-}" ]]
}

# Based on:
# https://github.com/dylanaraps/pure-bash-bible#get-the-directory-name-of-a-file-path
# Used instead of the dirname binary for performance.
# Changes:
# - Support a double dash argument
dirname() {
    if [[ $1 == -- ]]; then
      shift
    fi
    local tmp=${1:-.}

    [[ $tmp != *[!/]* ]] && {
        printf '/\n'
        return
    }

    tmp=${tmp%%"${tmp##*[!/]}"}

    [[ $tmp != */* ]] && {
        printf '.\n'
        return
    }

    tmp=${tmp%/*}
    tmp=${tmp%%"${tmp##*[!/]}"}

    printf '%s\n' "${tmp:-/}"
}

print_bold() {
  local bold normal
  bold="$(tput bold 2> /dev/null)" || true
  normal="$(tput sgr0 2> /dev/null)" || true
  printf '%s' "${bold}"
  printf '%s' "${@}"
  printf '%s\n' "${normal}"
}

print_warning() {
  local warning normal
  # Yellow color
  warning="$(tput setaf 3 2> /dev/null)" || true
  normal="$(tput sgr0 2> /dev/null)" || true
  printf >&2 '%s\n' "${warning}${*}${normal}"
}

print_error() {
  local error normal
  # Red color
  error="$(tput setaf 1 2> /dev/null)" || true
  normal="$(tput sgr0 2> /dev/null)" || true
  printf >&2 '%s\n' "${error}${*}${normal}"
}

command_exists() {
  command -v -- "$1" &> /dev/null
}

function_exists() {
  declare -f "$1" > /dev/null
}

# From: https://stackoverflow.com/a/17841619/10142j8
join_by() {
  local IFS="$1"
  shift
  printf '%s\n' "$*"
}
