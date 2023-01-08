# shellcheck shell=bash
# Performance tuning packages and config that have no X11/Wayland/GUI or
# networking dependencies.

# WSL 1 shouldn't hang on OOM because Windows manages the memory.
AddPackage earlyoom # Early OOM Daemon for Linux
CopyFile '/etc/systemd/system/earlyoom.service.d/override.conf'
CreateLink '/etc/systemd/system/multi-user.target.wants/earlyoom.service' '/usr/lib/systemd/system/earlyoom.service'

AddPackage reflector # A Python 3 module and script to retrieve and filter the latest Pacman mirror list.
cat "${REPO_ROOT}/.config/reflector.conf" >| "$(GetPackageOriginalFile reflector '/etc/xdg/reflector/reflector.conf')"
CreateLink /etc/systemd/system/timers.target.wants/reflector.timer /usr/lib/systemd/system/reflector.timer
CopyFile '/etc/pacman.d/hooks/mirrorlist.hook'
# NOTE: As of 2020-04-15, I stopped syncing the pacman mirrors across machines
# because the mirrors should be optimized per machine, i.e. the best optimal
# mirrors for one machine may not be the optimal mirrors for another machine,
# though there aren't probably big differences between machines in the same
# region. I also stopeed tracking them entirely (instead of tracking them for
# every machine separately), since it doesn't seem to have any benefit and
# adds more work when using aconfmgr save/apply.
# CopyFile /etc/pacman.d/mirrorlist
IgnorePath '/etc/pacman.d/mirrorlist'

CreateLink '/etc/systemd/system/timers.target.wants/fstrim.timer' '/usr/lib/systemd/system/fstrim.timer'
CreateLink '/etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service' '/usr/lib/systemd/system/systemd-timesyncd.service'
CreateLink '/etc/systemd/system/multi-user.target.wants/remote-fs.target' '/usr/lib/systemd/system/remote-fs.target'

CopyFile '/etc/sysctl.d/50-misc.conf' 600
CopyFile '/etc/sysctl.d/60-performance.conf' 600
if is_laptop; then
  CopyFile '/etc/sysctl.d/90-laptop.conf' 600
fi

AddPackage irqbalance # IRQ balancing daemon for SMP systems
CreateLink /etc/systemd/system/multi-user.target.wants/irqbalance.service /usr/lib/systemd/system/irqbalance.service

# Benchmarking and stress testing. Monitoring packages are in sysadmin.sh.
AddPackage stress # A tool that stress tests your system (CPU, memory, I/O, disks)

AddPackage cpupower # Linux kernel tool to examine and tune power saving related features of your processor
CreateLink '/etc/systemd/system/multi-user.target.wants/cpupower.service' '/usr/lib/systemd/system/cpupower.service'

# Set CPU governor to "performance" on desktops.
if is_desktop; then
  f="$(GetPackageOriginalFile cpupower /etc/default/cpupower)"
  # TODO: Use http://augeas.net once it supports this file. It should
  # probably be easy to use an existing augeas "lens" for this file, but I
  # couldn't figure it out quickly.
  sed -i -r 's/^#\s*(governor=).*$/\1"performance"/g' "${f}"
  unset f
fi

AddPackage --foreign cfs-zen-tweaks # Script tweak CFS for desktop interactivity
CreateLink /etc/systemd/system/hibernate.target.wants/set-cfs-tweaks.service /usr/lib/systemd/system/set-cfs-tweaks.service
CreateLink /etc/systemd/system/hybrid-sleep.target.wants/set-cfs-tweaks.service /usr/lib/systemd/system/set-cfs-tweaks.service
CreateLink /etc/systemd/system/multi-user.target.wants/set-cfs-tweaks.service /usr/lib/systemd/system/set-cfs-tweaks.service
CreateLink /etc/systemd/system/suspend.target.wants/set-cfs-tweaks.service /usr/lib/systemd/system/set-cfs-tweaks.service
CreateLink /etc/systemd/system/suspend-then-hibernate.target.wants/set-cfs-tweaks.service /usr/lib/systemd/system/set-cfs-tweaks.service

# hera11's battery doesn't work, no point for power management software to run.
if is_laptop && [[ "${HOST_ALIAS}" != hera11 ]]; then
  AddPackage powertop # A tool to diagnose issues with power consumption and power management
  AddPackage tlp      # Linux Advanced Power Management
  CreateLink '/etc/systemd/system/multi-user.target.wants/tlp.service' '/usr/lib/systemd/system/tlp.service'
  # TLP documentation says to mask rfkill in order to avoid conflicts with TLP.
  # See page below (search for the string "rfkill"):
  # https://linrunner.de/en/tlp/docs/tlp-linux-advanced-power-management.html#installation
  CreateLink '/etc/systemd/system/systemd-rfkill.service' '/dev/null'
  CreateLink '/etc/systemd/system/systemd-rfkill.socket' '/dev/null'
  # ethtool is an optional dependency of tlp which adds support to disable wake on LAN.
  AddPackage ethtool # Utility for controlling network drivers and hardware
  # x86_energy_perf_policy is an optional dependency of tlp.
  AddPackage x86_energy_perf_policy # Read or write MSR_IA32_ENERGY_PERF_BIAS
  AddPackage thermald               # The Linux Thermal Daemon program from 01.org
  CreateLink '/etc/systemd/system/dbus-org.freedesktop.thermald.service' '/usr/lib/systemd/system/thermald.service'
  CreateLink '/etc/systemd/system/multi-user.target.wants/thermald.service' '/usr/lib/systemd/system/thermald.service'
fi
