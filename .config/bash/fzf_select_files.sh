# This library is shared by:
# - The shell config for interactive usage
# - vim
# - ranger

fzf_select_path() {
  sed "s%^${HOME}%~%" |
    fzf --select-1 --exit-0 --toggle-sort=ctrl-r \
      --preview='terminal-file-preview --image-preview {}' \
      --preview-window=right:60% "$@" |
    sed "s%^~%${HOME}%"
}

fzf_select_dir() {
  fzf_select_path "$@"
}

fzf_select_file() {
  fzf_select_path "$@"
}
