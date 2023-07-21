# shellcheck shell=bash
# Sysadmin packages and config that have no X11/Wayland/GUI or networking
# dependencies.

# Basic development packages, no X11 dependencies.
AddPackage git # the fast distributed version control system
cat >> "$(GetPackageOriginalFile --no-clobber filesystem '/etc/shells')" << 'EOF'
/bin/git-shell
EOF
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
AddPackage gdb             # The GNU Debugger
AddPackage patch           # A utility to apply patch files to original sources
AddPackage pkgconf         # Package compiler and linker metadata toolkit
AddPackage python          # Next generation of the python high-level scripting language
AddPackage go              # Core compiler tools for the Go programming language
AddPackage go-tools        # Developer tools for the Go programming language
AddPackage rust            # Systems programming language focused on safety, speed and concurrency
AddPackage parallel        # A shell tool for executing jobs in parallel
AddPackage socat           # Multipurpose relay
# Android
AddPackage android-tools # Android platform tools
AddPackage android-udev  # Udev rules to connect Android devices to your linux box

AddPackage dash # POSIX compliant shell that aims to be as small as possible
cat >> "$(GetPackageOriginalFile --no-clobber filesystem '/etc/shells')" << 'EOF'
/bin/dash
EOF

AddPackage nodejs # Evented I/O for V8 javascript
IgnorePath '/usr/lib/node_modules/*'
AddPackage npm  # A package manager for javascript
AddPackage yarn # Fast, reliable, and secure dependency management

AddPackage emacs-nativecomp # The extensible, customizable, self-documenting real-time display editor with native compilation enabled
AddPackage bat              # cat clone with Git integration and syntax highlighting support
AddPackage jq               # Command-line JSON processor
AddPackage fd               # Simple, fast and user-friendly alternative to find
AddPackage shellcheck       # Shell script analysis tool
AddPackage expect           # A tool for automating interactive applications
# Disabled because I don't really use it and AUR packages can be a security
# issue.
# AddPackage --foreign howdoi # A code search tool.
AddPackage aspell-en # English dictionary for aspell
AddPackage cloc      # Count lines of code
AddPackage httpie    # cURL for humans
AddPackage qrencode  # C library for encoding data in a QR Code symbol.
AddPackage xonsh     # Python-powered, cross-platform, Unix-gazing shell
cat >> "$(GetPackageOriginalFile --no-clobber filesystem '/etc/shells')" << 'EOF'
/bin/xonsh
EOF
AddPackage yapf       # Python style guide checker
AddPackage pandoc-cli # Conversion between markup formats
# AddPackage termtosvg            # Record terminal sessions as SVG animations
AddPackage hexyl     # Colored command-line hex viewer
AddPackage moreutils # A growing collection of the unix tools that nobody thought to write thirty years ago

add_tex_pkgs() {
  AddPackage texlive-mathscience  # TeX Live - Mathematics, natural sciences, computer science packages
  AddPackage texlive-bibtexextra  # TeX Live - BibTeX additional styles
  AddPackage texlive-fontsextra   # TeX Live - Additional fonts
  AddPackage texlive-formatsextra # TeX Live - Additional formats
  AddPackage texlive-latexextra   # TeX Live - LaTeX additional packages
  AddPackage texlive-pictures     # TeX Live - Graphics, pictures, diagrams
  AddPackage texlive-pstricks     # TeX Live - PSTricks
  AddPackage texlive-publishers   # TeX Live - Publisher styles, theses, etc.
  AddPackage texlive-luatex       # TeX Live - LuaTeX packages
  AddPackage texlive-xetex        # TeX Live - XeTeX and packages
}

# add_tex_pkgs
IgnorePath '/etc/texmf/ls-R'
IgnorePath '/etc/texmf/web2c/fmtutil.cnf'
IgnorePath '/etc/texmf/web2c/updmap.cfg'
IgnorePath '/usr/share/texmf-dist/ls-R'

# shellcheck source=./virt.sh
source "${ACONF_LIB}/virt.sh"
