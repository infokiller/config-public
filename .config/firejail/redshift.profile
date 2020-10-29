noblacklist ${HOME}/.config/redshift.conf

include /etc/firejail/default.profile
include /etc/firejail/disable-devel.inc

net none

# firejail --audit recommends using `private-dev`, but this seems to prevent
# redshift from being able to change the color temperature.
# private-dev
