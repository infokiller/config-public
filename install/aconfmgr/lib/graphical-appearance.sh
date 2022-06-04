# shellcheck shell=bash

# Fonts.
# Croscore, which is used in Chrome OS, provides fonts that are
# metric-compatible with popular non-free fonts such as Arial. There are other
# popular alternatives like Liberation, but Croscore seems to have better
# unicode coverage.
# See also:
# https://wiki.archlinux.org/index.php/Metric-compatible_fonts
AddPackage ttf-croscore           # Chrome OS core fonts
# Noto is my default font. It seems to be a complement to Roboto which was
# designed for Android, but I think it now covers it completely, so I no longer
# install Roboto.
AddPackage noto-fonts             # Google Noto TTF fonts
# noto-fonts-emoji is needed for emojis such as ones from Whatsapp messages.
AddPackage noto-fonts-emoji       # Google Noto emoji fonts
# AddPackage ttf-roboto      # Google's signature family of fonts
# AddPackage ttf-roboto-mono # A monospaced addition to the Roboto type family.
# Monospace programming fonts. I also install Nerd Fonts patched fonts in my
# homedir.
AddPackage ttf-jetbrains-mono     # Typeface for developers, by JetBrains
AddPackage ttf-inconsolata        # Monospace font for pretty code listings and for the terminal
AddPackage ttf-fira-code          # Monospaced font with programming ligatures
# awesome-terminal-fonts is required for some glyhps to appear correctly in my
# terminal apps (zsh prompt, maybe vim).
AddPackage awesome-terminal-fonts # fonts/icons for powerlines
# NOTE: As of 2019-10-20, I'm not sure I need ttf-font-awesome or
# otf-font-awesome.
# AddPackage ttf-font-awesome       # Iconic font designed for Bootstrap
# AddPackage otf-font-awesome       # Iconic font designed for Bootstrap
# NOTE: As of 2019-10-20, I removed adobe-source-code-pro-fonts as I'm using
# inconsolata for programming.
# AddPackage adobe-source-code-pro-fonts # Monospaced font family for user interface and coding environments
# NOTE: As of 2019-10-20, I removed ttf-dejavu because I'm using Roboto and Noto
# as my default fonts, which are developed by Google and have better unicode
# coverage.
# AddPackage ttf-dejavu                  # Font family based on the Bitstream Vera Fonts with a wider range of characters
IgnorePath '/usr/share/fonts/**/fonts.dir'
IgnorePath '/usr/share/fonts/**/fonts.scale'
IgnorePath '/usr/share/fonts/mathjax/*'
# As of 2021-04-11, it seems that files in /etc/fonts/conf.d are symlinks to
# /usr/share/fontconfig/ and they are not owned by the package.
IgnorePath '/etc/fonts/conf.d/*'

# Icons and themes.
AddPackage qt5ct                   # Qt5 Configuration Utility
AddPackage sound-theme-freedesktop # Freedesktop sound theme
AddPackage gnome-themes-extra      # Extra Themes for GNOME Applications
AddPackage hicolor-icon-theme      # Freedesktop.org Hicolor icon theme
AddPackage gnome-icon-theme-extras # Extra GNOME icons for specific devices and file types
AddPackage adwaita-icon-theme      # GNOME standard icons
# breeze is the default for KDE apps.
AddPackage breeze       # Artwork, styles and assets for the Breeze visual style for the Plasma Desktop
AddPackage breeze-icons # Breeze icon themes
# NOTE 2018-12-01: adwaita-qt provides the Adwaita theme (which I'm using in
# GTK) for Qt apps. However, since it's not in the official repos and I don't
# regularly use Qt apps, I'm disabling it, but keeping it for documentation.
# AddPackage --foreign adwaita-qt # A style to bend Qt applications to look like they belong into GNOME Shell (Qt5)
