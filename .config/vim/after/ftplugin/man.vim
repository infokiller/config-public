if has('nvim')
  let g:no_man_maps = 1
  " Copied from /usr/share/nvim/runtime/ftplugin/man.vim
  nnoremap <silent> <buffer> gO         :<C-U>call man#show_toc()<CR>
  nnoremap <silent> <buffer> <C-]>      :<C-U>Man<CR>
  nnoremap <silent> <buffer> <C-T>      :<C-U>call man#pop_tag()<CR>
else
  setlocal nomodified nomodifiable
  setlocal tabstop=8 foldlevel=20 colorcolumn=0
end
