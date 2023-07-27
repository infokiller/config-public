# shellcheck shell=bash
# Networking packages with no X11/Wayland/GUI dependencies.

AddPackage dhcpcd # RFC2131 compliant DHCP client daemon
CreateLink '/etc/systemd/system/multi-user.target.wants/dhcpcd.service' '/usr/lib/systemd/system/dhcpcd.service'

AddPackage openresolv # resolv.conf management framework (resolvconf)
CopyFile '/etc/resolvconf.conf'
CopyFile '/etc/nsswitch.conf'
IgnorePath '/etc/resolv.conf'
IgnorePath '/etc/resolv.conf.bak'

AddPackage openssh # Free version of the SSH connectivity tools
# TODO: append my changes to the stock file or use the "Include" directive to
# put my changes in a separate file.
CopyFile '/etc/ssh/sshd_config' 600
IgnorePath '/etc/ssh/ssh_host_*_key*'
CreateLink '/etc/systemd/system/multi-user.target.wants/sshd.service' '/usr/lib/systemd/system/sshd.service'

# As of 2023-01-14, eternalterminal requires openssl 1.x but requires the
# openssl package which now defaults to 3.x.
AddPackage openssl-1.1               # The Open Source toolkit for Secure Sockets Layer and Transport Layer Security
AddPackage --foreign eternalterminal # Re-Connectable Terminal connection. Includes both client and server.
CreateLink /etc/systemd/system/multi-user.target.wants/et.service /usr/lib/systemd/system/et.service

# VPN
AddPackage tailscale # A mesh VPN that makes it easy to connect your devices, wherever they are.
CreateLink /etc/systemd/system/multi-user.target.wants/tailscaled.service /usr/lib/systemd/system/tailscaled.service

HOST_SPECIFIC_FILES=(
  /etc/udev/rules.d/10-network.rules
)
for file in "${HOST_SPECIFIC_FILES[@]}"; do
  # shellcheck disable=2154
  [[ -r "${config_dir}/files/${file}.${HOST_ALIAS}" ]] && CopyFileTo "${file}.${HOST_ALIAS}" "${file}"
done

# Home network
AddPackage nss-mdns # glibc plugin providing host name resolution via mDNS
AddPackage avahi    # Service Discovery for Linux using mDNS/DNS-SD -- compatible with Bonjour
CreateLink '/etc/systemd/system/dbus-org.freedesktop.Avahi.service' '/usr/lib/systemd/system/avahi-daemon.service'
CreateLink '/etc/systemd/system/multi-user.target.wants/avahi-daemon.service' '/usr/lib/systemd/system/avahi-daemon.service'
CreateLink '/etc/systemd/system/sockets.target.wants/avahi-daemon.socket' '/usr/lib/systemd/system/avahi-daemon.socket'

# NOTE: I used to enable wifi only on laptops, but I actually occasionally use
# it in desktops as well when the internet goes down and I use a hotspot from my
# mobile.
# Wifi
AddPackage iw             # nl80211 based CLI configuration utility for wireless devices
AddPackage wireless_tools # Tools allowing to manipulate the Wireless Extensions
AddPackage wpa_supplicant # A utility providing key negotiation for WPA wireless networks
# Bluetooth
if has_bluetooth; then
  AddPackage bluez       # Daemons for the bluetooth protocol stack
  AddPackage bluez-utils # Development and debugging utilities for the bluetooth protocol stack
  CreateLink '/etc/systemd/system/dbus-org.bluez.service' '/usr/lib/systemd/system/bluetooth.service'
  CreateLink '/etc/systemd/system/bluetooth.target.wants/bluetooth.service' '/usr/lib/systemd/system/bluetooth.service'
fi

AddPackage networkmanager # Network connection manager and user applications
CopyFile /etc/NetworkManager/conf.d/dns.conf
CreateLink '/etc/systemd/system/dbus-org.freedesktop.NetworkManager.service' '/usr/lib/systemd/system/NetworkManager.service'
CreateLink '/etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service' '/usr/lib/systemd/system/NetworkManager-dispatcher.service'
CreateLink '/etc/systemd/system/multi-user.target.wants/NetworkManager.service' '/usr/lib/systemd/system/NetworkManager.service'

set_hosts() {
  local expected_hostsfile
  expected_hostsfile="$(CreateFile /etc/hosts)"
  # New machines must run fetch-updates prior to export, or hostsctl will fail.
  sudo hostsctl fetch-updates
  # shellcheck disable=SC2024
  sudo hostsctl export > "${expected_hostsfile}"
}

# /etc/hosts is autogenerated by WSL by default, so I disable setting it from
# my config. It's possible to disable the autogeneration, which I will avoid
# for now to avoid networking issues (at least till I feel WSL is stable for
# me). It's also possible to configure hosts for Windows, which will be
# automatically copied to this file. See also:
# https://github.com/Microsoft/WSL/issues/3043
if is_wsl; then
  IgnorePath '/etc/hosts'
else
  # NOTE: As of 2020-03-31, hostsctl is included as a submodule.
  # AddPackage --foreign hostsctl # block advertisements, trackers, and other malicious activity by manipulating /etc/hosts
  CopyFile '/etc/hostsctl/hostsctl.conf'
  CopyFile '/etc/hostsctl/disabled.hosts'
  CopyFile '/etc/hostsctl/enabled.hosts'
  # orig.hosts is set in 05-private-before.sh
  # IgnorePath '/etc/hostsctl/orig.hosts'
  IgnorePath '/etc/hostsctl/remote.hosts'
  # NOTE: This should be executed after the hostsctl files were copied.
  set_hosts
fi

IgnorePath '/etc/ca-certificates/*'
IgnorePath '/etc/ssl/certs/*'

AddPackage iproute2      # IP Routing Utilities
AddPackage iputils       # Network monitoring tools, including ping
AddPackage ldns          # Fast DNS library supporting recent RFCs
AddPackage net-tools     # Configuration tools for Linux networking
AddPackage bind          # The ISC DNS Server
AddPackage traceroute    # Tracks the route taken by packets over an IP network
AddPackage whois         # Intelligent WHOIS client
AddPackage macchanger    # A small utility to change your NIC's MAC address
AddPackage speedtest-cli # Command line interface for testing internet bandwidth using speedtest.net
IgnorePath '/usr/lib/python3.*/site-packages/speedtest_cli-*.egg-info/*'
AddPackage wget    # Network utility to retrieve files from the Web
AddPackage ethtool # Utility for controlling network drivers and hardware
# Only the hostname command is used in inetutils
AddPackage inetutils # A collection of common network programs

AddPackage nmap      # Utility for network discovery and security auditing
AddPackage rsync     # A file transfer program to keep remote files in sync
AddPackage rclone    # Sync files to and from Google Drive, S3, Swift, Cloudfiles, Dropbox and Google Cloud Storage
AddPackage syncthing # Open Source Continuous Replication / Cluster Synchronization Thing
AddPackage kbfs      # The Keybase filesystem

CreateLink '/etc/systemd/user/sockets.target.wants/p11-kit-server.socket' '/usr/lib/systemd/user/p11-kit-server.socket'
