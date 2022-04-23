# Installation

## Setting up a new workstation: high level process

- [Partition the disk for Windows](#partition-the-disk-for-windows)

- [Install and set up](#install-windows-10) Windows 10.

- [Partition the disk for Linux](#partition-the-disk-for-linux).

- [Install and set up Linux](#set-up-linux).

- [Set up Chrome](#set-up-chrome)

- Test and verify system stability.

- Save disk image for future restore.

## Partition the disk for Windows

The Windows 10 installation doesn't give the option to select the partition
sizes and therefore you need to set them up beforehand. Microsoft has
[a short guide](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/configure-uefigpt-based-hard-drive-partitions)
about setting up the needed partitions, which also has
[an included script](https://goo.gl/R4fjYh) for setting up a new disk. I tweaked
this for my needs and saved it in
[~/install/create-windows-partitions.bat](../install/create-windows-partitions.bat).

The partition layout created in this step is as following:

| Number | Short description                      | Size              | Filesystem | Comments                                                                                                                                                |
| ------ | -------------------------------------- | ----------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1      | EFI System Partition                   | 550 MiB - 800 MiB | FAT32      | Needs to be at least 550MiB in size ([explanation](https://www.rodsbooks.com/efi-bootloaders/principles.html)), but much more than that seems wasteful. |
| 2      | MSR, AKA Microsoft Reserved Partition  | 16 MiB            | N/A        |                                                                                                                                                         |
| 3      | Windows "Healthy (Recovery partition)" | 450 MiB           |            |
| 4      | Windows main OS partition              | 75 GiB            | NTFS       |                                                                                                                                                         |

NOTE: As of 2018-06-22, on zeus18, the order of partitions is actually
different, probably because it was somehow done in the Windows installation.

### Steps

1. Boot into the Windows 10 installation media.
2. Click Shift+F10 to go the admin cmd.
3. Identify the number of the target disk by running `diskpart` and then
   `list disk`.
4. Copy the
   [create-windows-partitions.bat](../install/create-windows-partitions.bat)
   script to a USB drive.
5. Edit the copied file by replacing `???` with the target disk number from
   diskpart.
6. Insert the USB drive to the target machine.
7. Switch to the USB drive with `E:` (replace `E` with the correct drive
   letter).
8. Run `diskpart /s <script-path>` with `<script-path>` set to the location of
   the script.

## Install and set up Windows 10

- Boot into the Windows 10 installation media.

- Select the "Custom" installation type and choose the 75 GiB partition created
  for Windows.

- After the installation is complete, boot normally into Windows.

- If networking is not available out of the box, install networking drivers from
  a USB.

- Install all windows updates, which should contain all (or most) of the needed
  drivers. This may take multiple iterations of checking for updates, installing
  them, and rebooting.

  - Install any remaining drivers if needed. To verify that all the hardware is
    detected correctly, go to Device Manager and verify that there are no
    warnings.

- If this is a VM, see also the
  [Trello card](https://trello.com/c/msnAYmXM/276-windows-10-vm).

- Tweak Windows settings

  - Download <https://gitlab.com/infokiller/Win10-Initial-Setup-Script> and run
    one of the cmd scripts depending on the environment.

  - Set touchpad scrolling to be non-natural.

- Enable full disk encryption with Bitlocker and/or Veracrypt. Bitlocker is
  probably more secure and stable because it's supported and used internally by
  Microsoft. However, it's harder to decrypt Bitlocker encrypted partitions from
  Linux.

  - [Bitlocker with Linux dual boot guide](https://www.ctrl.blog/entry/dual-boot-bitlocker-device.html)

  - [Veracrypt Windows 10 guide](https://www.howtogeek.com/234826/how-to-enable-full-disk-encryption-on-windows-10/)

### Install Windows packages

> NOTE: I started scripting this in my fork of Win10-Initial-Setup-Script.

[winget](https://github.com/microsoft/winget-cli) is an official CLI package
manager by Microsoft. As of 2020-11-26 it is still in preview, but in the long
term it should be the best solution. Other Alternatives are Chocolately (see
instructions below) and [Scoop](https://github.com/lukesampson/scoop) which
looks interesting but I haven't tested it yet.

#### winget

- Install winget: As of 2020-11-26, winget is still in preview and hence manual
  installation is needed by downloading and installing the
  [latest release](https://github.com/microsoft/winget-cli/releases/latest).

- Install packages: open PowerShell as admin and run:

  ```powershell
  winget install windirstat Microsoft.WindowsTerminal copyq ...
  ```

#### Chocolately

- Install Chocolately: open PowerShell as admin and run:

  ```powershell
  Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  ```

- Install packages: open PowerShell as admin and run:

  > NOTE: On Windows it's better to install Chrome and not Chromium because
  > Chrome gets automatic updates. Additionally, the version of Chromium in
  > Chocolately was very old the last time I checked (2019-12-28).

  > NOTE: The backticks in the powershell command are line continuations
  > (similar to a backslash in bash).

  ```powershell
  choco install -y 7zip copyq windirstat autohotkey vlc inconsolata paint.net `
    notepadplusplus git winrar googlechrome google-backup-and-sync veracrypt `
    malwarebytes qbittorrent wox ueli f.lux python vscode sysinternals handbrake
  ```

### Notes

- As of 2020-01-07,
  [DisableWinTracking](https://github.com/10se1ucgo/DisableWinTracking) is
  almost fully contained in win10-initial-setup-script, but has two potentially
  useful additions that I may find useful in the future:
  - Blocking IPs in Windows Firewall that are known to be tracking.
  - Disable known tracking domains in the hosts file.
- As of 2020-01-07,
  [Debloat-Windows-10](https://github.com/W4RH4WK/Debloat-Windows-10) seems
  fully contained in Win10-Initial-Setup-Script. The latter also seems to have
  higher quality code, better documentation, and is easier to customize.
- TODO: Look into <https://github.com/henrypp/simplewall> for controlling
  internet access of apps.

### Deprecated software installation

#### Ninite

- Download [Ninite](https://ninite.com/) installer with:

  - Chrome
  - Paint.net
  - WinDirStat
  - qBittorrent
  - 7-Zip
  - WinRAR
  - VLC
  - Audacity
  - Spotify
  - HandBrake
  - Google Backup and Restore
  - Python
  - Java 8
  - .NET 4.7.1
  - ~~Essentials (no longer needed in Windows 10)~~

- Install more software from
  [Awesome Windows](https://github.com/Awesome-Windows/Awesome):

  - Microsoft Office (and/or LibreOffice)
  - f.lux
  - Ditto
  - Launcher: Launchy/Wox/etc
  - File manager (still not sure which one is best)
  - ~~Babun shell (turns out the project is dead)~~
  - GVim
  - Passmark (benchmarking)

## Partition the disk for Linux

Installing Windows 10 partitions the disk, and this step creates additional
partitions for Linux and a shared partition for Windows and Linux. This step
should be performed from a shell in a Linux Live ISO. The Arch Linux ISO seems
to be a good fit for this job. Partitions configured in this step:

> NOTE: Consider adding a GPT partition with the Arch Linux ISO for rescue.

| Number | Short description                       | Size                 | Filesystem | Comments                                                                                                                                   |
| ------ | --------------------------------------- | -------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| 5      | Linux boot partition                    | 250 MiB - 500 MiB    | ext4       | As of 2018-06-22 my desktop uses about 200MiB of space in this partition for 3 kernels                                                     |
| 6      | Encrypted container partition for Linux | 250 GiB - max        | crypto_LUK | Contains an LVM volume group with 3 volumes for root, home, and swap. root only needs about 40 GiB including `/var`, or 25 GiB without it. |
| 7      | Shared data partition                   | Remaining disk space | NTFS       | Optional, only useful if sharing lots of data between Linux and Windows                                                                    |

## Set up Linux

### Arch Linux

We are now going to boot into the Arch ISO, partition the target disk, and
configure LVM on LUKS so that all the Linux related files (including swap) are
encrypted.

The commands below assume that there is an active internet connection, which is
needed for syncing the system datetime and for getting packages from Pacman.

Check internet connection:

```sh
ping -c 3 google.com
```

If there's no internet connection, this is probably a driver issue that needs to
be fixed before continuing.

The next step is to enable to connect via ssh so that the next steps can be done
from a machine I'm more comfortable with.

> NOTE: If running in VirtualBox, the network adapter type should be changed
> from "NAT" to "Bridged Adapter" so that the guest machine will be accessible
> to the host machine. If this was done after the machine booted, dhcpcd will
> need to be restarted using `systemctl restart dhcpcd`.

Next, sshd needs to be started and a root password set:

```sh
systemctl start sshd
passwd root
```

Now it should be possible to SSH from the host to the guest and run the base
installation script.

Next, **review and set the variables in install/bootstrap-archlinux**. Then,
determine the ip address of the guest by running `ip addr`, and copy the
installation script:

```sh
TARGET_MACHINE_IP=''
scp -p ~/install/bootstrap-archlinux ~/install/bootstrap-archlinux-chroot "root@${TARGET_MACHINE_IP}":/
```

The last step is to ssh to the guest and run the copied installation script:

```sh
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "root@${TARGET_MACHINE_IP}"
/bootstrap-archlinux --machine-name <name>
```

Copying the script to the guest machine is needed (vs piping the local script to
ssh) because the script may have interactive prompts.

### WSL installation notes

I installed Arch on WSL using <https://github.com/yuk7/ArchWSL> The following
issues were encountered.

- Clipboard integration with Windows doesn't work unless I run an xserver in
  Windows and point DISPLAY to it. I can work around that by using `clip.exe`
  (provided by WSL) to copy to clipboard, and `powershell.exe Get-Clipboard` to
  paste. See also: <https://github.com/microsoft/WSL/issues/1069>

- WSL doesn't use systemd, so most of the settings and configuration files I use
  are not relevant. It seems that it's possible to run systemd on WSL 2 using a
  workaround: <https://github.com/yuk7/ArchWSL/wiki/Known-issues#fakeroot>

#### Useful references

- <https://github.com/pigmonkey/spark/blob/master/INSTALL.md>
- <https://github.com/archmirak/archlinux-fde-uefi/blob/master/LVM_on_LUKS>
- <https://wiki.archlinux.org/index.php/installation_guide.>

### Debian and derivatives

Download the
[minimal Ubunto iso](https://help.ubuntu.com/community/Installation/MinimalCD)
and boot into it to start the Linux installation process. When prompted on
"Software selection", don't select anything or select "Manual package
selection". Follow the steps to complete a basic installation. Steps that are
automated in the Arch installation, but not in Debian (yet) include:

- Configure fstab. This depends on which drives/partitions are regularly used by
  the device. See the fstab files in the repo for a reference.

- Install git and curl if needed: `sudo apt install -y git curl`

> TODO: Add more specific instructions for following the installation media to
> make sure my settings are consistent across installations.
>
> TODO: Verify these are the only changes needed in Debian.

### Cross distro setup

#### Clone and install config repo

1. [Create a Gitlab access token](https://gitlab.com/-/profile/personal_access_tokens)
   with only the `read_repository` permission. This will be used to authenticate
   to Gitlab for cloning the repo.

1. Clone the config repos (replace `hostname` below for the ssh key):

   ```sh
   bash <(curl -fsSL 'https://raw.githubusercontent.com/infokiller/config-public/master/install/bootstrap-config-repos') ~/.ssh/id_ed25519_hostname
   ```

1. Run the installation script: `~/install/install-new-workstation` The
   installation script might need to run multiple times with reboots in between
   (this should have been fixed but I'm not 100% sure). After the script
   succeeds:

   1. Log in to hub (enter Github username and password when prompted):

   ```sh
   hub api repos/infokiller/web-search-navigator
   ```

   1. Initialize history: `sync-config-repos`

#### Generate CopyQ encryption keys

Open CopyQ, then go to Preferences (`Ctrl+P`) -> Item -> Encryption and create
new encryption keys (with a UI button).

#### Whitelist needed USB devices in USBGuard

List blocked devices: `sudo usbguard list-devices --blocked` Allow a device:
`sudo usbguard allow-device <device_filter>` Edit config file directly:
`sudoedit /etc/usbguard/rules.conf` Reload service:
`sudo systemctl restart usbguard.service`

You should also whitelist the host in the `aconfmgr` function
`is_usbguard_enabled`.

## Set up Chrome profile

- Login to chrome (`google-chrome-home` on Linux), and wait till all extensions
  are synced. Then, proceed to the next sections.

### Log in to extensions

- Log in to LastPass
- Log in to Pocket
- Log in to [WhatsApp Web](https://web.whatsapp.com) and enable notifications.
- Log in to [Android Messages](https://messages.android.com/) and enable
  notifications.

### Fix extension settings that are not synced

- tabctl: set keyboard shortcuts in <chrome://extensions/shortcuts>
  > NOTE: As of 2020-02-03, on Chromium 79 tabctl keyboard shortcuts were synced
  > automatically to a new machine I setup.
- uBlock Origin:
  - Restore settings from `~/.config/ublock-settings.json`
  - Go to "Filter lists" tab and import from cloud storage (buttons at the top)
- LastPass:
  - Set "Automatically Log out after idle (mins)" to 1440 (24 hours).
  - Configure hotkeys so that `Ctrl+[`/`Ctrl+]` fill in the previous/next login.
- Google Dictionary:
  - Set pop-up display to trigger with Alt key
  - Check "Store words I look up"
  - Click Save
- TransOver:
  - Translate into **Hebrew** when I **point at word**
  - Only show word translation when I hold the **alt** key
  - Only show selection translation when I hold the **alt** key
- Violentmonkey: sync settings to Google Drive and verify scripts were synced.
- Privacy Badger: `Options` -> `Manage Data` ->
  `Import disabled sites from cloud`
- WorldBrain's Memex: disable keyboard shortcuts and sidebar

### Limit extensions site access

- Fakespot:
  - `*://*.amazon.com/*`
  - `*://*.amazon.co.uk/*`
  - `*://*.amazon.de/*`
  - `*://*.amazon.es/*`
  - `*://*.amazon.it/*`
- AliPrice Price Tracker:
  - `*://*.aliexpress.com/*`
  - `*://*.aliprice.com/*`
  - `*://*.banggood.com/*`
  - `*://*.gearbest.com/*`
  - `*://*.joybuy.com/*`
- MonkeyECHO:
  - `*://*.gearbest.com/*`
- Wikiwand:
  - `*://*.wikipedia.org/*`
- Violentmonkey:
  - `https://greasyfork.org/*`
  - `https://openuserjs.org/*`
  - Websites used by scripts
- PDF Viewer for Vimium C: allow access to file URLs
- Coudy Calculator: disable all site access
- Cently: On click.
- Honey: On click.

### DEPRECATED

These steps that are not needed anymore or are related to extensions that are no
longer used.

- Remove most of the extension icons from the menu bar
- Log in to Grammarly
- Log in to Pushbullet
- The Great Suspender: Change automatic suspension duration to 1 day as of
  2018-10-17 The Great Suspender seems to sync settings.
- RescueTime: log in and uncheck in the settings "I'm already using the full
  RescueTime application on this computer"
- Mate Translate:
  - Enable double click translation
  - Change default translation to English-Hebrew
  - Change translation keybinding to `Alt+t`

## Known issues

- Some Chrome settings are not synced and this requires manual work.

## Resources

- [Arch linux installation guide](https://wiki.archlinux.org/index.php/installation_guide)
- [Arch linux general recommendations](https://wiki.archlinux.org/index.php/General_recommendations)
- <http://www.tldp.org/LDP/Linux-Filesystem-Hierarchy/html/etc.html>
