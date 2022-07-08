" Based on jsonc.vim from neovim 0.7.
" https://nigeltao.github.io/blog/2021/json-with-commas-comments.html
" Used for tailscale config.

" Based on vim-jsonc syntax
runtime! syntax/jsonc.vim

" Ensure syntax is loaded once, unless nested inside another (main) syntax
" For description of main_syntax, see https://stackoverflow.com/q/16164549
if !exists('g:main_syntax')
  if exists('b:current_syntax') && b:current_syntax ==# 'jwpp'
    finish
  endif
  let g:main_syntax = 'jwpp'
endif

" Based on vim-jsonc syntax
runtime! syntax/jsonc.vim

syntax clear jsonTrailingCommaError

" Set/Unset syntax to avoid duplicate inclusion and correctly handle nesting
let b:current_syntax = 'jwpp'
if g:main_syntax ==# 'jwpp'
  unlet g:main_syntax
endif
