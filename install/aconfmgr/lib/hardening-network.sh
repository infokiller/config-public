# shellcheck shell=bash
# Network hardening config with no X11/Wayland/GUI dependencies.

AddPackage dnscrypt-proxy # DNS proxy, supporting encrypted DNS protocols such as DNSCrypt v2 and DNS-over-HTTP.
CopyFile '/etc/dnscrypt-proxy/custom/dnscrypt-proxy.toml'
CopyFile '/etc/dnscrypt-proxy/custom/forwarding-rules.txt'
CopyFile '/etc/systemd/system/dnscrypt-proxy.service.d/override.conf'
CreateLink '/etc/systemd/system/multi-user.target.wants/dnscrypt-proxy.service' '/usr/lib/systemd/system/dnscrypt-proxy.service'
CopyFile '/etc/systemd/system/dnscrypt-proxy.socket'

AddPackage openvpn # An easy-to-use, robust and highly configurable VPN (Virtual Private Network)
IgnorePath '/etc/openvpn/server'
SetFileProperty '/etc/openvpn/client' group network
SetFileProperty '/etc/openvpn/client' mode 750
SetFileProperty '/etc/openvpn/client' owner openvpn
CopyFile '/etc/openvpn/client/client.conf'
CopyFile '/etc/openvpn/update-resolv-conf' 755

AddPackage ufw # Uncomplicated and easy to use CLI tool for managing a netfilter firewall
CopyFile '/etc/default/ufw'
CopyFile '/etc/ufw/after.rules'
CopyFile '/etc/ufw/after6.rules'
CopyFile '/etc/ufw/sysctl.conf'
CopyFile '/etc/ufw/ufw.conf'
CopyFile '/etc/ufw/user.rules'
CopyFile '/etc/ufw/user6.rules'
CopyFile '/etc/ufw/applications.d/custom'
CreateLink '/etc/systemd/system/multi-user.target.wants/ufw.service' '/usr/lib/systemd/system/ufw.service'

AddPackage tor                 # Anonymizing overlay network.
AddPackage nyx                 # Command-line status monitor for tor
# AddPackage --foreign tor-browser # Tor Browser Bundle
AddPackage torbrowser-launcher # Securely and easily download, verify, install, and launch Tor Browser in Linux

configure_mullvad_vpn() {
  AddPackage --foreign mullvad-vpn # VPN Client for Mullvad.net
  # AddPackage --foreign nvm         # Node Version Manager - Simple bash script to manage multiple active node.js versions
  # NOTE: The wireguard key is stored in /etc/mullvad-vpn/device.json since
  # version 2022.2.
  CopyFile '/etc/mullvad-vpn/settings.json'
  CopyFile '/etc/mullvad-vpn/account-history.json'
  IgnorePath '/etc/mullvad-vpn/device.json'
  IgnorePath '/usr/bin/mullvad-problem-report'
  IgnorePath '/opt/Mullvad VPN/resources/mullvad-problem-report'
  CreateLink '/usr/lib/systemd/system/mullvad-daemon.service' '/opt/Mullvad VPN/resources/mullvad-daemon.service'
  # for server in at1 au1 be1 bg1 br1 ca1 ca2 ca3 ch1 ch2 cz1 de1 de2 de4 de5 dk1 \
  #   es1 fi1 fr1 gb2 gb3 gb4 gb5 hk1 in1 it1 jp1 md1 nl1 nl2 nl3 no1 pl1 ro1 rs1 \
  #   se2 se3 se4 se5 se6 se7 se8 sg1 ua1 us11 us12 us13 us14 us15 us1 us2 us3 us4 \
  #   us5 us6 us7 us9; do
  #   CopyFile "/etc/wireguard/mullvad-${server}.conf" 600
  # done
  # CreateLink '/etc/systemd/system/multi-user.target.wants/mullvad-daemon.service' '/opt/Mullvad VPN/resources/mullvad-daemon.service'
  CreateLink '/etc/systemd/system/multi-user.target.wants/mullvad-daemon.service' '/usr/lib/systemd/system/mullvad-daemon.service'
}

if [[ "${HOST_ALIAS}" != zeus20-juno ]]; then
  configure_mullvad_vpn
fi

AddPackage proxychains-ng # A hook preloader that allows to redirect TCP traffic of existing dynamically linked programs through one or more SOCKS or HTTP proxies

# AddPackage wireguard-dkms  # next generation secure network tunnel
# AddPackage wireguard-tools # next generation secure network tunnel

# NOTE(2018-10-15): I disabled fail2ban for now because I didn't
# configure it so it didn't really do anything while it was installed. When I
# have more time I'll look into configuring it.
# AddPackage fail2ban # Bans IPs after too many failed authentication attempts
# CopyFile '/etc/systemd/system/fail2ban.service.d/capabilities.conf'
# CreateLink '/etc/systemd/system/multi-user.target.wants/fail2ban.service' '/usr/lib/systemd/system/fail2ban.service'
