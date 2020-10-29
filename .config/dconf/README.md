# dconf scripts

This directory contains text files with dconf settings, which are used by the
GNOME desktop environment and other apps. The `base.ini` files contains settings
common to all machines, while the `<host_alias>.ini` files contain settings
specific to `<host_alias>`.

To diff the current live settings to the ones stored in the config:

```sh
dconf dump / >! "/tmp/dconf_live_${HOST_ALIAS}.ini" && ./dconf_diff.py --base-configs "base.ini,${HOST_ALIAS}.ini" --other-configs "/tmp/dconf_live_${HOST_ALIAS}.ini"
```

To reset the live settings to the ones stored in the config:

```sh
~/.config/dconf/load-config
```
