# TODO: This breaks ssh with jump hosts in VSCode, fix this.
quiet
whitelist ${RUNUSER}/gnupg/*/S.gpg-agent.ssh
include /etc/firejail/ssh.profile
