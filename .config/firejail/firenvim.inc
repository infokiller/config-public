whitelist ${HOME}/.local/share/firenvim
noblacklist ${HOME}/.local/share/firenvim
read-only ${HOME}/.local/share/firenvim
whitelist /usr/share/vim
whitelist /usr/share/nvim
whitelist ${HOME}/.config/vim
read-only ${HOME}/.config/vim
whitelist ${HOME}/.local/share/nvim
noblacklist ${HOME}/.local/share/nvim
read-only ${HOME}/.local/share/nvim
whitelist ${HOME}/.local/share/vim
noblacklist ${HOME}/.local/share/vim
read-only ${HOME}/.local/share/vim
whitelist ${HOME}/.local/share/wakatime
whitelist ${HOME}/.config/nvim
noblacklist ${HOME}/.config/nvim
read-only ${HOME}/.config/nvim
whitelist ${HOME}/.vimrc
noblacklist ${HOME}/.vimrc
read-only ${HOME}/.vimrc
# whitelist ${HOME}/submodules/vim/firenvim
whitelist ${HOME}/submodules/vim
read-only ${HOME}/submodules/vim
# .profile is used by vimrc.
whitelist ${HOME}/.profile
noblacklist ${HOME}/.profile
read-only ${HOME}/.profile
ignore noexec ${HOME}
ignore apparmor
