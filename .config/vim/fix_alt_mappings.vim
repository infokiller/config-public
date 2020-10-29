scriptencoding utf-8

function! s:FixTerminalVimAltMappings() abort
  let s:CHARS_TO_ESCAPE = {
      \ "\"": "\\\"",
      \ '>': '0',
      \ '|': '\\|',
      \ '~': '0',
  \ }
  " Defines fake Alt keymappings that map to Esc sequences. This makes Alt
  " mappings work in 7-bit terminal mode. See http://stackoverflow.com/a/10216459.
  function! s:DefineFakeAltMappings(begin, end) abort
    let l:begin = a:begin
    let l:end = a:end
    while l:begin < l:end
      let l:c = nr2char(l:begin)
      let l:c = get(s:CHARS_TO_ESCAPE, l:c, l:c)
      " NOTE: The escape key MUST be provided with the raw escape keycode for
      " this to work (i.e. DON'T use `<Esc>` or `\e`).
      exec 'set <M-'.l:c.'>='.l:c
      let l:begin += 1
    endw
  endfunction
  " For some reason the keymappings don't work after this function is called with
  " all printable ascii chars, so I'm calling it on a subset.
  call s:DefineFakeAltMappings(48, 58)   " 0-9
  call s:DefineFakeAltMappings(65, 91)   " A-Z
  call s:DefineFakeAltMappings(97, 123)  " a-z
  call s:DefineFakeAltMappings(42, 47)   " '*' '+' ',' '-' '.'
  call s:DefineFakeAltMappings(95, 96)   " '_'
  " call s:DefineFakeAltMappings(32, 127)
endfunction

" Only terminal vim doesn't have <M-x> keycodes defined, but neovim and GUI vim
" are fine.
if !has('nvim') && !has('gui_running')
  call s:FixTerminalVimAltMappings()
  " Running terminal vim inside tmux inside termite makes <C-Left> and <C-Right>
  " dysfunctional.
  if &term =~# '\v\C^(tmux|screen)'
    " NOTE: The escape key MUST be provided with the raw escape keycode for this
    " to work (i.e. DON'T use `<Esc>` or `\e`).
    set <C-Left>=[1;5D
    set <C-Right>=[1;5C
  endif
endif
