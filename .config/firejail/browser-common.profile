# Enable the projects directory for loading local extensions.
whitelist ${HOME}/projects
# Google drive locally synced files.
whitelist ${HOME}/desktop
whitelist ${HOME}/drive
whitelist ${HOME}/media
whitelist ${HOME}/src/tabctl
whitelist ${HOME}/src/web-search-navigator
whitelist ${HOME}/sync
whitelist ${HOME}/tmp
whitelist ${HOME}/.config/vimium-options.json
whitelist ${HOME}/.config/ublock-settings.json
whitelist ${HOME}/.config/qutebrowser

include firefox-common-addons.inc
include firenvim.inc

# Make data on mounted partitions accessible.
ignore disable-mnt

# dbus is required for native notifications. See also:
# https://github.com/netblue30/firejail/issues/2028#issuecomment-402754297
ignore nodbus
