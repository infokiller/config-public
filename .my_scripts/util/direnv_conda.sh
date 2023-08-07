#!/usr/bin/env bash
# This script is intended to be sourced by direnv (via an .envrc file).

# See https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -o errexit -o errtrace -o nounset -o pipefail

if [[ -n "${project_dir-}" ]]; then
  dir="${project_dir}"
else
  dir="${OLDPWD}"
fi

_CONDA_ENV_FILES=(
  "${dir}/conda_env.yml"
  "${dir}/req/conda_env.yml"
  "${dir}/environment.yml"
  "${dir}/.conda/environment.yml"
)

_activate_conda_env_file() {
  local file="${1}"
  local env_name
  if [[ -r "${file}" ]] &&
    env_name="$(grep '^name:' "${file}" | awk '{print $2}')" &&
    [[ -n "${env_name}" ]]; then
    # shellcheck source=../../.local/bin/activate
    source activate "${env_name}"
    export PYTHONPATH="${dir}"
    return 0
  fi
  return 1
}

for file in "${_CONDA_ENV_FILES[@]}"; do
  if _activate_conda_env_file "${file}"; then
    return
  fi
done
