# shellcheck shell=bash
# Packages for interacting with a display server, but without dependencies on
# display servers. For example, packages in this file can depend on libx11, but
# not on xorg-server.
# These packages can be useful even without a local display server, since it's
# possible to connect to a remote display server.

# X11 fonts.
# NOTE: According to the X11 wiki [1], font rendering can happen either on the
# server or client, though modern toolkits usually do it on the client.
# Therefore, we must also install fonts on the client.
AddPackage xorg-fonts-100dpi       # X.org 100dpi fonts
AddPackage xorg-fonts-alias-100dpi # X.org font alias files - 100dpi font familiy
AddPackage xorg-fonts-75dpi        # X.org 75dpi fonts
AddPackage xorg-fonts-alias-75dpi  # X.org font alias files - 75dpi font familiy
# AddPackage xorg-fonts-alias        # X.org font alias files

# X11 utilities.
AddPackage xorg-bdftopcf    # Convert X font from Bitmap Distribution Format to Portable Compiled Format
AddPackage xorg-font-util   # X.Org font utilities
AddPackage xorg-mkfontscale # Create an index of scalable font files for X
AddPackage xorg-xauth       # X.Org authorization settings program
AddPackage xorg-xbacklight  # RandR-based backlight control application
AddPackage xorg-xdpyinfo    # Display information utility for X
AddPackage xorg-xev         # Print contents of X events
AddPackage xorg-xfd         # Displays all the characters in a font using either the X11 core protocol or libXft2
AddPackage xorg-xhost       # Server access control program for X
AddPackage xorg-xinit       # X.Org initialisation program
AddPackage xorg-xinput      # Small commandline tool to configure devices
AddPackage xorg-xkill       # Kill a client by its X resource
AddPackage xorg-xlsfonts    # List available X fonts
AddPackage xorg-xprop       # Property displayer for X
AddPackage xorg-xrdb        # X server resource database utility
AddPackage xorg-xset        # User preference utility for X
AddPackage xorg-xsetroot    # Classic X utility to set your root window background to a given pattern or color
AddPackage xorg-xwininfo    # Command-line utility to print information about windows on an X server
AddPackage xsel             # XSel is a command-line program for getting and setting the contents of the X selection
AddPackage xclip            # Command line interface to the X11 clipboard
AddPackage xdotool          # Command-line X11 automation tool
AddPackage hsetroot         # Tool which allows you to compose wallpapers ("root pixmaps") for X. Fork by Hyriand
AddPackage wmctrl           # Control your EWMH compliant window manager from command line

# X11: XKB
AddPackage xorg-xkbcomp   # X Keyboard description compiler
AddPackage xorg-setxkbmap # Set the keyboard using the X Keyboard Extension

_add_dreymar_xkb_mods() {
  local xkb_mods="${SUBMODULES_DIR}/BigBagKbdTricks_XKB/xkb-data_xmod/xkb"
  while IFS= read -r -d '' f; do
    local file_path="/usr/share/X11/xkb/${f#"${xkb_mods}"/}"
    CopyFile "${file_path}"
  done < <(find "${xkb_mods}" -type f -print0)
}

# Not used for now because:
# 1. Dreymar's xkeyboard-config is older than the one on Arch
# 2. I use my own self contained xkb config anyway
# _add_dreymar_xkb_mods

# NOTE: Needs to be installed both in the graphical client and server.
AddPackage xpra # multi-platform screen and application forwarding system screen for X11
