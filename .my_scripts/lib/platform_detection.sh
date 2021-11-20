# Library for detecting platform features, such as the Linux distro, CPU
# model, etc.
# This library should be compatible with both bash and zsh.

if [[ -n "${__sh_platform_detection_loaded-}" ]]; then
  return
fi
__sh_platform_detection_loaded=1

# NOTE: We intentionally only set these variables if they're not already set so
# that if they are readonly there won't be an error.
: "${REPO_ROOT:=$(config-repo-root "${BASH_SOURCE[0]:-${(%):-%x}}" 2> /dev/null || echo "${HOME}")}"
: "${SUBMODULES_DIR:=${REPO_ROOT}/submodules}"
# Detect distro- see https://unix.stackexchange.com/a/6348
# NOTE: The nixpkgs/nix-flakes docker image doesn't have /etc/os-release.
: "${DISTRO:=$(. /etc/os-release 2> /dev/null && printf '%s\n' ${ID})}"

# https://kerneltalks.com/linux/all-you-need-to-know-about-hostname-in-linux/
# Another alternative is to use ${HOST} in zsh or ${HOSTNAME} in bash.
get_hostname() {
  cat /proc/sys/kernel/hostname
}

is_uefi() {
  [[ -d /sys/firmware/efi ]]
}

# Check if laptop- see also https://superuser.com/a/877796/407543
is_laptop() {
  sudo dmidecode --string chassis-type |
    grep -Eq '(Laptop|Notebook|Portable|Sub Notebook)'
}

# See full list of chassis types here:
# https://technet.microsoft.com/en-us/library/ee156537.aspx
is_desktop() {
  sudo dmidecode --string chassis-type | grep -Eq '(Desktop|Tower)'
}

is_intel_cpu() {
  grep 'vendor' /proc/cpuinfo | grep -q Intel
}

get_gpu_vendors() {
  lshw -C display 2> /dev/null | 
    grep --text vendor | 
    sed -E 's/^\s+vendor:\s*//'
  # Alternative:
  # lshw -json -C display | jq -r '.[0] | .configuration.driver'
  # Alternative:
  # lspci | grep -e VGA -e 3D
}

is_intel_gpu() {
  get_gpu_vendors | grep -iq intel
}

is_amd_gpu() {
  get_gpu_vendors | grep -iq -e 'AMD' -e 'Advanced Micro Devices'
}

is_nvidia_gpu() {
  get_gpu_vendors | grep -iq nvidia
}

# Enables private/local overrides.
is_primary_dev_machine() {
  true
}

# Enables private/local overrides.
is_personal_device() {
  true
}

# https://github.com/microsoft/WSL/issues/423#issuecomment-221514627
# https://github.com/microsoft/WSL/issues/4555#issuecomment-700213318
is_wsl() {
  [[ -n "${WSL_DISTRO_NAME-}" ]] || [[ "$(< /proc/version)" == *[Mm]icrosoft* ]]
}

is_wsl1() {
  is_wsl && (! is_wsl2)
}

is_wsl2() {
  is_wsl || return 1
  # https://github.com/microsoft/WSL/issues/4555#issuecomment-700213318
  if [[ -n "${WSL_DISTRO_NAME-}" ]]; then
    [[ -n "${WSL_INTEROP-}" ]] && return 0 || return 1
  fi
  # https://github.com/microsoft/WSL/issues/4555#issuecomment-539674785
  local gcc_major_version
  gcc_major_version="$(grep --text -oE 'gcc version ([0-9]+)' /proc/version | 
    awk '{print $3}')"
  ((gcc_major_version > 5))
}

is_using_systemd() {
  ! is_wsl
}

is_nvidia_dgx() {
  [[ -f /etc/dgx-release ]]
}

uses_local_graphics() {
  ! is_wsl1 && ! is_nvidia_dgx
}

# Enables private/local overrides.
_get_local_optional_submodules() {
  true
}

# Returns the git pathspec for optional submodules that are relevant to the
# environment.
get_optional_submodules_pathspec() {
  # The neovim submodule is required because vscode-neovim requires neovim 0.5,
  # which is not released yet.
  local platform_submodules=()
  while IFS= read -r submodule; do
    platform_submodules+=("${submodule}")
  done < <(_get_local_optional_submodules)
  case "${DISTRO}" in
    *buntu | debian)
      platform_submodules+=(tmux)
      ;;
    arch)
      platform_submodules+=(aconfmgr pacmate)
      ;;
    *)
      _log_error "Unsupported distro: ${DISTRO}"
      return 1
      ;;
  esac
  local valid_submodules=()
  for sm in "${platform_submodules[@]}"; do
    local dir="${SUBMODULES_DIR}/optional/${sm}"
    if [[ -n "$(git ls-files "${dir}")" ]]; then
      valid_submodules+=("${dir}")
    fi
  done
  if ((${#valid_submodules[@]})); then
    printf '%s\n' "${valid_submodules[@]}"
  fi
}

if [ -r "${REPO_ROOT}/.my_scripts/lib/platform_detection_private.sh" ]; then
  # shellcheck disable=SC1091
  source "${REPO_ROOT}/.my_scripts/lib/platform_detection_private.sh"
fi
