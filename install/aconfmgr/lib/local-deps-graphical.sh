# shellcheck shell=bash
# Dependencies for locally built/installed packages/scripts.

# All of the build tools below are required by multiple packages built in the
# script install-crossdistro-local-packages.
AddPackage git             # the fast distributed version control system
AddPackage make            # GNU make utility to maintain groups of programs
AddPackage go              # Core compiler tools for the Go programming language
AddPackage rust            # Systems programming language focused on safety, speed and concurrency
AddPackage nodejs          # Evented I/O for V8 javascript
AddPackage npm             # A package manager for javascript
AddPackage yarn            # Fast, reliable, and secure dependency management

# Polybar
# https://github.com/polybar/polybar/wiki/Compiling
AddPackage git             # the fast distributed version control system
AddPackage make            # GNU make utility to maintain groups of programs
AddPackage cmake           # A cross-platform open-source make system
AddPackage pkgconf         # Package compiler and linker metadata toolkit
AddPackage clang           # C language family frontend for LLVM
AddPackage alsa-lib        # An alternative implementation of Linux sound support
AddPackage cairo           # 2D graphics library with support for multiple output devices
AddPackage libnl           # Library for applications dealing with netlink sockets
AddPackage libpulse        # A featureful, general-purpose sound server (client library)
AddPackage libxcb          # X11 client-side library
AddPackage xcb-proto       # XML-XCB protocol descriptions
AddPackage xcb-util-cursor # XCB cursor library
AddPackage xcb-util-image  # Utility libraries for XC Binding - Port of Xlib's XImage and XShmImage functions
AddPackage xcb-util-wm     # Utility libraries for XC Binding - client and window-manager helpers for ICCCM
AddPackage xcb-util-xrm    # XCB utility functions for the X resource manager
AddPackage libmpdclient    # C library to implement a MPD client

# Terminal notifications dependencies.
# https://github.com/marzocchi/zsh-notify
AddPackage wmctrl     # Control your EWMH compliant window manager from command line

# get-window-title dependencies.
AddPackage sed        # GNU stream editor
# Provides hexdump.
AddPackage util-linux # Miscellaneous system utilities for Linux
# Provides xxd.
AddPackage gvim # Vi Improved, a highly configurable, improved version of the vi text editor (with advanced features, such as a GUI)
