" Based on the example from `:help new-filetype`.
if exists('g:did_load_filetypes')
  finish
endif

augroup filetypedetect
  autocmd BufReadPost,BufNewFile *.zsh nested setfiletype zsh
  autocmd BufReadPost,BufNewFile .envrc nested setfiletype sh
  autocmd BufReadPost,BufNewFile *.xresources nested setfiletype xdefaults
  autocmd BufReadPost,BufNewFile *.xkb nested setfiletype xkb
  " Machine specific user/group files.
  autocmd BufReadPost,BufNewFile */etc/passwd.*,*/etc/shadow.* nested
      \ setfiletype passwd
  autocmd BufReadPost,BufNewFile */etc/group.*,*/etc/gshadow.* nested
      \ setfiletype group
  autocmd BufReadPost,BufNewFile */etc/systemd/*.conf nested
      \ setfiletype systemd
  autocmd BufReadPost,BufNewFile */etc/udev/rules.d/*.rules nested
      \ setfiletype udevrules
  " fontconfig files are actually xml files that are detected correctly, but
  " they have the .conf extension.
  autocmd BufReadPost,BufNewFile *.conf nested
      \ if expand('<afile>:p') !~# '\v\C\/font(s|config)\/conf.d\/.*.conf$' |
      \ setfiletype conf |
      \ endif
  autocmd BufReadPost,BufNewFile *.ipy nested setfiletype python
  autocmd BufReadPost,BufNewFile *.jwcc nested setfiletype jwcc
augroup END
