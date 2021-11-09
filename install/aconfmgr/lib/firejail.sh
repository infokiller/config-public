# shellcheck shell=bash

AddPackage firejail # Linux namespaces sandbox program
CreateFile '/etc/ld.so.preload' > /dev/null
id -un >| "$(CreateFile '/etc/firejail/firejail.users')"
CopyFile '/etc/firejail/disable-common.local'

# NOTE: I think apparmor isn't used right now anyway.
cat >> "$(GetPackageOriginalFile firejail '/etc/apparmor.d/local/firejail-default')" <<'EOF'

#########################################################################
# Changes by infokiller
#########################################################################
# Enable running binaries from home directory
owner @HOME/** ix,
# Don't remember why I set this originally in mid 2018, I think it was related
# to error messages in Chrome that may have been fixed by now.
# ptrace,
EOF

_FIREJAILED_BINS=(
  arch-audit
  atool
  audacity
  clamdscan
  clamdtop
  clamscan
  # Firejail breaks vscode remote dev.
  # code
  conky
  cvlc
  dig
  display
  dnscrypt-proxy
  enchant-2
  enchant-lsmod-2
  exiftool
  ffmpeg
  freshclam
  gapplication
  gcloud
  geeqie
  gnome-screenshot
  highlight
  img2txt
  less
  libreoffice
  lobase
  localc
  lodraw
  loffice
  lofromtemplate
  loimpress
  lomath
  loweb
  lowriter
  mediainfo
  mpv
  nslookup
  krita
  ncdu
  odt2txt
  patch
  pavucontrol
  pdftotext
  qbittorrent
  # Not much benefit in firejailing ranger, see my ranger.profile for details.
  # ranger
  redshift
  redshift-gtk
  shellcheck
  soffice
  sqlitebrowser
  # Breaks SSH via jumphosts in VSCode remote extension.
  # ssh
  strings
  transmission-cli
  transmission-create
  transmission-daemon
  transmission-edit
  transmission-remote
  transmission-show
  udiskie
  vlc
  w3m
  wget
  whois
  zathura
)

# NOTE: As of 2020-02-13, I disabled firejail for web browsers because it breaks
# firenvim. I was close to fixing it, but I spent too much time on it.
# Additionally, chromium seems to crash more often.
# _FIREJAILED_BINS+=(
#   brave
#   chromium
#   google-chrome
#   google-chrome-stable
#   firefox
#   vivaldi-stable
#   tor-browser
#   qutebrowser
# )

# Other stuff I want to test before enabling firejail by default.
# _FIREJAILED_BINS+=(
#   code
#   et
#   remmina
# )

for bin in "${_FIREJAILED_BINS[@]}"; do
  if command_exists "${bin}"; then
    CreateLink /usr/local/bin/"${bin}" /usr/bin/firejail
  fi
done
