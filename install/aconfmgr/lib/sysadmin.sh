# shellcheck shell=bash
# Sysadmin packages and config that have no X11/Wayland/GUI or networking
# dependencies.

CopyFile /etc/systemd/logind.conf.d/10-powerkey.conf
if [[ "${HOST_ALIAS}" == hera11 ]]; then
  CopyFile '/etc/systemd/logind.conf.d/20-ignore-lidswitch-externalpower.conf'
fi
CopyFile '/etc/systemd/journald.conf.d/00-journal-size.conf'
CopyFile '/etc/systemd/system.conf.d/timeouts.conf'
CopyFile '/etc/systemd/user.conf.d/resources.conf'
CopyFile '/etc/systemd/user.conf.d/timeouts.conf'

IgnorePath '/usr/lib/udev/hwdb.bin'

# As of 2020-05-15, network-ups-tools is working unreliably for me (usually
# doesn't detect the UPS although it shows up in lsusb).
if [[ "${HOST_ALIAS}" == zeus18 ]]; then
  AddPackage nut # NUT is a collection of programs for monitoring and administering UPS hardware
  CopyFile '/etc/udev/rules.d/50-nut.rules'
  # Setting the /etc/nut file properties is a workaround to an issue where
  # aconfmgr doesn't detect the package permissions correctly:
  # https://github.com/CyberShadow/aconfmgr/issues/115#issuecomment-986014006
  SetFileProperty '/etc/nut/upsd.conf' group nut
  SetFileProperty '/etc/nut/upsd.conf' mode 640
  SetFileProperty '/etc/nut/upsd.users' group nut
  SetFileProperty '/etc/nut/upsd.users' mode 640
  SetFileProperty '/etc/nut/upsmon.conf' group nut
  SetFileProperty '/etc/nut/upsmon.conf' mode 640
  cat >> "$(GetPackageOriginalFile nut '/etc/nut/ups.conf')" << 'EOF'

[eaton_zeus18]
  driver = "usbhid-ups"
  port = "auto"
  vendorid = "0463"
EOF
fi

AddPackage borg # Deduplicating backup program with compression and authenticated encryption
IgnorePath '/usr/lib/python3.*/site-packages/borgbackup-*.egg-info/*'
# Required for mounting borg backups.
AddPackage python-llfuse # A set of Python bindings for the low level FUSE API.

# Filesystem, no X11 or networking dependencies.
AddPackage device-mapper # Device mapper userspace library and tools
AddPackage udisks2       # Disk Management Service, version 2
AddPackage lsof          # Lists open files for running Unix processes
AddPackage rsync         # A file transfer program to keep remote files in sync
AddPackage gdu           # Fast disk usage analyzer
AddPackage ncdu          # Disk usage analyzer with an ncurses interface
AddPackage wipe          # Secure file wiping utility
AddPackage ntfs-3g       # NTFS filesystem driver and utilities
AddPackage smartmontools # Control and monitor S.M.A.R.T. enabled ATA and SCSI Hard Drives
CreateLink '/etc/systemd/system/multi-user.target.wants/smartd.service' '/usr/lib/systemd/system/smartd.service'
# btrfs
if is_btrfs_machine; then
  AddPackage btrfs-progs # Btrfs filesystem utilities
  IgnorePath '/usr/lib/python3.*/site-packages/btrfsutil-*.egg-info/*'
  AddPackage compsize # Calculate compression ratio of a set of files on Btrfs
  # Snapper
  AddPackage snapper  # A tool for managing BTRFS and LVM snapshots. It can create, diff and restore snapshots and provides timelined auto-snapping.
  AddPackage snap-pac # Pacman hooks that use snapper to create pre/post btrfs snapshots like openSUSE's YaST
  CopyFile '/etc/snapper/configs/home' 600
  CopyFile '/etc/snapper/configs/root' 600
  CopyFile '/etc/conf.d/snapper'
  CreateLink '/etc/systemd/system/timers.target.wants/snapper-boot.timer' '/usr/lib/systemd/system/snapper-boot.timer'
  CreateLink '/etc/systemd/system/timers.target.wants/snapper-cleanup.timer' '/usr/lib/systemd/system/snapper-cleanup.timer'
  CreateLink '/etc/systemd/system/timers.target.wants/snapper-timeline.timer' '/usr/lib/systemd/system/snapper-timeline.timer'
  # https://wiki.archlinux.org/title/System_backup#Snapshots_and_/boot_partition
  CopyFile '/etc/pacman.d/hooks/95-bootbackup.hook' 640
  IgnorePath '/.bootbackup'
fi

AddPackage xdg-user-dirs # Manage user directories like ~/Desktop and ~/Music
CreateLink '/etc/systemd/user/default.target.wants/xdg-user-dirs-update.service' '/usr/lib/systemd/user/xdg-user-dirs-update.service'

AddPackage lvm2 # Logical Volume Manager 2 utilities
IgnorePath '/etc/lvm/archive/*'
IgnorePath '/etc/lvm/backup/arch'

CopyFile /etc/fuse.conf

# Package management: pacman
AddPackage pkgfile        # a pacman .files metadata explorer
AddPackage pacman-contrib # Contributed scripts and tools for pacman systems
AddPackage devtools       # Tools for Arch Linux package maintainers
AddPackage --foreign yay  # Yet another yogurt. Pacman wrapper and AUR helper written in go.
# Periodically clean Pacman's cache to save disk space
CopyFile '/etc/systemd/system/paccache.service.d/override.conf'
CreateLink '/etc/systemd/system/timers.target.wants/paccache.timer' '/usr/lib/systemd/system/paccache.timer'
# Periodically download latest versions of packages to make upgrades quicker.
CopyFile '/etc/systemd/system/download-new-packages.service'
CopyFile '/etc/systemd/system/download-new-packages.timer'
CreateLink '/etc/systemd/system/timers.target.wants/download-new-packages.timer' '/etc/systemd/system/download-new-packages.timer'
# Updates cache of available binaries in pacman which is needed for using
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/command-not-found
CreateLink '/etc/systemd/system/multi-user.target.wants/pkgfile-update.timer' '/usr/lib/systemd/system/pkgfile-update.timer'

# Package management: nix
# nix installs /etc/profile.d/nix-daemon.sh which sets PATH and can cause issues
# with other programs, for example loading a shared library from nix that is
# incompatible with another library, so I'm disabling it till I fully commit to
# using nix.
# AddPackage nix # A purely functional package manager
# CreateLink /etc/systemd/system/multi-user.target.wants/nix-daemon.service /usr/lib/systemd/system/nix-daemon.service
# cat >> "$(GetPackageOriginalFile nix /etc/nix/nix.conf)" << 'EOF'
#
# experimental-features = nix-command flakes
# EOF
IgnorePath '/nix/*'

# Package management: others
AddPackage flatpak # Linux application sandboxing and distribution framework (formerly xdg-app)

# GNOME keyring
AddPackage gnome-keyring # Stores passwords and encryption keys
CreateLink '/etc/systemd/user/sockets.target.wants/gnome-keyring-daemon.socket' '/usr/lib/systemd/user/gnome-keyring-daemon.socket'
# gcr-ssh-agent is enabled by the arch package:
# https://github.com/archlinux/svntogit-packages/blob/ab4cadffe15a327b582629ddef5f9c7f16c1c3e1/gcr/trunk/gcr.install
CreateLink '/etc/systemd/user/sockets.target.wants/gcr-ssh-agent.socket' '/usr/lib/systemd/user/gcr-ssh-agent.socket'

# GPG
AddPackage gnupg # Complete and free implementation of the OpenPGP standard
CreateLink '/etc/systemd/user/sockets.target.wants/dirmngr.socket' '/usr/lib/systemd/user/dirmngr.socket'
CreateLink '/etc/systemd/user/sockets.target.wants/gpg-agent-browser.socket' '/usr/lib/systemd/user/gpg-agent-browser.socket'
CreateLink '/etc/systemd/user/sockets.target.wants/gpg-agent-extra.socket' '/usr/lib/systemd/user/gpg-agent-extra.socket'
CreateLink '/etc/systemd/user/sockets.target.wants/gpg-agent-ssh.socket' '/usr/lib/systemd/user/gpg-agent-ssh.socket'
CreateLink '/etc/systemd/user/sockets.target.wants/gpg-agent.socket' '/usr/lib/systemd/user/gpg-agent.socket'

# Auth
AddPackage libfido2                # Library functionality for FIDO 2.0, including communication with a device over USB
AddPackage keybase                 # CLI tool for GPG with keybase.io
AddPackage lastpass-cli            # LastPass command line interface tool
AddPackage yubikey-manager         # Python library and command line tool for configuring a YubiKey
AddPackage yubikey-personalization # Yubico YubiKey Personalization library and tool
AddPackage yubikey-touch-detector  # A tool that can detect when your YubiKey is waiting for a touch

# Smartcard daemon
AddPackage pcsclite # PC/SC Architecture smartcard middleware library
CreateLink '/etc/systemd/system/sockets.target.wants/pcscd.socket' '/usr/lib/systemd/system/pcscd.socket'

AddPackage minisign # A dead simple tool to sign files and verify digital signatures.
if is_primary_dev_machine; then
  AddPackage veracrypt # Disk encryption with strong security based on TrueCrypt
fi

# Performance monitoring
AddPackage htop    # Interactive process viewer
AddPackage glances # CLI curses-based monitoring tool
AddPackage btop    # A monitor of system resources, bpytop ported to C++
AddPackage iotop   # View I/O usage of processes
AddPackage sysstat # a collection of performance monitoring tools (iostat,isag,mpstat,pidstat,sadf,sar)
if is_intel_cpu; then
  AddPackage i7z # A better i7 (and now i3, i5) reporting tool for Linux
fi
if is_nvidia_gpu; then
  AddPackage nvtop # An htop like monitoring tool for NVIDIA GPUs
fi

# Other system administration utilities, no X11 dependencies
AddPackage git                # the fast distributed version control system
AddPackage usbutils           # USB Device Utilities
AddPackage logrotate          # Rotates system logs automatically
AddPackage lshw               # A small tool to provide detailed information on the hardware configuration of the machine.
AddPackage strace             # A diagnostic, debugging and instructional userspace tracer
AddPackage dmidecode          # Desktop Management Interface table related utilities
AddPackage exfatprogs         # exFAT filesystem userspace utilities for the Linux Kernel exfat driver
AddPackage pciutils           # PCI bus configuration space access library and tools
AddPackage inotify-tools      # inotify-tools is a C library and a set of command-line programs for Linux providing a simple interface to inotify.
AddPackage neofetch           # A CLI system information tool written in BASH that supports displaying images.
AddPackage perl-file-mimeinfo # Determine file type, includes mimeopen and mimetype
AddPackage croc               # Easily and securely send things from one computer to another.

if ! is_wsl; then
  # It's unlikely I'll want to print anything on WSL since I can just use the
  # much better supported Windows drivers.
  AddPackage cups     # The CUPS Printing System - daemon package
  AddPackage cups-pdf # PDF printer for cups
  # Not sure if fwupd will work in WSL, and Windows probably has better support
  # for installing firmware anyway.
  AddPackage fwupd # Simple daemon to allow session software to update firmware
fi
