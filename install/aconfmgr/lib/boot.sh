# shellcheck shell=bash
if is_intel_cpu; then
  AddPackage intel-ucode # Microcode update files for Intel CPUs
  IgnorePath '/boot/intel-ucode.img'
  AddPackage iucode-tool # Tool to manipulate Intel® IA-32/X86-64 microcode bundles
fi
if is_amd_cpu; then
  AddPackage amd-ucode # Microcode update files for AMD CPUs
  IgnorePath '/boot/amd-ucode.img'
fi

CopyFile '/etc/mkinitcpio.conf'
IgnorePath '/etc/mkinitcpio.d/*.preset'

IgnorePath '/boot/initramfs-*.img'
IgnorePath '/boot/lost+found'
IgnorePath '/boot/vmlinuz-*'

_add_btrfs_boot_config() {
  local esp="$1"
  AddPackage --foreign arch-secure-boot # UEFI Secure Boot for Arch Linux + btrfs snapshot recovery
  cat >| "$(CreateFile '/etc/arch-secure-boot/config')" << EOF
ESP="${esp}"
SUBVOLUME_ROOT='@root'
SUBVOLUME_SNAPSHOT='@snapshots/%1/snapshot'
EOF
  IgnorePath "${esp}/EFI/arch"
  IgnorePath "${esp}/recovery.nsh"
  IgnorePath "${esp}/snapshots.txt"
  # Because /boot is formatted as FAT32, so the permissions can be
  # different when mounted on Linux, depending on the mount options. This
  # causes aconfmgr to think that the file has changed, so we ignore it.
  IgnorePath "${esp}/syslinux/syslinux.cfg"
  # EXP: Secure boot via arch-secure-boot
  if [[ "${HOST_ALIAS}" != zeus18 ]]; then
    return
  fi
  IgnorePath '/etc/arch-secure-boot/keys'
  IgnorePath '/etc/secureboot/keys'
  cat >| "$(CreateFile '/etc/kernel/cmdline')" << EOF
root=/dev/mapper/s980pro-luks rootflags=subvol=@root cryptdevice=UUID=f5e23420-5f9d-4d37-90c1-eb2648a365b8:s980pro-luks resume=/dev/mapper/s980pro-luks resume_offset=533760 consoleblank=300
EOF
}

_add_refind_config() {
  local esp="$1"
  AddPackage refind # Rod Smith's fork of rEFIt UEFI Boot Manager - Built with GNU-EFI libs
  CopyFileTo "/boot/refind_linux.conf.${HOST_ALIAS}" '/boot/refind_linux.conf'
  CopyFileTo '/boot/efi/EFI/refind/refind.conf' "${esp}/EFI/refind/refind.conf" 755
  CopyFileTo "/boot/efi/EFI/refind/refind_machine_specific.conf.${HOST_ALIAS}" "${esp}/EFI/refind/refind_machine_specific.conf" 755
  # Pacman hook to upgrade the refind binaries on the EFI partition after the
  # package is updated. See:
  # https://wiki.archlinux.org/index.php/REFInd#Pacman_hook
  CopyFile /etc/pacman.d/hooks/refind.hook 640
  IgnorePath "${esp}/EFI/refind/BOOT.CSV"
  IgnorePath "${esp}/EFI/refind/drivers*"
  IgnorePath "${esp}/EFI/refind/icons/*"
  IgnorePath "${esp}/EFI/refind/refind.conf-sample"
  IgnorePath "${esp}/EFI/refind/icons-backup/*"
  IgnorePath "${esp}/EFI/refind/keys"
  IgnorePath "${esp}/EFI/refind/refind_x64.efi"
}

_add_uefi_config() {
  esp='/boot/efi'
  if is_btrfs_machine; then
    esp='/boot'
    _add_btrfs_boot_config "${esp}"
  fi
  _add_refind_config "${esp}"
  # EFI dir ignores
  IgnorePath "${esp}/EFI/Boot/bootx64.efi"
  IgnorePath "${esp}/EFI/Boot/bootx64.efi.backup*"
  IgnorePath "${esp}/EFI/Boot/original_bootx64.vc_backup"
  IgnorePath "${esp}/EFI/Microsoft/*"
  IgnorePath "${esp}/EFI/VeraCrypt/*"
  IgnorePath "${esp}/EFI/tools"
  IgnorePath "${esp}/System Volume Information/*"
}

_add_boot_config() {
  # Systemd should soon be supported in WSL:
  # https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/
  AddPackage systemd            # system and service manager
  AddPackage systemd-sysvcompat # sysvinit compat for systemd
  if is_uefi; then
    _add_uefi_config
  else
    AddPackage grub # GNU GRand Unified Bootloader (2)
    CopyFileTo "/etc/default/grub.${HOST_ALIAS}" '/etc/default/grub'
    AddPackage os-prober # Utility to detect other OSes on a set of drives
    IgnorePath '/boot/grub/*'
  fi
}

if ! is_wsl; then
  _add_boot_config
fi
