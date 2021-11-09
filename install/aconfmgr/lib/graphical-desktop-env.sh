# shellcheck shell=bash
# Core desktop environment packages.

# Custom desktop session
CopyFile '/usr/share/xsessions/custom.desktop'

AddPackage lightdm             # A lightweight display manager
AddPackage lightdm-gtk-greeter # GTK+ greeter for LightDM
CreateLink '/etc/systemd/system/display-manager.service' '/usr/lib/systemd/system/lightdm.service'
# accountsservice is an optional dependency of lightdm, but if it's not
# installed then lightdm outputs a warning to the journal. The package seems
# pretty lightweight and harmless so I'm installing it to remove this warning.
# See also: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=837979
AddPackage accountsservice  # D-Bus interface for user account query and manipulation

AddPackage i3-wm            # An improved dynamic tiling window manager
AddPackage i3status         # Generates status bar to use with i3bar, dzen2 or xmobar
# Required by i3-save-tree.
AddPackage perl-anyevent-i3 # Communicate with the i3 window manager
AddPackage unclutter        # A small program for hiding the mouse cursor
AddPackage xcape            # Configure modifier keys to act as other keys when pressed and released on their own
AddPackage xss-lock         # Use external locker as X screen saver
AddPackage xsecurelock      # X11 screen lock utility with security in mind
AddPackage i3lock           # An improved screenlocker based upon XCB and PAM
AddPackage gnome-keyring    # Stores passwords and encryption keys
AddPackage picom            # X compositor that may fix tearing issues
AddPackage conky            # Lightweight system monitor for X
AddPackage dunst            # Customizable and lightweight notification-daemon
AddPackage copyq            # Clipboard manager with searchable and editable history
AddPackage dconf-editor     # dconf Editor
AddPackage polkit-gnome     # Legacy polkit authentication agent for GNOME
AddPackage maim             # Utility to take a screenshot using imlib2
AddPackage flameshot        # Powerful yet simple to use screenshot software
AddPackage gnome-screenshot # Take pictures of your screen
AddPackage kdeconnect       # Adds communication between KDE and your smartphone
# Required for kdeconnect to be able to browse file systems on remote devices.
AddPackage sshfs # FUSE client based on the SSH File Transfer Protocol
AddPackage dex   # Program to generate and execute DesktopEntry files of type Application

AddPackage ibus # Next Generation Input Bus for Linux
IgnorePath '/etc/dconf/db/ibus'

# Applets
AddPackage volumeicon             # Volume control for your system tray
AddPackage network-manager-applet # Applet for managing network connections
AddPackage udiskie                # Removable disk automounter using udisks
CreateLink '/etc/systemd/system/graphical.target.wants/udisks2.service' '/usr/lib/systemd/system/udisks2.service'
# NOTE: As of 2020-01-25, usbguard-qt is no longer in the official Arch repos,
# and the AUR version doesn't work. I can use the CLI tools in the meantime.
# AddPackage usbguard-qt            # Software framework for implementing USB device authorization policies - Qt frontend
if is_laptop; then
  AddPackage blueman # GTK+ Bluetooth Manager
fi

AddPackage redshift # Adjusts the color temperature of your screen according to your surroundings.
# Append some options to geoclue config file to allow redshift to access the
# network.
cat >> "$(GetPackageOriginalFile geoclue /etc/geoclue/geoclue.conf)" <<'EOF'

[redshift]
allowed=true
system=false
users=
EOF
