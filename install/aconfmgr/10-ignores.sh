# shellcheck shell=bash

# NOTE: Most IgnorePath commands should be near their related packages. However,
# these paths are too general.
IgnorePath '/etc/xml/catalog'
IgnorePath '/usr/lib/**/*.cache'
IgnorePath '/usr/share/glib-2.0/*'
IgnorePath '/usr/lib/ghc-*/package.conf.d/*'
IgnorePath '/usr/lib/jvm/*'
IgnorePath '__pycache__'
IgnorePath '*.pyc'
IgnorePath '/usr/share/.mono/*'
IgnorePath '/var/*'
IgnorePath '/etc/credstore'

# These paths are related to graphical programs, but are still used by programs
# that aren't graphical or can be used without graphics (like emacs), so they
# can't be placed in the graphical aconfmgr configs.
IgnorePath '/usr/share/mime/*'
IgnorePath '/usr/share/icons/*/icon-theme.cache'
IgnorePath '/usr/share/applications/mimeinfo.cache'

IgnorePath '/swap'

# btrfs, snapper, etc
IgnorePath '/mnt/btrfs-root'
IgnorePath '/.snapshots'
