# See note in .zshenv about sourcing .profile.
if [[ -z ${_IKL_PROFILE_LOADED-} && ! -o INTERACTIVE ]]; then
  emulate sh -c 'source ${ZSHENV_DIR}/../../.profile'
fi
