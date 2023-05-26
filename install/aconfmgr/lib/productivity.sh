# shellcheck shell=bash
# Productivity enhancing packages and config that have no X11/Wayland/GUI or
# networking dependencies. All the config/dotfiles dependencies that don't
# depend on graphics should go here.

AddPackage bash-completion # Programmable completion for the bash shell
AddPackage zsh             # A very advanced and programmable command interpreter (shell) for UNIX
AddPackage zsh-completions # Additional completion definitions for Zsh
cat >> "$(GetPackageOriginalFile --no-clobber filesystem '/etc/shells')" <<'EOF'
/bin/zsh
EOF
AddPackage tmux            # A terminal multiplexer
AddPackage neovim          # Fork of Vim aiming to improve user experience, plugins, and GUIs
AddPackage python-pynvim   # Python client for neovim
# Graphical systems will install gvim which conflicts with vim, so we only
# install it on non-graphical ones.
if ! uses_local_graphics; then
  AddPackage vim # Vi Improved, a highly configurable, improved version of the vi text editor
fi
AddPackage ripgrep             # A search tool that combines the usability of ag with the raw speed of grep
# AddPackage the_silver_searcher # Code searching tool similar to Ack, but faster
AddPackage exa                 # ls replacement
AddPackage git-delta           # Syntax-highlighting pager for git and diff output
AddPackage source-highlight    # Convert source code to syntax highlighted document
AddPackage lesspipe            # an input filter for the pager less
AddPackage duf                 # Disk Usage/Free Utility
AddPackage mlocate             # Merging locate/updatedb implementation
AddPackage bc                  # An arbitrary precision calculator language

AddPackage atool               # A script for managing file archives of various types
AddPackage unrar               # The RAR uncompression program
# gvfs is needed for trash integration (`trash:///`).
AddPackage gvfs                # Virtual filesystem implementation for GIO
# As of 2018-11-03 I'm using systemd user services as a cron replacement.
# AddPackage fcron # Feature-rich cron implementation
AddPackage trash-cli           # Command line trashcan (recycle bin) interface

AddPackage ranger              # A simple, vim-like file manager
# Ranger optional dependencies for file previewing.
AddPackage highlight           # Fast and flexible source code highlighter (CLI version)
AddPackage mediainfo           # Supplies technical and tag information about a video or audio file (CLI interface)
AddPackage odt2txt             # extracts the text out of OpenDocument Texts
AddPackage perl-image-exiftool # Reader and rewriter of EXIF informations that supports raw files
AddPackage mat2                # Metadata removal tool, supporting a wide range of commonly used file formats
IgnorePath '/usr/lib/python3.*/site-packages/mat2-*.egg-info/*'
AddPackage python-pygments     # Python syntax highlighter
IgnorePath '/usr/lib/python3.*/site-packages/Pygments-*.egg-info/*'
AddPackage transmission-cli    # Fast, easy, and free BitTorrent client (CLI tools, daemon and web client)
# For w3m image previews.
AddPackage w3m           # Text-based Web browser as well as pager
# For kitty image previews.
AddPackage python-pillow # Python Imaging Library (PIL) fork

AddPackage broot # Fuzzy Search + tree + cd

AddPackage youtube-dl # A small command-line program to download videos from YouTube.com and a few more sites
AddPackage yt-dlp     # A youtube-dl fork with additional features and fixes
AddPackage aria2      # Download utility that supports HTTP(S), FTP, BitTorrent, and Metalink
