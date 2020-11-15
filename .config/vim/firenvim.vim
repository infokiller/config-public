Plug 'glacambre/firenvim'

nnoremap <C-R> <Nop>

" Note that <C-Q> is already used by TGS (The Great Suspender).
" As of 2020-11-15, I no longer use TGS, and I also think that <C-Q> is not
" necessary for TGS because I can just refresh the page with <C-R>.
noremap <expr> <C-Q> vimrc#GetCommandForMode('call firenvim#hide_frame()')
noremap! <expr> <C-Q> vimrc#GetCommandForMode('call firenvim#hide_frame()')
" Mapping <Esc><Esc> turns out to be very annoying because then vim waits for
" the second escape each time I want to exit normal mode.
" noremap <expr> <Esc><Esc> vimrc#GetCommandForMode('call firenvim#focus_page()')
" noremap! <expr> <Esc><Esc> vimrc#GetCommandForMode('call firenvim#focus_page()')

" Since Firenvim is running in a browser, the undo/redo remappings I defined
" for terminals don't apply so instead I need to remap the non-terminal
" undo/redo keys (Ctrl-z and Ctrl-Shift-z). However, the latter can't be
" mapped, so I'm waiting for Firenvim support:
" https://github.com/glacambre/firenvim/issues/574
"
" nmap <C-Z> <Plug>(MyUndo)
" nmap <C-T> <Plug>(RepeatRedo)
" inoremap <C-Z> <C-O>u
" inoremap <C-T> <C-O><C-R>
" xnoremap <C-Z> <Esc>ugv
" xnoremap <C-T> <Esc><C-R>gv
" " NOTE: As of 2019-09-19, I could not find a way to use undo/redo in vim's
" " command line, so I'm just disabling the regular keybindings to avoid the
" " insertion of weird characters.
" cnoremap <C-Z> <Nop>
" cnoremap <C-T> <Nop>

let s:english_layout_cmd = 'call vimrc#kb_layout#SetEnglishLayout()'
let s:alt_layout_cmd = 'call vimrc#kb_layout#SetAltLangLayout()'
let s:toggle_layout_cmd = 'call vimrc#kb_layout#ToggleLanguageLayout()'

nnoremap <silent> <expr> <M-J> vimrc#GetCommandForMode(s:english_layout_cmd)
nnoremap <silent> <expr> <M-L> vimrc#GetCommandForMode(s:alt_layout_cmd)
nnoremap <silent> <expr> <M-:> vimrc#GetCommandForMode(s:toggle_layout_cmd)
inoremap <silent> <expr> <M-J> vimrc#GetCommandForMode(s:english_layout_cmd)
inoremap <silent> <expr> <M-L> vimrc#GetCommandForMode(s:alt_layout_cmd)
inoremap <silent> <expr> <M-:> vimrc#GetCommandForMode(s:toggle_layout_cmd)

" https://github.com/glacambre/firenvim/issues/717#issuecomment-712632995
let s:IGNORED_KEYS = ['<C-1>', '<C-2>', '<C-3>', '<C-4>', '<C-5>', '<C-6>', 
      \ '<C-7>', '<C-8>', '<C-9>', '<C-0>']

let g:firenvim_config = {
    \ 'globalSettings': {
        \ 'ignoreKeys': { 
        \     'all': s:IGNORED_KEYS,
        \ },
    \ },
    \ 'localSettings': {
        \ '.*': {
            \ 'selector': 'textarea, div[role="textbox"], div[contenteditable="true"]',
            \ 'priority': 0,
            \ 'takeover': 'once',
            \ 'cmdline': 'firenvim',
        \ },
        \ 'ticktick\.com': {
            \ 'selector': '.td-content textarea',
            \ 'priority': 1,
        \ },
    \ },
\ }

" URLs where firenvim should be disabled by default. It can still be manually
" enabled using a keyboard shortcut.
" Note that some disabled URLs are used in iframes of websites I want to
" disable (for example `about:blank` is used in Google Docs). See:
" https://github.com/glacambre/firenvim/issues/546
" Office 365 subdomains of officeapps.live.com:
" ppc-(powerpoint|word-edit)
" frc-excel
let s:FIRENVIM_DISABLED_URLS = [
      \ 'about:blank',
      \ '\b\.co\.il',
      \ '(docs|mail)\.google\.com',
      \ 'web\.whatsapp\.com',
      \ 'outlook.office.com/mail',
      \ '.*.officeapps.live.com',
      \ 'script.google.com',
      \ 'facebook\.com',
      \ 'excalidraw\.com',
      \ 'overleaf\.com',
\ ]
for s:url in s:FIRENVIM_DISABLED_URLS
  let g:firenvim_config['localSettings'][s:url] = {'priority': 1, 'selector': ''}
endfor

set termguicolors
let &guifont = 'MyMono:h12'

let g:lightline = get(g:, 'lightline', {})
let g:lightline['active'] = get(g:lightline, 'active', {})
let g:lightline['active']['left'] = [ ['mode', 'spell', 'paste'] ]

function! s:IsFirenvimActive(event) abort
  if !exists('*nvim_get_chan_info')
    return 0
  endif
  let l:ui = nvim_get_chan_info(a:event.chan)
  return has_key(l:ui, 'client') && has_key(l:ui.client, 'name') &&
      \ l:ui.client.name is# 'Firenvim'
endfunction

" Settings that are always applied for a minimal UI.
set showtabline=1
set shortmess+=F
set colorcolumn=0
set textwidth=200
set noruler
" Settings that are used by default for a minimal UI, but get overridden if
" the window size is sufficient (see below).
set cmdheight=1
set laststatus=0
set showmode
set nocursorline
set nonumber

function! s:OnFirenvimIframeLoad() abort
  if &lines >= 10
    set laststatus=2
    set cmdheight=2
    set noshowmode
    set cursorline
    if &columns >= 10
      set number
    endif
  endif
  call VimrcEnableSpellCheck(0)
  " The input to feedkeys is queued for processing, so the keys will actually
  " be typed only after the autocmd that triggers this function is done.
  call feedkeys("\<C-L>", 'n')
  " If the buffer is empty, start in insert mode.
  if empty(getline('.'))
    call feedkeys('i', 'n')
  endif
endfunction

function! s:OnUIEnter(event) abort
  if !s:IsFirenvimActive(a:event)
    return
  endif
endfunction

augroup vimrc
  autocmd BufReadPost,BufNewFile github.com_*,gitlab.com_*,trello.com_* 
      \ setfiletype markdown
  autocmd BufReadPost * ++once call <SID>OnFirenvimIframeLoad()
  " Firenvim has an issue when combined with autosaving in certain websites,
  " see: https://github.com/glacambre/firenvim/issues/479
  autocmd BufEnter ticktick.com_*,outlook.office.com_* let g:vimrc_autowrite_buffers = 0
  " Jupyterlab
  autocmd BufEnter localhost_*,127.0.0.1_* call VimrcDisableSpellCheck()

  " autocmd UIEnter * call <SID>OnUIEnter(deepcopy(v:event))
augroup END

" startinsert
