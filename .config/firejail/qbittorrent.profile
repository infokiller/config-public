# This is needed to be able to download files to other partitions in hera11. Not
# sure why.
ignore apparmor
ignore nodbus
# I'm running scripts on torrent completion, so may need some binaries.
# TODO: Run the external scripts externally to qBittorrent so that
# qBittorrent won't need elevated privileges. Can use inotify on completed
# torrents dir.
ignore private-bin
# ignore private-dev
# When using private-tmp, qBittorrent won't find existing running instances.
ignore private-tmp
include /etc/firejail/qbittorrent.profile
