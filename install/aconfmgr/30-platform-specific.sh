# shellcheck shell=bash
# Platform-specific configuration.

# shellcheck source=./lib/network.sh
source "${ACONF_LIB}/network.sh"
# shellcheck source=./lib/sysadmin.sh
source "${ACONF_LIB}/sysadmin.sh"
# shellcheck source=./lib/productivity.sh
source "${ACONF_LIB}/productivity.sh"
# shellcheck source=./lib/local-deps-base.sh
source "${ACONF_LIB}/local-deps-base.sh"

if is_wsl; then
  # shellcheck source=./lib/wsl.sh
  source "${ACONF_LIB}/wsl.sh"
else
  # shellcheck source=./lib/system_tuning.sh
  source "${ACONF_LIB}/system_tuning.sh"
  # shellcheck source=./lib/hardening-local.sh
  source "${ACONF_LIB}/hardening-local.sh"
  # shellcheck source=./lib/hardening-network.sh
  source "${ACONF_LIB}/hardening-network.sh"
fi

if is_primary_dev_machine; then
  # shellcheck source=./lib/dev.sh
  source "${ACONF_LIB}/dev.sh"
fi

# shellcheck source=./lib/graphical-client-base.sh
source "${ACONF_LIB}/graphical-client-base.sh"
if uses_local_graphics; then
  # shellcheck source=./lib/graphical-server-base.sh
  source "${ACONF_LIB}/graphical-server-base.sh"
  # shellcheck source=./lib/graphical-appearance.sh
  source "${ACONF_LIB}/graphical-appearance.sh"
  # shellcheck source=./lib/graphical-desktop-env.sh
  source "${ACONF_LIB}/graphical-desktop-env.sh"
  # shellcheck source=./lib/graphical-apps.sh
  source "${ACONF_LIB}/graphical-apps.sh"
  # shellcheck source=./lib/local-deps-graphical.sh
  source "${ACONF_LIB}/local-deps-graphical.sh"
fi
