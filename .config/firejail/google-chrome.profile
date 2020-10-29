include ${HOME}/.config/firejail/browser-common.profile

noblacklist ${HOME}/.config/chrome-flags.conf
whitelist ${HOME}/.config/chrome-flags.conf

include /etc/firejail/google-chrome.profile
