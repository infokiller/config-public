# shellcheck shell=bash
# System core- mostly packages from the Arch base meta package, plus a few
# other packages that I consider essential.

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
# NOTE: pacman.conf supports the 'Include' directive, but it's not easy to put
# all my customizations there, because it must be written in the [options]
# section (or the repo-specific sections for repo-specific customizations), and
# there is no robust way to add the include line to the file in the correct
# location.
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
