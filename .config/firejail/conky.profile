# This is needed to enable conky to query the current volume.
ignore nosound
# Needed for getting the keyboard layout via my scripts.
ignore noexec ${HOME}
include /etc/firejail/conky.profile

# Disable firejail output because otherwise the output of
# ~/.config/i3/conky-i3bar becomes malformed (it should be valid json).
quiet
