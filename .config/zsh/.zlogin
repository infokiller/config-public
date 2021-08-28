# See note in .zshenv about sourcing .profile.
if [[ ! -o INTERACTIVE ]]; then
  emulate sh -c 'source ${ZSHENV_DIR}/../../.profile'
fi
