#!/usr/bin/env bash

readonly REPO_ROOT="$([[ ${CONFIG_GET_ROOT:-0} == 1 ]] && config-repo-root "${BASH_SOURCE[0]}" || echo "${HOME}")"

TERMINAL_WIN_ID="${WINDOWID}"

# Example value:
# vbox_win_id_given='0x100000d'
vbox_win_id_given="$1"

vbox_window_id() {
  if [[ -z ${vbox_win_id_given-} ]]; then
    xdotool search --onlyvisible --classname "VirtualBox Machine"
  else
    printf '%s\n' "${vbox_win_id_given}"
  fi
}

focus_on_window() {
  i3-msg "[id=\"$*\"] focus" > /dev/null
}

send_keys() {
  "${REPO_ROOT}/install/virtualbox/string_to_xdotool_key_args.py" "$@" |
    xargs -d '\n' xdotool key
}

send_enter() {
  xdotool key Return
}

send_keys_and_enter() {
  send_keys "$@" && send_enter
}

focus_and_send_keys() {
  focus_on_window "$(vbox_window_id)"
  send_keys "$@"
  focus_on_window "${TERMINAL_WIN_ID}"
}
