# shellcheck shell=bash
# Dependencies for locally built/installed packages/scripts.

# All of the build tools below are required by multiple packages built in the
# script install-crossdistro-local-packages.
AddPackage git      # the fast distributed version control system
AddPackage make     # GNU make utility to maintain groups of programs
AddPackage python   # Next generation of the python high-level scripting language
AddPackage go       # Core compiler tools for the Go programming language
AddPackage rust     # Systems programming language focused on safety, speed and concurrency
AddPackage nodejs   # Evented I/O for V8 javascript
AddPackage npm      # A package manager for javascript
AddPackage yarn     # Fast, reliable, and secure dependency management

# YouCompleteMe dependencies on Arch Linux- see also:
# https://github.com/Valloric/YouCompleteMe/issues/778
# AddPackage --foreign ncurses5-compat-libs # System V Release 4.0 curses emulation library, ABI 5
# Update 2018-10-14: another workaround for making YouCompleteMe work in Arch is
# to use the system clang library, which I prefer because it avoid adding
# another AUR package. See also:
# https://github.com/Valloric/YouCompleteMe/issues/778#issuecomment-306043611
AddPackage clang    # C language family frontend for LLVM

# ctags is used in Vim.
# AddPackage ctags # Generates an index file of language objects found in source files
# Dependencies for building universal-ctags-git.
AddPackage autoconf # A GNU tool for automatically configuring source code
AddPackage make
# AddPackage --foreign universal-ctags-git # Multilanguage reimplementation of the Unix ctags utility

# tmux-list-words dependencies.
AddPackage ruby                # An object-oriented language for quick and easy programming

# pacutils is used by the aconfmgr save command and if I don't specify to
# install it, it will be uninstalled on every `aconfmgr apply` and then
# reinstalled on every `aconfmgr save`.
AddPackage pacutils            # Helper tools for libalpm

# Needed by the vim jupyter plugin: https://github.com/wmvanvliet/jupyter-vim
# NOTE: As of 2020-01-27, the python 2 version is needed for vim, while the
# python 3 version is needed by neovim.
AddPackage python-jupyter_core # Jupyter core package. A base package on which Jupyter projects rely.
# AddPackage ipython # An enhanced Interactive Python shell.
# AddPackage python-ipykernel # The ipython kernel for Jupyter
IgnorePath '/usr/lib/python3.*/site-packages/debugpy-*.egg-info/*'
