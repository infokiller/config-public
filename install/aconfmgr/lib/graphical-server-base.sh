# shellcheck shell=bash
# Packages for running a display server on the local machine.
# Packages that don't require a local display server (and can work with a remote
# display server) should be configured in graphical-client-base.sh.

# Display drivers.
if is_nvidia_gpu; then
  AddPackage nvidia-dkms            # NVIDIA driver sources for linux
  AddPackage nvidia-utils           # NVIDIA drivers utilities
  # Linux headers are required when using the NVIDIA DKMS drivers.
  AddPackage linux-headers          # Header files and scripts for building modules for Linux kernel
  AddPackage linux-hardened-headers # Header files and scripts for building modules for Linux-hardened kernel
  CopyFile '/etc/pacman.d/hooks/nvidia.hook'
  AddPackage vdpauinfo          # Command line utility for querying the capabilities of a VDPAU device
  # TODO: Consider switching to libva-vdpau-driver-vp9-git or
  # libva-vdpau-driver-chromium from AUR, see:
  # https://wiki.archlinux.org/index.php/Hardware_video_acceleration#Translation_layers
  AddPackage libva-vdpau-driver # VDPAU backend for VA API
fi
if is_intel_gpu; then
  # TODO: Consider removing xf86-video-intel and falling back on the modesetting
  # driver. See note on the Arch Wiki [1] , and the Fedora announcement from
  # 2017 [2].
  # [1] https://wiki.archlinux.org/index.php/Intel_graphics
  # [2] https://www.phoronix.com/scan.php?page=news_item&px=Fedora-Xorg-Intel-DDX-Switch
  AddPackage xf86-video-intel   # X.org Intel i810/i830/i915/945G/G965+ video drivers
  AddPackage vulkan-intel       # Intel's Vulkan mesa driver
  # TODO: detect the Intel GPU version and only install the required one. See:
  # https://wiki.archlinux.org/index.php/Hardware_video_acceleration#Intel
  AddPackage intel-media-driver # Intel Media Driver for VAAPI — Broadwell+ iGPUs
  # AddPackage libva-intel-driver # VA-API implementation for Intel G45 and HD Graphics family
fi
if is_amd_gpu; then
  # NOTE: mesa-vdpau seems to only be needed for AMD GPUs.
  AddPackage xf86-video-amdgpu  # X.org amdgpu video driver
  AddPackage vulkan-radeon      # Radeon's Vulkan mesa driver
  AddPackage libva-mesa-driver  # VA-API implementation for gallium
  AddPackage mesa-vdpau         # Mesa VDPAU drivers
  AddPackage vdpauinfo          # Command line utility for querying the capabilities of a VDPAU device
  AddPackage libva-vdpau-driver # VDPAU backend for VA API
fi

# Touchpad drivers.
AddPackage xf86-input-libinput # Generic input driver for the X.Org server based on libinput
if grep -q 'Synaptics TouchPad' /proc/bus/input/devices; then
  AddPackage xf86-input-synaptics # Synaptics driver for notebook touchpads
fi

# VA-API. Note that although VA-API is targeted at Intel GPUs, this is useful
# for other GPUs as well, since some software (such as Chromium) only supports
# GPU rendering via VA-API, and there are drivers between VA-API and other
# APIs.
AddPackage libva-utils # Intel VA-API Media Applications and Scripts for libva

# X11: display server.
AddPackage xorg-server # Xorg X server

# TODO: Move this to an installation script in the keydope repo and call the
# script from this file. The script will need to support a custom --sysroot.
_configure_keydope() {
  local keydope_dir="${SUBMODULES_DIR}/keydope"
  # NOTE: As of 2019-04-24, keydope is launched from my xsession because:
  # - It's not really needed before graphical login, and it introduces a risk if
  #   there's a bug.
  # - It outputs warnings about the X11 display before the graphical login.
  # CopyFile '/etc/systemd/system/keydope.service'
  cat "${keydope_dir}/etc/udev/rules.d/90-keydope.rules" \
    >| "$(CreateFile '/etc/udev/rules.d/90-keydope.rules')"
  # Verify that uinput is loaded if this is the first time that keydope is
  # configured. We first check if the module is already loaded, because if it's
  # loaded but the kernel was upgraded, modprobe may return an error because of
  # missing kernel modules (for the running kernel).
  # NOTE: We can't pipe lsmod to `grep -q` because lsmod seems to error when its
  # output is closed (which grep -q does as soon as it finds a match).
  if ! grep -q '^uinput' <(lsmod) && ! sudo modprobe uinput; then
    print_warning 'Cannot load uinput module, keydope will not work'
  fi
  cat "${keydope_dir}/etc/modules-load.d/keydope.conf" \
    >| "$(CreateFile '/etc/modules-load.d/keydope.conf')"
  # shellcheck disable=SC2154
  sed -r "s#@USER@#$(id -un)#g; $(printf 's#@KEYDOPE_DIR@#%s#g' "${keydope_dir}")" \
    "${SUBMODULES_DIR}/keydope/etc/sudoers.d/keydope.tmpl" \
    >| "$(CreateFile '/etc/sudoers.d/keydope' 440)"
  CopySymlinkAsFile '/etc/security/limits.d/80-keydope.conf' 440
}

# Used by the handle-monitor-hotplug.service user service.
CopyFile '/opt/ikl/is-x11-ready' 755
# CopyFile '/opt/ikl/launch-logged-script' 755
# NOTE: When using systemd v245 or later, this file isn't needed anymore:
# https://github.com/Yubico/libfido2/issues/131#issuecomment-592931639
# CopySymlinkAsFile '/etc/udev/rules.d/80-tag-fido.rules'
CopySymlinkAsFile '/etc/udev/rules.d/99-keyboard.rules'
# Keydope causes issues with the trackpad in hera11's wireless keyboard, so it's
# disabled there.
if [[ "${HOST_ALIAS}" != hera11 ]]; then
  _configure_keydope
  CopyFile '/etc/udev/rules.d/95-monitor-hotplug.rules'
fi

CopyFile '/etc/udev/rules.d/90-backlight.rules'
if is_laptop && is_intel_gpu; then
  CopyFile '/etc/X11/xorg.conf.d/20-intel-backlight.conf'
fi

# Audio server base system and utils.
AddPackage pulseaudio # A featureful, general-purpose sound server
CreateLink '/etc/systemd/user/sockets.target.wants/pulseaudio.socket' '/usr/lib/systemd/user/pulseaudio.socket'
AddPackage pulseaudio-alsa      # ALSA Configuration for PulseAudio
AddPackage pulseaudio-bluetooth # Bluetooth support for PulseAudio
AddPackage alsa-utils           # An alternative implementation of Linux sound support

CreateLink '/etc/systemd/user/sockets.target.wants/pipewire.socket' '/usr/lib/systemd/user/pipewire.socket'
