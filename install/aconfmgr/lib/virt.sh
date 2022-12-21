# shellcheck shell=bash
# Virtualization packages and config that have no X11/Wayland/GUI or networking
# dependencies.

# Docker {{{
AddPackage docker         # Pack, ship and run any application as a lightweight container
AddPackage docker-compose # Fast, isolated development environments using Docker
CreateLink '/etc/systemd/system/multi-user.target.wants/docker.service' '/usr/lib/systemd/system/docker.service'
IgnorePath '/etc/docker/key.json'
IgnorePath '/opt/containerd/*'
if [[ "${HOST_ALIAS}" == zeus18 ]]; then
  # NOTE: runsc is for gVisor [1] which I'm experimenting with.
  # [1] https://github.com/google/gvisor
  cat >| "$(CreateFile '/etc/docker/daemon.json' 600)" << 'EOF'
{
    "data-root": "/mnt/evo970/docker",
    "runtimes": {
        "runsc": {
            "path": "/usr/local/bin/runsc",
            "runtimeArgs": []
        }
    }
}
EOF
fi
# }}} Docker

# Podman {{{
AddPackage podman         # Tool and library for running OCI-based containers in pods
AddPackage fuse-overlayfs # FUSE implementation of overlayfs
IgnorePath /etc/containers/networks/netavark.lock
cat >| "$(CreateFile '/etc/subuid' 644)" <<< "${UID}:100000:65536"
cat >| "$(CreateFile '/etc/subgid' 644)" <<< "${UID}:100000:65536"
# }}} Podman

# Libvirt {{{
AddPackage libvirt # API for controlling virtualization engines (openvz,kvm,qemu,virtualbox,xen,etc)
IgnorePath '/etc/libvirt/secrets'
IgnorePath '/etc/libvirt/secrets/*'
IgnorePath '/etc/libvirt/storage/*'
IgnorePath '/etc/libvirt/networks/*'
IgnorePath '/etc/libvirt/nwfilter/*'
IgnorePath '/etc/libvirt/qemu/*.xml'
IgnorePath '/run/libvirt/*'
# }}} Libvirt

# Qemu {{{
if uses_local_graphics; then
  AddPackage qemu-desktop # A QEMU setup for desktop environments
else
  AddPackage qemu-base # A basic QEMU setup for headless environments
fi
# Offline HTML docs for qemu
AddPackage qemu-docs # A generic and open source machine emulator and virtualizer - documentation
# Optional libvirt/qemu deps (see
# https://wiki.archlinux.org/index.php/libvirt#Server):
# ebtables and dnsmasq are required for NAT/DHCP networking
# openbsd-netcat is required for remote SSH management.
AddPackage dnsmasq        # Lightweight, easy to configure DNS forwarder and DHCP server
AddPackage iptables-nft   # Ethernet bridge filtering utilities
AddPackage openbsd-netcat # TCP/IP swiss army knife. OpenBSD variant.
AddPackage edk2-ovmf      # Tianocore UEFI firmware for qemu.
AddPackage swtpm          # Libtpms-based TPM emulator with socket, character device, and Linux CUSE interface
CreateLink '/etc/systemd/system/multi-user.target.wants/libvirtd.service' '/usr/lib/systemd/system/libvirtd.service'
CreateLink '/etc/systemd/system/sockets.target.wants/libvirtd-ro.socket' '/usr/lib/systemd/system/libvirtd-ro.socket'
CreateLink '/etc/systemd/system/sockets.target.wants/libvirtd.socket' '/usr/lib/systemd/system/libvirtd.socket'
CreateLink '/etc/systemd/system/sockets.target.wants/virtlockd.socket' '/usr/lib/systemd/system/virtlockd.socket'
CreateLink '/etc/systemd/system/sockets.target.wants/virtlogd.socket' '/usr/lib/systemd/system/virtlogd.socket'
# This file is created by the brltty package, which is not used, but is required
# by qemu.
IgnorePath '/etc/brlapi.key'
CopyFile '/etc/modprobe.d/kvm.conf'
AddPackage libguestfs # Access and modify virtual machine disk images
# multipath is a dependency of libguestfs
IgnorePath '/etc/multipath'
# }}} Qemu

# Misc {{{
AddPackage skopeo # A command line utility for various operations on container images and image repositories.
AddPackage gitlab-runner # The official GitLab CI runner written in Go
# }}} Misc
