#!/usr/bin/env bash

# shellcheck disable=SC2155
readonly REPO_ROOT="$([[ ${CONFIG_GET_ROOT:-0} == 1 ]] && config-repo-root "${BASH_SOURCE[0]}" || echo "${HOME}")"
# shellcheck source=virtualbox_installation_util.sh
source "${REPO_ROOT}/install/virtualbox/virtualbox_installation_util.sh"

send_mount_cmds() {
  focus_on_window "$(vbox_window_id)"
  sleep 0.2
  send_keys_and_enter "cryptsetup open /dev/sda3 cryptroot"
  # Wait for password prompt
  sleep 2
  send_keys_and_enter "pass"
  sleep 5
  send_keys_and_enter "mount /dev/mapper/cryptroot /mnt"
  send_keys_and_enter "mount /dev/sda2 /mnt/boot"
  send_keys_and_enter "mount /dev/sda1 /mnt/boot/efi"
}
