# shellcheck shell=bash
# Sysadmin packages and config that have no X11/Wayland/GUI or networking
# dependencies.

# Basic development packages, no X11 dependencies.
AddPackage git             # the fast distributed version control system
AddPackage git-filter-repo # Quickly rewrite git repository history (filter-branch replacement)
AddPackage hub             # cli interface for Github
AddPackage github-cli      # The GitHub CLI
AddPackage make            # GNU make utility to maintain groups of programs
AddPackage autoconf        # A GNU tool for automatically configuring source code
AddPackage automake        # A GNU tool for automatically creating Makefiles
AddPackage binutils        # A set of programs to assemble and manipulate binary and object files
AddPackage cmake           # A cross-platform open-source make system
AddPackage gcc             # The GNU Compiler Collection - C and C++ frontends
AddPackage gcc-libs        # Runtime libraries shipped by GCC
AddPackage patch           # A utility to apply patch files to original sources
AddPackage pkgconf         # Package compiler and linker metadata toolkit
AddPackage dash            # POSIX compliant shell that aims to be as small as possible
AddPackage go              # Core compiler tools for the Go programming language
AddPackage go-tools        # Developer tools for the Go programming language
AddPackage rust            # Systems programming language focused on safety, speed and concurrency
AddPackage parallel        # A shell tool for executing jobs in parallel
# Android
AddPackage android-tools # Android platform tools
AddPackage android-udev  # Udev rules to connect Android devices to your linux box

AddPackage nodejs # Evented I/O for V8 javascript
IgnorePath '/usr/lib/node_modules/*'
AddPackage npm            # A package manager for javascript
AddPackage yarn           # Fast, reliable, and secure dependency management

AddPackage docker         # Pack, ship and run any application as a lightweight container
AddPackage docker-compose # Fast, isolated development environments using Docker
CreateLink /etc/systemd/system/multi-user.target.wants/docker.service /usr/lib/systemd/system/docker.service
IgnorePath '/etc/docker/key.json'
IgnorePath '/opt/containerd/*'
AddPackage gitlab-runner # The official GitLab CI runner written in Go

AddPackage libvirt # API for controlling virtualization engines (openvz,kvm,qemu,virtualbox,xen,etc)
IgnorePath '/etc/libvirt/secrets'
IgnorePath '/etc/libvirt/secrets/*'
IgnorePath '/etc/libvirt/storage/*'
IgnorePath '/etc/libvirt/networks/*'
IgnorePath '/etc/libvirt/nwfilter/*'
IgnorePath '/etc/libvirt/qemu/*.xml'
IgnorePath '/run/libvirt/*'
# Optional libvirt/qemu deps (see
# https://wiki.archlinux.org/index.php/libvirt#Server):
# ebtables and dnsmasq are required for NAT/DHCP networking
# openbsd-netcat is required for remote SSH management.
AddPackage dnsmasq        # Lightweight, easy to configure DNS forwarder and DHCP server
AddPackage ebtables       # Ethernet bridge filtering utilities
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
CopyFile /etc/modprobe.d/kvm.conf

AddPackage emacs                # The extensible, customizable, self-documenting real-time display editor
AddPackage bat                  # cat clone with Git integration and syntax highlighting support
AddPackage jq                   # Command-line JSON processor
AddPackage fd                   # Simple, fast and user-friendly alternative to find
AddPackage shellcheck           # Shell script analysis tool
# Disabled because I don't really use it and AUR packages can be a security
# issue.
# AddPackage --foreign howdoi # A code search tool.
AddPackage aspell-en            # English dictionary for aspell
AddPackage cloc                 # Count lines of code
AddPackage httpie               # cURL for humans
AddPackage qrencode             # C library for encoding data in a QR Code symbol.
AddPackage xonsh                # Python-powered, cross-platform, Unix-gazing shell
AddPackage yapf                 # Python style guide checker
AddPackage pandoc               # Conversion between markup formats
AddPackage termtosvg            # Record terminal sessions as SVG animations

# Latex
AddPackage texlive-bibtexextra  # TeX Live - Additional BibTeX styles and bibliography databases
AddPackage texlive-core         # TeX Live core distribution
AddPackage texlive-fontsextra   # TeX Live - all sorts of extra fonts
AddPackage texlive-formatsextra # TeX Live - collection of extra TeX 'formats'
AddPackage texlive-latexextra   # TeX Live - Large collection of add-on packages for LaTeX
AddPackage texlive-pictures     # TeX Live - Packages for drawings graphics
AddPackage texlive-pstricks     # TeX Live - Additional PSTricks packages
AddPackage texlive-publishers   # TeX Live - LaTeX classes and packages for specific publishers
AddPackage texlive-science      # TeX Live - Typesetting for mathematics, natural and computer sciences
IgnorePath '/etc/texmf/ls-R'
IgnorePath '/etc/texmf/web2c/fmtutil.cnf'
IgnorePath '/etc/texmf/web2c/updmap.cfg'
IgnorePath '/usr/share/texmf-dist/ls-R'
