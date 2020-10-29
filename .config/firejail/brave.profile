include ${HOME}/.config/firejail/browser-common.profile

# According to /etc/firejail/brave.profile brave uses gpg for a built-in
# password manager. 
noblacklist ${HOME}/.config/gnupg
whitelist ${HOME}/.config/gnupg

include /etc/firejail/brave.profile
