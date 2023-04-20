# shellcheck shell=bash
# System core- mostly packages from the Arch base meta package, plus a few
# other packages that I consider essential.

IgnorePath '/boot/initramfs-*.img'
IgnorePath '/boot/lost+found'
IgnorePath '/boot/vmlinuz-*'
if ! is_wsl; then
  # Systemd should soon be supported in WSL:
  # https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/
  AddPackage systemd            # system and service manager
  AddPackage systemd-sysvcompat # sysvinit compat for systemd
  if is_uefi; then
    ESP='/boot/efi'
    if is_btrfs_machine; then
      ESP='/boot'
    AddPackage --foreign arch-secure-boot # UEFI Secure Boot for Arch Linux + btrfs snapshot recovery
    cat >| "$(CreateFile '/etc/arch-secure-boot/config')" << EOF
ESP="${ESP}"
SUBVOLUME_ROOT='@root'
SUBVOLUME_SNAPSHOT='@snapshots/%1/snapshot'
EOF
      IgnorePath '/etc/arch-secure-boot/keys'
      IgnorePath '/etc/secureboot/keys'
      IgnorePath "${ESP}/EFI/arch"
      IgnorePath "${ESP}/recovery.nsh"
      IgnorePath "${ESP}/snapshots.txt"
    fi
    AddPackage refind                     # Rod Smith's fork of rEFIt UEFI Boot Manager - Built with GNU-EFI libs
    CopyFileTo "/boot/refind_linux.conf.${HOST_ALIAS}" '/boot/refind_linux.conf'
    CopyFileTo '/boot/efi/EFI/refind/refind.conf' "${ESP}/EFI/refind/refind.conf" 755
    CopyFileTo "/boot/efi/EFI/refind/refind_machine_specific.conf.${HOST_ALIAS}" "${ESP}/EFI/refind/refind_machine_specific.conf" 755
    # Pacman hook to upgrade the refind binaries on the EFI partition after the
    # package is updated. See:
    # https://wiki.archlinux.org/index.php/REFInd#Pacman_hook
    CopyFile /etc/pacman.d/hooks/refind.hook 640
    IgnorePath "${ESP}/EFI/refind/BOOT.CSV"
    IgnorePath "${ESP}/EFI/refind/drivers*"
    IgnorePath "${ESP}/EFI/refind/icons/*"
    IgnorePath "${ESP}/EFI/refind/refind.conf-sample"
    IgnorePath "${ESP}/EFI/refind/icons-backup/*"
    IgnorePath "${ESP}/EFI/refind/keys"
    IgnorePath "${ESP}/EFI/refind/refind_x64.efi"

    IgnorePath "${ESP}/EFI/Boot/bootx64.efi"
    IgnorePath "${ESP}/EFI/Boot/bootx64.efi.backup*"
    IgnorePath "${ESP}/EFI/Boot/original_bootx64.vc_backup"
    IgnorePath "${ESP}/EFI/Microsoft/*"
    IgnorePath "${ESP}/EFI/VeraCrypt/*"
    IgnorePath "${ESP}/EFI/tools"
    IgnorePath "${ESP}/System Volume Information/*"
  else
    AddPackage grub # GNU GRand Unified Bootloader (2)
    CopyFileTo "/etc/default/grub.${HOST_ALIAS}" '/etc/default/grub'
    AddPackage os-prober # Utility to detect other OSes on a set of drives
    IgnorePath '/boot/grub/*'
  fi
fi

AddPackage base                # Minimal package set to define a basic Arch Linux installation
AddPackage linux               # The Linux kernel and modules
AddPackage linux-firmware      # Firmware files for Linux
AddPackage kernel-modules-hook # Keeps your system fully functional after a kernel upgrade
CreateLink /etc/systemd/system/basic.target.wants/linux-modules-cleanup.service /usr/lib/systemd/system/linux-modules-cleanup.service
IgnorePath '/usr/lib/modules/*'

AddPackage coreutils  # The basic file, shell and text manipulation utilities of the GNU operating system
AddPackage bash       # The GNU Bourne Again shell
AddPackage file       # File type identification utility
AddPackage filesystem # Base Arch Linux files
AddPackage findutils  # GNU utilities to locate files
AddPackage pacman     # A library-based package manager with dependency support
AddPackage glibc      # GNU C Library
AddPackage grep       # A string search utility
AddPackage gzip       # GNU compression utility
AddPackage bzip2      # A high-quality data compression program
AddPackage zip        # Compressor/archiver for creating and modifying zipfiles
AddPackage unzip      # For extracting and viewing files in .zip archives
AddPackage less       # A terminal based program for viewing text files
AddPackage vi         # The original ex/vi text editor
AddPackage util-linux # Miscellaneous system utilities for Linux
AddPackage which      # A utility to show the full path of commands
AddPackage gawk       # GNU version of awk
AddPackage tar        # Utility used to store, backup, and transport files
AddPackage e2fsprogs  # Ext2/3/4 filesystem utilities
AddPackage shadow     # Password and account management tool suite with support for shadow files and PAM
AddPackage diffutils  # Utility programs used for creating patch files
AddPackage sed        # GNU stream editor
AddPackage man-db     # A utility for reading man pages
AddPackage man-pages  # Linux man pages
AddPackage make       # GNU make utility to maintain groups of programs
AddPackage procps-ng  # Utilities for monitoring your system and its processes
AddPackage psmisc     # Miscellaneous procfs tools

AddPackage sudo # Give certain users the ability to run some commands as root
CopyFile '/etc/sudoers.d/custom' 440
# CopyFile '/etc/sudoers.d/pm_utils' 440

if is_intel_cpu; then
  AddPackage intel-ucode # Microcode update files for Intel CPUs
  IgnorePath '/boot/intel-ucode.img'
  AddPackage iucode-tool # Tool to manipulate Intel® IA-32/X86-64 microcode bundles
fi

# Generated files with no apparent benefit for managing.
IgnorePath '/etc/machine-id'
IgnorePath '/etc/adjtime'
IgnorePath '/etc/hostname'

HOST_SPECIFIC_FILES=(
  /etc/crypttab
  /etc/fstab
)
for file in "${HOST_SPECIFIC_FILES[@]}"; do
  # shellcheck disable=2154
  [[ -r "${config_dir}/files/${file}.${HOST_ALIAS}" ]] && CopyFileTo "${file}.${HOST_ALIAS}" "${file}"
done

_verify_safe_group_update() {
  local wheel_id
  wheel_id="$(grep --text wheel /etc/group | cut --delimiter=: --fields=3)"
  local updated_wheel_id
  updated_wheel_id="$(grep wheel "${config_dir}/files/etc/group" |
    cut --delimiter=: --fields=3)"
  if ((wheel_id != updated_wheel_id)); then
    print_warning 'Wheel group ID changed! You must copy the files manually from a root shell and then login again to avoid being locked out'
    return 1
  fi
}

config_users_groups() {
  # NOTE: I used to set the mod to 0 (IIRC this was recommended by Lynis), but
  # it breaks shadow.service.
  # local shadow_mod=0
  local shadow_mod=600
  if ((${ACONF_UPDATE_USERS:-1})); then
    _verify_safe_group_update || exit 1
    # Conventions of system groups for Linux:
    # - https://wiki.archlinux.org/index.php/DeveloperWiki:UID_/_GID_Database
    # - https://wiki.debian.org/SystemGroups
    # - https://git.archlinux.org/svntogit/packages.git/tree/trunk/sysusers?h=packages/filesystem
    # See also the output from `systemd-sysusers --cat-config`
    CopyFile '/etc/passwd'
    CopyFile '/etc/shadow' "${shadow_mod}"
    CopyFile '/etc/group'
    CopyFile '/etc/gshadow' "${shadow_mod}"
  else
    IgnorePath '/etc/passwd'
    IgnorePath '/etc/shadow'
    IgnorePath '/etc/group'
    IgnorePath '/etc/gshadow'
  fi

  # Backups for group, passwd, shadow, and gshadow. See also:
  # https://stackoverflow.com/q/7872907/1014208
  IgnorePath '/etc/shadow-'
  IgnorePath '/etc/gshadow-'
  IgnorePath '/etc/group-'
  IgnorePath '/etc/passwd-'
}

config_users_groups

CopyFile '/etc/mkinitcpio.conf'
IgnorePath '/etc/mkinitcpio.d/*.preset'

# Verify integrity of passwd, shadow, group, and gshadow.
# shellcheck disable=2154
# TODO: This is disabled because it will give errors if the current /etc/group
# is inconsistent with the given files. To fix this, it's possible to use the
# `--root` flag, or add a separate test to the repo.
# pwck --read-only "${config_dir}/files/etc/passwd" \
#   "${config_dir}/files/etc/shadow"
# grpck --read-only "${config_dir}/files/etc/group" \
#   "${config_dir}/files/etc/gshadow"

CreateLink '/etc/os-release' '../usr/lib/os-release'

cat >> "$(GetPackageOriginalFile pacman '/etc/makepkg.conf')" << 'EOF'
#########################################################################
# Changes by infokiller
#########################################################################

CFLAGS+=" -fstack-protector-strong"
CXXFLAGS+=" -fstack-protector-strong"

MAKEFLAGS+=" -j$(nproc)"

# Use as many threads as CPU cores
COMPRESSXZ+=(--threads=0)
COMPRESSZST+=(--threads=0)
EOF
# TODO: Move pacman.conf changes to a separate file and use the 'Include'
# directive in order to minimize the changes to the distributed file.
CopyFile '/etc/pacman.conf'
# Refresh pacman mirrors if they're not up to date.
"${REPO_ROOT}/.my_scripts/sysadmin/pacman-refresh-mirrors"
# Pacman GPG data.
IgnorePath '/etc/pacman.d/gnupg/gpg.conf'
IgnorePath '/etc/pacman.d/gnupg/gpg-agent.conf'
IgnorePath '/etc/pacman.d/gnupg/.gpg-v21-migrated'
IgnorePath '/etc/pacman.d/gnupg/S.*'
IgnorePath '/etc/pacman.d/gnupg/crls.d/DIR.txt'
IgnorePath '/etc/pacman.d/gnupg/openpgp-revocs.d'
IgnorePath '/etc/pacman.d/gnupg/private-keys-v1.d'
IgnorePath '/etc/pacman.d/gnupg/pubring.gpg'
IgnorePath '/etc/pacman.d/gnupg/pubring.gpg~'
IgnorePath '/etc/pacman.d/gnupg/reader_0.status'
IgnorePath '/etc/pacman.d/gnupg/secring.gpg'
IgnorePath '/etc/pacman.d/gnupg/tofu.db'
IgnorePath '/etc/pacman.d/gnupg/trustdb.gpg'

CreateLink '/etc/systemd/system/getty.target.wants/getty@tty1.service' '/usr/lib/systemd/system/getty@.service'

AddPackage ntp
CopyFile /etc/ntp.conf
CreateLink '/etc/systemd/system/multi-user.target.wants/ntpd.service' '/usr/lib/systemd/system/ntpd.service'

IgnorePath '/lost+found'
IgnorePath '/etc/.updated'
IgnorePath '/etc/.pwd.lock'
IgnorePath '/etc/ld.so.cache'
IgnorePath '/usr/share/info/dir'
