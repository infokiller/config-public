scriptencoding utf-8

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                            Buffers, windows, tabs                            "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Split down and right which feels more natural and is consistent with i3.
set splitbelow
set splitright
" Maximum number of tab pages to be opened by the |-p| command line argument or
" the ":tab all" command. From vim-sensible.
set tabpagemax=50
" When jumping to a buffer (for example, by selecting an entry in the quickfix
" window), jump to the first open window with that buffer.
" NOTE: As of 2018-12-15, this is disabled because I find this behavior annoying
" when I want to force vim to open the buffer in a specific window.
" set switchbuf=useopen
" Fuzzy buffer selection
" [Buffers] Jump to an existing window if possible
" let g:fzf_buffers_jump = 1

if g:VSCODE_MODE
  " VSCode commands based on:
  " https://github.com/asvetliakov/vscode-neovim/blob/master/vim/vscode-window-commands.vim#L21
  function! s:RepeatVSCodeNotify(count, cmd) abort
    let l:count = a:count ? a:count : 1
    for i in range(1, l:count)
      call VSCodeNotify(a:cmd)
    endfor
  endfunction

  " See https://github.com/asvetliakov/vscode-neovim/blob/master/vim/vscode-window-commands.vim
  let s:win_left = ":\<C-U>call VSCodeNotify('workbench.action.navigateLeft')\<CR>"
  let s:win_down = ":\<C-U>call VSCodeNotify('workbench.action.navigateDown')\<CR>"
  let s:win_up = ":\<C-U>call VSCodeNotify('workbench.action.navigateUp')\<CR>"
  let s:win_right = ":\<C-U>call VSCodeNotify('workbench.action.navigateRight')\<CR>"
  let s:win_move_left = ":\<C-U>call VSCodeNotify('workbench.action.moveEditorToLeftGroup')\<CR>"
  let s:win_move_down = ":\<C-U>call VSCodeNotify('workbench.action.moveEditorToBelowGroup')\<CR>"
  let s:win_move_up = ":\<C-U>call VSCodeNotify('workbench.action.moveEditorToAboveGroup')\<CR>"
  let s:win_move_right = ":\<C-U>call VSCodeNotify('workbench.action.moveEditorToRightGroup')\<CR>"
  let s:win_max = ":\<C-U>call VSCodeNotify('workbench.action.toggleEditorWidths')\<CR>"
  let s:win_split_down = ":\<C-U>call VSCodeNotify('workbench.action.splitEditorDown')\<CR>"
  let s:win_split_right = ":\<C-U>call VSCodeNotify('workbench.action.splitEditorRight')\<CR>"
  let s:win_prev = ":\<C-U>call VSCodeNotify('workbench.action.focusPreviousGroup')\<CR>"
  let s:win_resize_eq = ":\<C-U>call VSCodeNotify('workbench.action.evenEditorWidths')\<CR>"
  let s:win_inc_height = "\<SID>RepeatVSCodeNotify(v:count, 'workbench.action.increaseViewSize')\<CR>"
  let s:win_dec_height = "\<SID>RepeatVSCodeNotify(v:count, 'workbench.action.decreaseViewSize')\<CR>"
  let s:win_inc_width = s:win_inc_height
  let s:win_dec_width = s:win_dec_height
  " `Wq` and `Wqall` are defined in vscode-neovim
  let s:win_quit = ":\<C-U>Wq\<CR>"
  let s:win_quit_all = ":\<C-U>Wqall\<CR>"
  let s:buf_close = ":\<C-U>call VSCodeNotify('workbench.action.closeActiveEditor')\<CR>"
  let s:buf_next = ":\<C-U>call VSCodeNotify('workbench.action.nextEditor')\<CR>"
  let s:buf_prev = ":\<C-U>call VSCodeNotify('workbench.action.previousEditor')\<CR>"
else
  let s:win_left = "\<C-W>h"
  let s:win_down = "\<C-W>j"
  let s:win_up = "\<C-W>k"
  let s:win_right = "\<C-W>l"
  let s:win_move_left = "\<C-W>H"
  let s:win_move_down = "\<C-W>J"
  let s:win_move_up = "\<C-W>K"
  let s:win_move_right = "\<C-W>L"
  let s:win_max = "\<C-W>_\<C-W>\<Bar>"
  let s:win_split_down = "\<C-W>s"
  let s:win_split_right = "\<C-W>v"
  let s:win_prev = "\<C-W>p"
  let s:win_resize_eq = "\<C-W>="
  let s:win_inc_height = "\<C-W>+"
  let s:win_dec_height = "\<C-W>-"
  let s:win_inc_width = "\<C-W><"
  let s:win_dec_width = "\<C-W>>"
  " NOTE: I previously used `:q!` instead of `:q`, but this silently quits
  " read-only modified buffers (losing their changes). `:q` alone works well
  " with my autosync settings.
  let s:win_quit = ":\<C-U>q\<CR>"
  let s:win_quit_all = ":\<C-U>wqall\<CR>"
  Plug 'mhinz/vim-sayonara', { 'on': 'Sayonara' }
  let s:buf_close = ":\<C-U>Sayonara!\<CR>"
  let s:buf_next = ":\<C-U>bn\<CR>"
  let s:buf_prev = ":\<C-U>bp\<CR>"
endif

" Navigating windows.
exec 'nnoremap <Leader>wj ' . s:win_left
exec 'xnoremap <Leader>wj ' . s:win_left
exec 'nnoremap <Leader>wk ' . s:win_down
exec 'xnoremap <Leader>wk ' . s:win_down
exec 'nnoremap <Leader>wi ' . s:win_up
exec 'xnoremap <Leader>wi ' . s:win_up
exec 'nnoremap <Leader>wl ' . s:win_right
exec 'xnoremap <Leader>wl ' . s:win_right
" Moving windows.
exec 'nnoremap <Leader>wJ ' . s:win_move_left
exec 'xnoremap <Leader>wJ ' . s:win_move_left
exec 'nnoremap <Leader>wK ' . s:win_move_down
exec 'xnoremap <Leader>wK ' . s:win_move_down
exec 'nnoremap <Leader>wI ' . s:win_move_up
exec 'xnoremap <Leader>wI ' . s:win_move_up
exec 'nnoremap <Leader>wL ' . s:win_move_right
exec 'xnoremap <Leader>wL ' . s:win_move_right
" Resizing/focusing on windows.
exec 'nnoremap <Leader>wf ' . s:win_max
" Now that h is free use h and v for horizontal and vertical splitting. The
" splitting is done in a way that is consistent with i3 and tmux.
exec 'nnoremap <Leader>wv ' . s:win_split_down
exec 'xnoremap <Leader>wv ' . s:win_split_down
exec 'nnoremap <Leader>wh ' . s:win_split_right
exec 'xnoremap <Leader>wh ' . s:win_split_right
" Go to previous window
exec 'nnoremap <Leader>w<Leader>w ' . s:win_prev
exec 'xnoremap <Leader>w<Leader>w ' . s:win_prev

" Window resizing
exec 'nnoremap <Leader>w= ' . s:win_resize_eq
exec 'xnoremap <Leader>w= ' . s:win_resize_eq
exec 'nnoremap <Leader>w+ ' . s:win_inc_height
exec 'xnoremap <Leader>w+ ' . s:win_inc_height
exec 'nnoremap <Leader>w- ' . s:win_dec_height
exec 'xnoremap <Leader>w- ' . s:win_dec_height
exec 'nnoremap <Leader>w> ' . s:win_inc_width
exec 'xnoremap <Leader>w> ' . s:win_inc_width
exec 'xnoremap <Leader>w< ' . s:win_dec_width
exec 'nnoremap <Leader>w_ ' . s:win_resize_eq

exec 'nnoremap <Leader>wq ' . s:win_quit
exec 'nnoremap <Leader>q ' . s:win_quit
exec 'nnoremap <Leader>wQ ' . s:win_quit_all
exec 'nnoremap <Leader>Q ' . s:win_quit_all

" Buffer stuff with b.
nnoremap b <Nop>
xnoremap b <Nop>
nnoremap B <Nop>
xnoremap B <Nop>
exec 'nnoremap bd ' . s:buf_close
exec 'nnoremap bp ' . s:buf_prev
exec 'nnoremap bn ' . s:buf_next
exec 'nnoremap [b ' . s:buf_prev
exec 'nnoremap ]b ' . s:buf_next
nnoremap <Leader>e :<C-U>call vimrc#actions#LastBuffer()<CR>

" Example usage: `:EditExOutput autocmd`
command! -nargs=+ -complete=command EditExOutput
    \ call vimrc#EditExOutput(<q-args>, <q-mods>)

" TODO: Improve vimrc handling for vscode mode: define actions that are only
" mapped in the main vimrc, and will be overridden in vscode mode.
if g:VSCODE_MODE
  nnoremap <expr> <C-L> vimrc#GetCommandForMode('nohlsearch')
  xnoremap <expr> <C-L> vimrc#GetCommandForMode('nohlsearch')
  inoremap <expr> <C-L> vimrc#GetCommandForMode('nohlsearch')
  snoremap <expr> <C-L> vimrc#GetCommandForMode('nohlsearch')

  nnoremap <silent> <Leader>d :<C-U>call VSCodeNotify('workbench.action.showCommands')<CR>
  " nnoremap <silent> <Leader>D :<C-U>History:<CR>
  " nnoremap <silent> <Leader>sh :<C-U>History/<CR>
  nnoremap <silent> <Leader>E :<C-U>call VSCodeNotify('workbench.action.quickOpen')<CR>
  " nnoremap <silent> <Leader>sl :<C-U>BLines<CR>
  " nnoremap <silent> <Leader>sL :<C-U>Lines<CR>
  " nnoremap <silent> <Leader>C :<C-U>Colors<CR>
  nnoremap <silent> <Leader>o :<C-U>call VSCodeNotify('workbench.action.gotoSymbol')<CR>
  nnoremap <silent> <Leader>O :<C-U>call VSCodeNotify('workbench.action.showAllSymbols')<CR>
  nnoremap <silent> <Leader>ff :<C-U>call VSCodeNotify('fzf-quick-open.runFzfFile')<CR>
  nnoremap <silent> bl :<C-U>call VSCodeNotify('workbench.action.showAllEditorsByMostRecentlyUsed')<CR>

  " Mnemonic: Code Execute
  nnoremap <silent> <Leader>cee :<C-U>call VSCodeNotify('python.datascience.runcurrentcell')<CR>
  nnoremap <silent> <Leader>cen :<C-U>call VSCodeNotify('python.datascience.runcurrentcelladvance')<CR>
  nnoremap <silent> <Leader>cei :<C-U>call VSCodeNotify('python.datascience.runallcellsabove.palette')<CR>
  nnoremap <silent> <Leader>cek :<C-U>call VSCodeNotify('python.datascience.runcurrentcellandallbelow.palette')<CR>
  nnoremap <silent> <Leader>cea :<C-U>call VSCodeNotify('python.datascience.runallcells')<CR>

  finish
endif  " g:VSCODE_MODE

" Resize window, no equivalent in VSCode.
nnoremap <Leader>w_ <C-W>_
xnoremap <Leader>w_ <C-W>_

Plug 'simeji/winresizer', { 'on':  [ 'WinResizerStartResize',
    \ 'WinResizerStartMove', 'WinResizerStartFocus'] }
" Since the plugin is lazy loaded, we map C-r directly.
nnoremap <Leader>wr :<C-U>WinResizerStartResize<CR>
let g:winresizer_start_key = '<C-R>'
let g:winresizer_keycode_left = 106
let g:winresizer_keycode_down = 107
let g:winresizer_keycode_right = 108
let g:winresizer_keycode_up = 105

Plug 'infokiller/fzf', {'dir': g:submodules_dir . '/terminal/fzf'}
" fzf.vim needs to be renamed because of a maktaba bug which outputs errors when
" plugins have a dot in their name.
Plug 'infokiller/fzf.vim', {'dir': g:plugins_dir . '/fzf-vim'}

nnoremap <silent> bl :<C-U>Buffers<CR>

function! s:FzfFilesNoIgnore(args, bang) abort
  try
    let prev_default_command = $FZF_DEFAULT_COMMAND
    let $FZF_DEFAULT_COMMAND = 'rg --no-ignore --files'
    call fzf#vim#files(a:args, fzf#vim#with_preview(), a:bang)
  finally
    let $FZF_DEFAULT_COMMAND = prev_default_command
  endtry
endfunction

" Like Files, but don't respect gitignore and other ignore files.
command! -bang -nargs=? -complete=dir FilesNoIgnore
    \ call <SID>FzfFilesNoIgnore(<q-args>, <bang>0)

" https://github.com/junegunn/fzf.vim/issues/865#issuecomment-684804262
function! s:FormatJumpsForFzf() abort
  let l:cout = ''
  redir =>> l:cout
  silent jumps
  redir END
  let l:lines = split(cout, "\n")
  return l:lines[:0] + reverse(l:lines[1:-2])
  " return reverse(split(cout, "\n"))
endfunction
function! GoToJump(jump) abort
  let l:num = split(a:jump, '\v\C\s+')[0]
  execute 'normal! ' . l:num . "\<c-o>"
endfunction
" TODO: Add preview
command! FzfJumps call fzf#run(fzf#wrap({
    \ 'source': s:FormatJumpsForFzf(),
    \ 'sink': function('GoToJump'),
    \ 'options': '--header-lines=1'
    \ }))

" Since autosaving is enabled by default, saving manually should be pretty rare.
nnoremap <Leader>fs :<C-U>w<CR>
nnoremap <silent> <Leader>ff :<C-U>Files<CR>
nnoremap <silent> <Leader>fd :<C-U>Files <C-R>=expand('%:h')<CR><CR>
nnoremap <silent> <Leader>fF :<C-U>FilesNoIgnore<CR>

Plug 'mtth/scratch.vim', { 'on': ['Scratch', 'ScratchSelection'] }
let g:scratch_top = 1
let g:scratch_no_mappings = 1
nnoremap <M-s> :<C-U>Scratch<CR>
xnoremap <M-s> :<C-U>ScratchSelection<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                     Tmux                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'christoomey/vim-tmux-navigator'
" Plug 'benmills/vimux'

" Navigating windows without using the Ctrl+W prefix, integrated with tmux.

" Don't navigate out of vim when tmux is zoomed.
let g:tmux_navigator_disable_when_zoomed = 1
let g:tmux_navigator_no_mappings = 1

" NOTE: <M-;> doesn't work here and below, not sure why. Also, adding
" this keybinding makes vim identify key sequences like Esc-k as <Alt-k>, which
" causes it to shift focus to another pane.
" nnoremap <silent> <M-;> :<C-U>TmuxNavigateLast<CR>
nnoremap <silent> <M-j> :<C-U>TmuxNavigateLeft<CR>
nnoremap <silent> <M-k> :<C-U>TmuxNavigateDown<CR>
nnoremap <silent> <M-i> :<C-U>TmuxNavigateUp<CR>
nnoremap <silent> <M-l> :<C-U>TmuxNavigateRight<CR>
nnoremap <silent> <M-w> :<C-U>TmuxNavigatePrevious<CR>
xnoremap <silent> <M-j> <Esc>:TmuxNavigateLeft<CR>gv
xnoremap <silent> <M-k> <Esc>:TmuxNavigateDown<CR>gv
xnoremap <silent> <M-i> <Esc>:TmuxNavigateUp<CR>gv
xnoremap <silent> <M-l> <Esc>:TmuxNavigateRight<CR>gv
xnoremap <silent> <M-w> <Esc>:TmuxNavigatePrevious<CR>
inoremap <silent> <M-j> <C-O>:TmuxNavigateLeft<CR>
inoremap <silent> <M-k> <C-O>:TmuxNavigateDown<CR>
inoremap <silent> <M-i> <C-O>:TmuxNavigateUp<CR>
inoremap <silent> <M-l> <C-O>:TmuxNavigateRight<CR>
inoremap <silent> <M-w> <C-O>:TmuxNavigatePrevious<CR>
" The commands below exit the command line before navigating. The typed command
" line should still be in the history, so no data should be lost.
cnoremap <silent> <M-j> <C-C>:TmuxNavigateLeft<CR>
cnoremap <silent> <M-k> <C-C>:TmuxNavigateDown<CR>
cnoremap <silent> <M-l> <C-C>:TmuxNavigateUp<CR>
cnoremap <silent> <M-i> <C-C>:TmuxNavigateRight<CR>
cnoremap <silent> <M-w> <C-C>:TmuxNavigatePrevious<CR>
tnoremap <silent> <M-j> <C-\><C-N>:TmuxNavigateLeft<CR>
tnoremap <silent> <M-k> <C-\><C-N>:TmuxNavigateDown<CR>
tnoremap <silent> <M-l> <C-\><C-N>:TmuxNavigateUp<CR>
tnoremap <silent> <M-i> <C-\><C-N>:TmuxNavigateRight<CR>
tnoremap <silent> <M-w> <C-\><C-N>:TmuxNavigatePrevious<CR>

" Focus events should work out of the box in neovim:
" https://github.com/tmux-plugins/vim-tmux-focus-events/issues/1#issuecomment-562432723
if !has('nvim')
  Plug 'tmux-plugins/vim-tmux-focus-events'
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                          Directory/File navigation                           "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Recognize paths that have ${VAR}
set isfname+={,}
set path+=~/.local/bin

Plug 'rafaqz/ranger.vim'
Plug 'airblade/vim-rooter'

let g:rooter_manual_only = 1

" Copy current file base name to clipboard
nnoremap <Leader>yn :<C-U>let @+ = expand('%:t')<CR>
" Copy current file full path to clipboard
nnoremap <Leader>yp :<C-U>let @+ = expand('%:p')<CR>
" Copy current dir to clipboard
nnoremap <Leader>yd :<C-U>let @+ = expand('%:p:h')<CR>

nnoremap <Leader>cdh :<C-U>cd<CR>
nnoremap <Leader>cdf :<C-U>cd %:p:h<CR>
nnoremap <Leader>cdd :<C-U>RangerCD<CR>
nnoremap <Leader>cdl :<C-U>RangerLCD<CR>
" nnoremap <Leader>cde :<C-U>RangerEdit<CR>
nnoremap <Leader>fe :<C-U>RangerEdit<CR>
nnoremap <expr> <Leader>cdr ":\<C-U>cd " . FindRootDirectory() . '<CR>'

" Breaks gnupg plugin- see https://github.com/bogado/file-line/issues/39
" Plug 'bogado/file-line'

" NOTE: As of 2018-12-18 I played with francoiscabrol/ranger.vim and it didn't
" work well for me (it didn't replace the built in file manager correctly).
" Plug 'rbgrouleff/bclose.vim' | Plug 'francoiscabrol/ranger.vim'
" Prevent the ranger.vim plugin from mapping keys.
" let g:ranger_map_keys = 0
" Use ranger instead of netrw for navigating files. See also:
" https://github.com/francoiscabrol/ranger.vim#opening-ranger-instead-of-netrw-when-you-open-a-directory
" let g:NERDTreeHijackNetrw = 0
" let g:ranger_replace_netrw = 1

" Plug 'scrooloose/nerdtree', {'on': 'NERDTreeToggle'}
" Toggle NerdTree
" nnoremap <Leader>fe :<C-U>NERDTreeToggle<CR>

" Plug 'justinmk/vim-gtfo'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                        Multi-files search and replace                        "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NOTE: As of 2019-09-27, I switched to using ferret, since vim-grepper doesn't
" have good support for passing options to the underlying tools.
" Plug 'mhinz/vim-grepper', { 'on': ['Grepper', 'GrepperRg'] }
" let g:grepper = {}
" let g:grepper.tools = ['rg', 'ag', 'ack', 'grep', 'git']
" " Key for switching to the next grep tool on Grepper's prompt. Note that for the
" " commands I mapped below, I use `-noprompt` so it will always use the first
" " one.
" let g:grepper.prompt_mapping_tool = '<C-T>'
" let g:airline#extensions#grepper#enabled = 1
"
" function! s:RunGrepper(grepper_options, grep_args) abort
"   let l:grep_args = a:grep_args
"   if empty(l:grep_args)
"     let l:grep_args = shellescape(expand('<cword>'))
"   endif
"   execute printf('Grepper %s -query %s', a:grepper_options, l:grep_args)
" endfunction
"
" command! -nargs=* -bar Grep
"     \ call <SID>RunGrepper('-noprompt', <q-args>)
" command! -nargs=* -bar GrepBuffers
"     \ call <SID>RunGrepper('-buffers -noprompt', <q-args>)
" nnoremap <Leader>sa :<C-U>Grep<Space>
" xnoremap <expr> <Leader>sa
"     \ '""y:Grep --fixed-strings -- <C-R>=shellescape(@")<CR>'
" nnoremap <Leader>sb :<C-U>GrepBuffers<Space>
" xnoremap <expr> <Leader>sb
"     \ '""y:GrepBuffers --fixed-strings -- <C-R>=shellescape(@")<CR>'

" Ferret is lazy loaded by default, so no need to use vim-plug for this.
Plug 'wincent/ferret'
let g:FerretMap = 0
let g:FerretQFMap = 0
let g:FerretHlsearch = 0
let g:FerretMaxResults = 10000
let g:FerretExecutableArguments = {
    \ 'rg': '--vimgrep --no-heading --max-columns 512'
\ }

function! s:RunFerret(ferret_cmd, query) abort
  let l:query = a:query
  if empty(l:query)
    let l:query = expand('<cword>')
  endif
  execute printf('%s %s', a:ferret_cmd, l:query)
endfunction

command! -nargs=* -complete=customlist,ferret#private#ackcomplete Ferret
    \ call <SID>RunFerret('Ack', <q-args>)
command! -nargs=* -complete=customlist,ferret#private#backcomplete FerretBuffers
    \ call <SID>RunFerret('Back', <q-args>)
nnoremap <Leader>sa :<C-U>Ferret<Space>
xnoremap <Leader>sa
    \ ""y:Ack --fixed-strings -- <C-R>=substitute(@", " ", "\\\\ ", "g")<CR>
nnoremap <Leader>sb :<C-U>FerretBuffers<Space>
xnoremap <Leader>sb
    \ ""y:Back --fixed-strings -- <C-R>=substitute(@", " ", "\\\\ ", "g")<CR>

" Plug 'dyng/ctrlsf.vim', { 'on': ['CtrlSF'] }
" Uncomment to make changes within a single buffer undone as a single undo unit.
" let g:qf_join_changes = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                  Diff mode                                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" See: https://vimways.org/2018/the-power-of-diff/
" internal: use the new internal diff library available since vim 8.1.360.
" filler: use filler lines when synchronized windows are scrolled.
" vertical: use vertical splits.
" algorithm:histogram: use histogram based algorithm from libxdiff.
if v:version >= 801 && has('patch0562')
  set diffopt=internal,filler,vertical,algorithm:histogram
else
  set diffopt=filler,vertical
endif

function! s:MaybeDiffBindings() abort
  if &diff
    " Navigate diff changes with Ctrl+{p,n}
    nnoremap <buffer> <C-P> [c
    nnoremap <buffer> <C-N> ]c
    nnoremap <buffer> du :<C-U>diffupdate<CR>
    nnoremap <buffer> dp :<C-U>diffput<CR>
    nnoremap <buffer> dg :<C-U>diffget<CR>
  else
    silent! nunmap <buffer> <C-P>
    silent! nunmap <buffer> <C-N>
    silent! nunmap <buffer> du
    silent! nunmap <buffer> dp
    silent! nunmap <buffer> dg
  endif
endfunction

augroup vimrc
  autocmd BufEnter * call s:MaybeDiffBindings()
augroup END

" DiffUpdated is needed for diffs triggered by fugitive to work.
" DiffUpdated is not supported in older versions of vim.
if exists('##DiffUpdated')
  augroup vimrc
    autocmd BufEnter,DiffUpdated * call s:MaybeDiffBindings()
  augroup END
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                   Sessions                                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NOTE: As of 2020-04-25, vim-session has been unmaintained for more than 5
" years.
" Plug 'xolox/vim-misc' | Plug 'xolox/vim-session'
" " Don't load the session automatically.
" let g:session_autoload        = 'no'
" " Automatically save an existing session before exiting vim.
" let g:session_autosave        = 'yes'
" " Auto-save sessions every 2 minutes.
" let g:session_autosave_periodic = 2
" let g:session_default_to_last = 'yes'
" let g:session_directory       = Concat(g:VIM_DATA_DIR, '/session/')
" " Add command aliases that start with the prefix "Session" for easy
" " autocomplete
" let g:session_command_aliases = 1


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                             General UI settings                              "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set title               " Set terminal/window title.
set showmatch           " Show matching brackets.
set number              " Print the line number in front of each line.
set ruler               " Show the line and column number of the cursor
                        " position.
set scrolloff=5         " Keep at least 5 lines above/below.
set sidescrolloff=5     " Keep at least 5 lines left/right.
" WARNING: The following setting makes scrolling lines slow, esepcially when the
" viewport is large. The reason is that for each line navigation the screen has
" the bo redrawn completely. For details see:
" https://www.reddit.com/r/vim/comments/fdwax/just_a_reminder_cursorline_and_relativenumber/
set cursorline          " Highlight current line.
set cmdheight=2         " Set height of the command window.
set lazyredraw          " Stops macros rendering every step.
" Very long lines will cause a performance degredation. Try to mitigate this by
" limiting the syntax highlighting to N first chars.
set synmaxcol=300
" Highlight one column to the right of the `textwidth` setting
set colorcolumn=+1
" Disable the bell which I don't use. This is already the default in nvim.
set belloff=all

" Line wrapping {{{
" Wrap lines longer than window width. Already the default.
set wrap
" wrap long lines at a character in 'breakat' rather than at the last character
" that fits on the screen.
set linebreak
" Wrap lines with indentation. Tip from:
" https://bluz71.github.io/2017/05/15/vim-tips-tricks.html
set breakindent
" Reduce wrapping intentation if the text width is less than 30 chars wide.
set breakindentopt=min:30
" Relevant signs: ↳, ↪
" NOTE: As of 2019-11-12, this causes an overlap of the icon with the previous
" char.
" let s:showbreak_sign = '↪'
let s:showbreak_sign = '↳'
function! s:SetShowBreak(scope, width) abort
  call vimrc#Log('Setting showbreak to width %d in scope %s', a:width, a:scope)
  let l:value = s:showbreak_sign .
        \ repeat(' ', a:width - strwidth(s:showbreak_sign))
  if a:scope is# 'global'
    let &g:showbreak = l:value
  else
    let &l:showbreak = l:value
  endif
endfunction

call s:SetShowBreak('global', 4)

" TODO: This doesn't work when shiftwidth is set from ftplugin/lang.vim.
augroup vimrc
  autocmd OptionSet shiftwidth call <SID>SetShowBreak(v:option_type,
        \ 2*v:option_new)
augroup END
" }}} Line wrapping

" Use consistent settings for vim and neovim (neovim changed the defaults for
" these).
set fillchars=vert:\|,fold:·
set shortmess-=F

" Make tabs and trailing spaces visible when requested.
" set listchars=tab:>-,trail:·,eol:$,nbsp:☣
set listchars=tab:»\ ,trail:·,eol:↲,precedes:‹,extends:›,nbsp:☣
" tab:\!\ ,,extends:❯,precedes:❮
nnoremap <silent> <Leader>tw :<C-U>set list!<CR>

" Use `:RainbowParentheses` to enable.
Plug 'junegunn/rainbow_parentheses.vim'
" Use `:RainbowToggle` to toggle.
Plug 'luochen1990/rainbow'
" Disable by default.
let g:rainbow_active = 0

Plug 'junegunn/vim-peekaboo'

" According to the docs of vim-cursorword, who is written by a profficient vim
" hacker, it is ten times faster than brightest.
Plug 'itchyny/vim-cursorword'
" Highlights the word under the cursor and all its visible occurrences the
" focused window.
" Plug 'osyo-manga/vim-brightest', { 'on':  [ 'BrightestHighlight',
"     \ 'BrightestEnable', 'BrightestDisable', 'BrightestToggle', ] }
" let g:brightest_enable = 0
" Mnemonic: toggle highlight
" nnoremap <silent> <Leader>th :<C-U>BrightestToggle<CR>
let g:cursorword = 0
nnoremap <silent> <Leader>th :<C-U>call vimrc#ToggleOption('g:cursorword') <Bar>
    \ if exists('*cursorword#matchadd') <Bar> 
    \ call cursorword#matchadd() <Bar> endif<CR>

" Consider instead of vim-gitgutter - it also shows git changes, so could
" potentially replace it.
" NOTE: As of 2019-09-18, this plugin didn't work for me in both vim and nvim,
" even with vim-gitgutter disabled. vim-gitgutter also seems to be better
" maintained.
" Plug 'tomtom/quickfixsigns_vim'
" Plug 'ryanoasis/vim-devicons'

" Plug 'liuchengxu/vim-which-key',
"     \ { 'on': ['WhichKey', 'WhichKey!', 'WhichKeyVisual', 'WhichKeyVisual!'] }
" " Don't make me wait additional time after timeoutlen has passed.
" let g:which_key_timeout = 0
" nnoremap <silent> <Space> :<C-U>WhichKey '<Space>'<CR>
" xnoremap <silent> <Space> :<C-U>WhichKeyVisual '<Space>'<CR>

" Smooth scrolling for <C-D> and <C-U>. Makes the direction of the scrolling
" clearer but a bit (intentionally) slower. Not sure yet if I like it.
" Plug 'psliwka/vim-smoothie'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                   Fzf                                        "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'infokiller/fzf', {'dir': g:submodules_dir . '/terminal/fzf'}
" fzf.vim needs to be renamed because of a maktaba bug which outputs errors when
" plugins have a dot in their name.
Plug 'infokiller/fzf.vim', {'dir': g:plugins_dir . '/fzf-vim'}

" Fuzzy select mappings
nmap <Leader><Tab> <Plug>(fzf-maps-n)
xmap <Leader><Tab> <Plug>(fzf-maps-x)
omap <Leader><Tab> <Plug>(fzf-maps-o)

" nnoremap <silent> <Leader>d :<C-U>call
"     \ fzf#vim#commands({'down': '~40%', 'options': '--no-extended +x'})<CR>
nnoremap <silent> <Leader>d :<C-U>Commands<CR>
nnoremap <silent> <Leader>D :<C-U>History:<CR>
nnoremap <silent> <Leader>sh :<C-U>History/<CR>
nnoremap <silent> <Leader>E :<C-U>History<CR>
nnoremap <silent> <Leader>C :<C-U>Colors<CR>
nnoremap <silent> <Leader>h :<C-U>Helptags<CR>
nnoremap <silent> <Leader>sl :<C-U>BLines<CR>
nnoremap <silent> <Leader>sL :<C-U>Lines<CR>

" Copied from:
" https://github.com/szymonmaszke/dotfiles/blob/master/nvim/settings/vim-plug.vim
function! s:plug_help_sink(line) abort
  let l:dir = g:plugs[a:line].dir
  for l:pat in ['doc/*.txt', 'README.md']
    let l:match = get(split(globpath(l:dir, l:pat), "\n"), 0, '')
    if len(l:match)
      execute 'tabedit' l:match
      return
    endif
  endfor
  tabnew
  execute 'Explore' l:dir
endfunction

command! PlugHelp call fzf#run(fzf#wrap({
  \ 'source': sort(keys(g:plugs)),
  \ 'sink':   function('s:plug_help_sink')}))

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                Indent guides                                 "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NOTE: As of 2018-12-18, vim-indent-guides doesn't work well for me, probably
" because of some interaction with another plugin or setting in my vimrc (it
" used to work a few months ago). The README also mentions that terminal vim
" only has basic support.
" Plug 'nathanaelkane/vim-indent-guides'
" let g:indent_guides_auto_colors = 0
" let g:indent_guides_start_level = 2
" let g:indent_guides_guide_size = 2
" let g:indent_guides_enable_on_vim_startup = 0
" let g:indent_guides_default_mapping = 0
" " Set saner colors for vim-indent-guides on solarized.
" " See http://vim.wikia.com/wiki/Xterm256_color_names_for_console_Vim for how to
" " see the terminal colors.
" hi IndentGuidesEven ctermbg=237
" hi IndentGuidesOdd ctermbg=239
" nmap <silent> <Leader>ti <Plug>IndentGuidesToggle

Plug 'Yggdroot/indentLine'
let g:indentLine_enabled = 0
nnoremap <silent> <Leader>ti :<C-U>IndentLinesToggle<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                   Zen mode                                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'junegunn/goyo.vim'

nnoremap <silent> <M-F> :<C-U>Goyo<CR>
nnoremap <silent> <Leader>F :<C-U>Goyo<CR>

function! s:goyo_enter() abort
  if has('gui_running')
    set background=light
    set linespace=7
  elseif vimrc#base#IsInsideTmux()
    silent !tmux set status off
  endif
endfunction

function! s:goyo_leave() abort
  if has('gui_running')
    set background=dark
    set linespace=0
  elseif vimrc#base#IsInsideTmux()
    silent !tmux set status on
  endif
  " This is needed so that my custom highlight groups (ActiveWindow and
  " InactiveWindow) are not cleared by the colorscheme.
  call VimrcSetColorScheme()
  " NOTE: As of 2019-09-25, This no longer seems to be needed. It used to be
  " required to fix colorscheme issues after leaving Goyo.
  " Required after having changed the colorscheme
  " hi clear SignColumn
endfunction

augroup vimrc
  autocmd User GoyoEnter nested call <SID>goyo_enter()
  autocmd User GoyoLeave nested call <SID>goyo_leave()
augroup END

Plug 'junegunn/limelight.vim'
" Toggle limelight
nnoremap <silent> <Leader>tl :<C-U>Limelight!!<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                 Status line                                  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Don't show mode (normal, insert, etc), since lightlight already shows it.
set noshowmode
set showcmd       " Show (partial) command in status line.
set laststatus=2  " Always show a status line.
set report=0      " Always report changed lines.

" TODO: Show both tabs and buffers on the tabline.
Plug 'itchyny/lightline.vim'
let g:lightline = {
    \ 'active': {
    \   'left': [ ['mode', 'spell', 'paste'],
    \             ['readonly', 'modified', 'git_branch', 'filename', 'method'] ],
    \   'right': [ ['column_info', 'percent', 'line_number'], 
    \              ['autoindent', 'filetype'],
    \              ['linter_checking', 'linter_errors',
    \               'linter_warnings', 'linter_ok'] ],
    \ },
    \ 'component': {
    \   'column_info': '𛱴%-2v',
    \   'line_number': ' %{printf("%2d/%2d", line("."),  line("$"))}',
    \ },
    \ 'component_function': {
    \   'readonly':   'LightlineReadonly',
    \   'git_branch': 'LightlineGitBranch',
    \   'filename':   'LightlineFilename',
    \   'method':     'LightlineNearestMethodOrFunction',
    \   'spell':      'LightlineSpell',
    \   'modified':   'LightlineModified',
    \   'autoindent': 'LightlineAutoindent',
    \ },
    \ 'component_expand': {
    \  'linter_checking': 'lightline#ale#checking',
    \  'linter_warnings': 'lightline#ale#warnings',
    \  'linter_errors': 'lightline#ale#errors',
    \  'linter_ok': 'lightline#ale#ok',
    \ },
    \ 'component_type': {
    \     'linter_checking': 'left',
    \     'linter_warnings': 'warning',
    \     'linter_errors': 'error',
    \     'linter_ok': 'left',
    \ },
    \ 'colorscheme': 'solarized',
    \ 'separator': { 'left': '', 'right': '' },
    \ 'subseparator': { 'left': '', 'right': '' },
\ }

function! g:LightlineReadonly() abort
  return &readonly ? '' : ''
endfunction

function! s:GetGitBranchName() abort
  if exists('*gina#component#repo#branch')
    return gina#component#repo#branch()
  endif
  if exists('*fugitive#head')
    return fugitive#head()
  endif
  return ''
endfunction

function! g:LightlineGitBranch() abort
  let l:branch = s:GetGitBranchName()
  return l:branch !=# '' ? ' '.l:branch : ''
endfunction

function! g:LightlineModified() abort
  if &filetype is# 'fzf'
    return ''
  endif
  return &modified ? '✎' : ''
endfunction

function! g:LightlineFilename() abort
  if &filetype is# 'fzf'
    return ''
  endif
  if expand('%:p') is# ''
    return '[No Name]'
  endif
  let l:display_path = expand('%:~')
  if winwidth(0) - len(l:display_path) < 50
    return expand('%:t')
  endif
  return l:display_path
endfunction

function! g:LightlineNearestMethodOrFunction() abort
  if !get(s:, 'vista_loaded_for_lightline', 0)
    if !exists(':Vista')
      let s:vista_loaded_for_lightline = 1
      return
    endif
    " Run a command so that vim-plug lazy loads the plugin.
    Vista!
    call vista#RunForNearestMethodOrFunction()
    let s:vista_loaded_for_lightline = 1
  endif
  return get(b:, 'vista_nearest_method_or_function', '')
endfunction

function! g:LightlineSpell() abort
  return &spell? printf('SPELL [%s]', &spelllang): ''
endfunction

function! g:LightlineAutoindent() abort
  return exists('*SleuthIndicator') ? SleuthIndicator() : ''
endfunction

Plug 'maximbaz/lightline-ale'
let g:lightline#ale#indicator_checking = "\uf110"
let g:lightline#ale#indicator_warnings = "\uf071 "
let g:lightline#ale#indicator_errors = "\uf05e "
let g:lightline#ale#indicator_ok = "\uf00c"

Plug 'mengelbrecht/lightline-bufferline'
set showtabline=2
let g:lightline.tabline = {'left': [['buffers']], 'right': []}
call extend (g:lightline.component_expand,
    \ {'buffers': 'lightline#bufferline#buffers'})
call extend (g:lightline.component_type, {'buffers': 'tabsel'})

let g:lightline#bufferline#modified = ' ✎'
let g:lightline#bufferline#read_only = ' '
let g:lightline#bufferline#unnamed = '[No Name]'
let g:lightline#bufferline#show_number = 2

nmap <Leader>1 <Plug>lightline#bufferline#go(1)
nmap <Leader>2 <Plug>lightline#bufferline#go(2)
nmap <Leader>3 <Plug>lightline#bufferline#go(3)
nmap <Leader>4 <Plug>lightline#bufferline#go(4)
nmap <Leader>5 <Plug>lightline#bufferline#go(5)
nmap <Leader>6 <Plug>lightline#bufferline#go(6)
nmap <Leader>7 <Plug>lightline#bufferline#go(7)
nmap <Leader>8 <Plug>lightline#bufferline#go(8)
nmap <Leader>9 <Plug>lightline#bufferline#go(9)
nmap <Leader>0 <Plug>lightline#bufferline#go(10)

" Plug 'bling/vim-airline'
" " Show list of buffers at the top
" let g:airline#extensions#tabline#enabled = 1
" " Show buffer numbers
" let g:airline#extensions#tabline#buffer_idx_mode = 1
" nmap <Leader>1 <Plug>AirlineSelectTab1
" nmap <Leader>2 <Plug>AirlineSelectTab2
" nmap <Leader>3 <Plug>AirlineSelectTab3
" nmap <Leader>4 <Plug>AirlineSelectTab4
" nmap <Leader>5 <Plug>AirlineSelectTab5
" nmap <Leader>6 <Plug>AirlineSelectTab6
" nmap <Leader>7 <Plug>AirlineSelectTab7
" nmap <Leader>8 <Plug>AirlineSelectTab8
" nmap <Leader>9 <Plug>AirlineSelectTab9
" " In vim-airline, only display "hunks" if the diff is non-zero
" let g:airline#extensions#hunks#non_zero_only = 1
" " Enable tmuxline integration. Currently tmuxline is not used so it will have no
" " effect.
" let g:airline#extensions#tmuxline#enabled = 1
" let g:airline_powerline_fonts = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                Screen refresh                                "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:RefreshScreenCommand() abort
  let l:cmds = ['nohlsearch', 'checktime']
  if exists('*clever_f#reset')
    call extend(l:cmds, ['call clever_f#reset()'])
  endif
  if exists('*brightest#hl_clear')
    call extend(l:cmds, ['call brightest#hl_clear()'])
  endif
  if &diff
    call extend(l:cmds, ['diffupdate'])
  endif
  if &filetype is# 'go' && exists(':GoCoverageClear')
    call extend(l:cmds, ['GoCoverageClear'])
  endif
  if exists(':ALELint') && get(g:, 'ale_enabled', 1) && get(b:, 'ale_enabled', 1)
    call extend(l:cmds, ['ALELint'])
  endif
  " This must be the last command, otherwise the cursor jumps to the first char
  " on the line.
  " call extend(l:cmds, ["\<C-L>"])
  call extend(l:cmds, ['mode'])
  " call extend(l:cmds, ['silent call feedkeys("\<C-L>", "n")'])
  return vimrc#GetCommandForMode(join(l:cmds, ' | '))
endfunction

" Clear screen and current search highlight with Ctrl+L.
" Don't get used to it too much though, L is an important navigation key.
" See also:
" https://github.com/mhinz/vim-galore#go-to-other-end-of-selected-text
nnoremap <silent> <expr> <C-L> <SID>RefreshScreenCommand()
xnoremap <silent> <expr> <C-L> <SID>RefreshScreenCommand()
inoremap <silent> <expr> <C-L> <SID>RefreshScreenCommand()
snoremap <silent> <expr> <C-L> <SID>RefreshScreenCommand()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                 Colorscheme                                  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'lifepillar/vim-solarized8'
" Plug 'flazz/vim-colorschemes'

function! VimrcSetColorScheme() abort
  set background=dark
  colorscheme solarized8
  " These highlight groups must be set after the colorscheme, since the
  " colorscheme resets all preexisting groups.
  highlight ActiveWindow guibg=#002b36
  highlight InactiveWindow guibg=#00242e
  highlight! link ALEVirtualText Comment
  highlight! link ALEVirtualTextWarning ALEVirtualText
  highlight! link ALEVirtualTextError ALEVirtualText
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                         Platform dependent settings                          "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:HasTruecolor() abort
  return $COLORTERM =~# '\v\C^(truecolor|24bit)' && exists('+termguicolors')
endfunction

if has('gui_running')
  set guioptions-=m  " Hide menu bar.
  set guioptions-=T  " Hide toolbar
  set guioptions-=L  " Hide left-hand scrollbar
  set guioptions-=r  " Hide right-hand scrollbar
  set guioptions-=b  " Hide bottom scrollbar
  set showtabline=0  " Hide tabline
  set guioptions-=e  " Hide tab
elseif s:HasTruecolor()
  set termguicolors
  " This is required for making colors work in vim inside tmux. See also:
  " - https://github.com/vim/vim/issues/993#issuecomment-255651605
  " - https://github.com/tmux/tmux/issues/1246
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif

if has('gui_running') || s:HasTruecolor()
  Plug 'TaDaa/vimade'
  let g:vimade = {
      \ 'fadelevel': 0.75,
      \ }
  " Dim inactive windows and change the background of the preview window. See:
  " https://medium.com/@caleb89taylor/customizing-individual-neovim-windows-4a08f2d02b4e
  " NOTE: As of 2020-04-25, I switched to using the vimade plugin in gui mode
  " and when truecolor is supported.
  " augroup vimrc
  "   autocmd VimEnter,WinNew,WinEnter,BufWinEnter * call <SID>SetWinhighlight()
  " augroup END
  "
  " function! s:SetWinhighlight() abort
  "   if exists('+winhighlight')
  "     setlocal winhighlight=Normal:ActiveWindow,NormalNC:InactiveWindow
  "   endif
  " endfunction
endif

function! s:ConfigNeovimQt() abort
  if exists(':GuiTabline')
    GuiTabline 0
  endif
endfunction

if has('nvim')
  " https://github.com/equalsraf/neovim-qt
  augroup vimrc
    autocmd UIEnter * call <SID>ConfigNeovimQt()
  augroup END
endif

" https://github.com/neovim/neovim/pull/12279
if has('##TextYankPost')
  augroup vimrc
    autocmd BufEnter * call s:MaybeDiffBindings()
    autocmd TextYankPost * silent! lua
        \ require'highlight'.on_yank('IncSearch', 500, vim.v.event)
  augroup END
else
  " Highlight yanked region for a small duration after yanking.
  Plug 'machakann/vim-highlightedyank'
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                     Misc                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'tweekmonster/startuptime.vim', { 'on': ['StartupTime'] }
Plug 'tweekmonster/helpful.vim', { 'on': ['HelpfulVersion'] }

" See diff of recovered file.
Plug 'chrisbra/Recover.vim'

" gundo is slow for me, so I'm experimenting with undotree to see if it's any
" better.
" Plug 'sjl/gundo.vim'
Plug 'mbbill/undotree', { 'on': ['UndotreeToggle'] }
" Toggle undo tree
nnoremap U :<C-U>UndotreeToggle<CR>

" NOTE: As of 2020-05-16, fuzzy tag finding is done with vista.
nnoremap <silent> <Leader>o :<C-U>BTags<CR>
nnoremap <silent> <Leader>O :<C-U>Tags<CR>

" Plug 'liuchengxu/vista.vim'
" nnoremap <silent> <Leader>O :<C-U>Vista finder!<CR>
" xnoremap <Leader>O ""y:Vista finder! <Bar>
"     \ call feedkeys('<C-R>=substitute(@", "'", "''", 'g')<CR>', 'n')<CR>
" nnoremap <Leader>wt :<C-U>Vista!!<CR>

function! s:ToggleConceal() abort
  let l:bufnr = bufnr()
  let s:bufnr_to_conceal = get(s:, 'bufnr_to_conceal', {})
  let l:conceallevel = &conceallevel
  if has_key(s:bufnr_to_conceal, l:bufnr)
    let &l:conceallevel = s:bufnr_to_conceal[l:bufnr]
  elseif &conceallevel > 0
    let &l:conceallevel = 0
  else
    let &l:conceallevel = 2
  endif
  let s:bufnr_to_conceal[l:bufnr] = l:conceallevel
endfunction

nnoremap <silent> <Leader>tc :<C-U>call <SID>ToggleConceal()<CR>
