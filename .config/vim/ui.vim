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
    for i in range(1, a:count)
      call VSCodeNotify(a:cmd)
    endfor
  endfunction

  " See https://github.com/asvetliakov/vscode-neovim/blob/master/vim/vscode-window-commands.vim
  let s:win_left = 'call VSCodeNotify("workbench.action.navigateLeft")'
  let s:win_down = 'call VSCodeNotify("workbench.action.navigateDown")'
  let s:win_up = 'call VSCodeNotify("workbench.action.navigateUp")'
  let s:win_right = 'call VSCodeNotify("workbench.action.navigateRight")'
  let s:win_move_left = 'call VSCodeNotify("workbench.action.moveEditorToLeftGroup")'
  let s:win_move_down = 'call VSCodeNotify("workbench.action.moveEditorToBelowGroup")'
  let s:win_move_up = 'call VSCodeNotify("workbench.action.moveEditorToAboveGroup")'
  let s:win_move_right = 'call VSCodeNotify("workbench.action.moveEditorToRightGroup")'
  let s:win_max = 'call VSCodeNotify("workbench.action.toggleEditorWidths")'
  " NOTE: vscode-neovim overrides the built-in split/vsplit commands with its
  " Split/Vsplit variants, so I could in theory just use split/vsplit for both
  " VSCode mode and non-VSCode mode, but it didn't work in VSCode when I tried
  " it, possibly due to the fact that overriding the built-in commands doesn't
  " work when used in <Cmd> mappings.
  let s:win_split_down = 'Split'
  let s:win_split_right = 'Vsplit'
  let s:win_prev = 'call VSCodeNotify("workbench.action.focusPreviousGroup")'
  let s:win_resize_eq = 'call VSCodeNotify("workbench.action.evenEditorWidths")'
  let s:win_inc_height = 'call <SID>RepeatVSCodeNotify(v:count1, "workbench.action.increaseViewHeight")'
  let s:win_dec_height = 'call <SID>RepeatVSCodeNotify(v:count1, "workbench.action.decreaseViewHeight")'
  let s:win_inc_width = 'call <SID>RepeatVSCodeNotify(v:count1, "workbench.action.increaseViewWidth")'
  let s:win_dec_width = 'call <SID>RepeatVSCodeNotify(v:count1, "workbench.action.decreaseViewWidth")'
  " `Wq` and `Wqall` are defined in vscode-neovim
  let s:win_quit = 'Wq'
  let s:win_quit_all = 'Wqall'
  let s:buf_close = 'call VSCodeNotify("workbench.action.closeActiveEditor")'
  let s:buf_next = 'call VSCodeNotify("workbench.action.nextEditor")'
  let s:buf_prev = 'call VSCodeNotify("workbench.action.previousEditor")'
else
  " TODO: Verify if undo works correctly, i.e. the full sequence of commands is
  " undone as a single unit. It doesn't matter right now because I don't use it
  " for text editing actions.
  function! s:RepeatCommand(count, cmd) abort
    for i in range(1, a:count)
      exec a:cmd
    endfor
  endfunction

  let s:win_left = 'normal! <C-W>h'
  let s:win_down = 'normal! <C-W>j'
  let s:win_up = 'normal! <C-W>k'
  let s:win_right = 'normal! <C-W>l'
  let s:win_move_left = 'normal! <C-W>H'
  let s:win_move_down = 'normal! <C-W>J'
  let s:win_move_up = 'normal! <C-W>K'
  let s:win_move_right = 'normal! <C-W>L'
  let s:win_max = 'normal! <C-W>_<C-W><Bar>'
  let s:win_split_down = 'normal! <C-W>s'
  let s:win_split_right = 'normal! <C-W>v'
  let s:win_prev = 'normal! <C-W>p'
  let s:win_resize_eq = 'normal! <C-W>='
  let s:win_inc_height = 'call <SID>RepeatCommand(v:count1, "normal! \<C-W>+")'
  let s:win_dec_height = 'call <SID>RepeatCommand(v:count1, "normal! \<C-W>-")'
  let s:win_inc_width = 'call <SID>RepeatCommand(v:count1, "normal! \<C-W>>")'
  let s:win_dec_width = 'call <SID>RepeatCommand(v:count1, "normal! \<C-W><")'
  " NOTE: I previously used `:q!` instead of `:q`, but this silently quits
  " read-only modified buffers (losing their changes). `:q` alone works well
  " with my autosync settings.
  let s:win_quit = 'q'
  let s:win_quit_all = 'wqall'
  Plug 'mhinz/vim-sayonara', { 'on': 'Sayonara' }
  let s:buf_close = 'Sayonara!'
  let s:buf_next = 'bn'
  let s:buf_prev = 'bp'
endif

for s:map_mode in ['nnoremap', 'xnoremap']
  " Navigating windows.
  exec printf('%s <Leader>wj <Cmd>%s<CR>', s:map_mode, s:win_left)
  exec printf('%s <Leader>wk <Cmd>%s<CR>', s:map_mode, s:win_down)
  exec printf('%s <Leader>wi <Cmd>%s<CR>', s:map_mode, s:win_up)
  exec printf('%s <Leader>wl <Cmd>%s<CR>', s:map_mode, s:win_right)
  " Moving windows.
  exec printf('%s <Leader>wJ <Cmd>%s<CR>', s:map_mode, s:win_move_left)
  exec printf('%s <Leader>wK <Cmd>%s<CR>', s:map_mode, s:win_move_down)
  exec printf('%s <Leader>wI <Cmd>%s<CR>', s:map_mode, s:win_move_up)
  exec printf('%s <Leader>wL <Cmd>%s<CR>', s:map_mode, s:win_move_right)
  " Resizing/focusing on windows.
  exec printf('%s <Leader>wf <Cmd>%s<CR>', s:map_mode, s:win_max)
  " Now that h is free use h and v for horizontal and vertical splitting. The
  " splitting is done in a way that is consistent with i3 and tmux.
  exec printf('%s <Leader>wv <Cmd>%s<CR>', s:map_mode, s:win_split_down)
  exec printf('%s <Leader>wh <Cmd>%s<CR>', s:map_mode, s:win_split_right)
  " Go to previous window
  exec printf('%s <Leader>w<Leader>w <Cmd>%s<CR>', s:map_mode, s:win_prev)
  " Window resizing
  exec printf('%s <Leader>w= <Cmd>%s<CR>', s:map_mode, s:win_resize_eq)
  exec printf('%s <Leader>w+ <Cmd>%s<CR>', s:map_mode, s:win_inc_height)
  exec printf('%s <Leader>w- <Cmd>%s<CR>', s:map_mode, s:win_dec_height)
  exec printf('%s <Leader>w> <Cmd>%s<CR>', s:map_mode, s:win_inc_width)
  exec printf('%s <Leader>w< <Cmd>%s<CR>', s:map_mode, s:win_dec_width)
  exec printf('%s <Leader>w_ <Cmd>%s<CR>', s:map_mode, s:win_resize_eq)
endfor

exec printf('nnoremap <Leader>wq <Cmd>%s<CR>', s:win_quit)
exec printf('nnoremap <Leader>q <Cmd>%s<CR>', s:win_quit)
exec printf('nnoremap <Leader>wQ <Cmd>%s<CR>', s:win_quit_all)
exec printf('nnoremap <Leader>Q <Cmd>%s<CR>', s:win_quit_all)

" Buffer stuff with b.
nnoremap b <Nop>
xnoremap b <Nop>
nnoremap B <Nop>
xnoremap B <Nop>
exec printf('nnoremap bd <Cmd>%s<CR>', s:buf_close)
exec printf('nnoremap bp <Cmd>%s<CR>', s:buf_prev)
exec printf('nnoremap bn <Cmd>%s<CR>', s:buf_next)
exec printf('nnoremap [b <Cmd>%s<CR>', s:buf_prev)
exec printf('nnoremap ]b <Cmd>%s<CR>', s:buf_next)
nnoremap <Leader>e <Cmd>call vimrc#actions#LastBuffer()<CR>

" Example usage: `:EditExOutput autocmd`
command! -nargs=+ -complete=command EditExOutput
    \ call vimrc#EditExOutput(<q-args>, <q-mods>)

" TODO: Improve vimrc handling for vscode mode: define actions that are only
" mapped in the main vimrc, and will be overridden in vscode mode.
if g:VSCODE_MODE
  nnoremap <C-L> <Cmd>nohlsearch<CR>
  xnoremap <C-L> <Cmd>nohlsearch<CR>
  inoremap <C-L> <Cmd>nohlsearch<CR>
  snoremap <C-L> <Cmd>nohlsearch<CR>

  nnoremap <silent> <Leader>d <Cmd>call VSCodeNotify('workbench.action.showCommands')<CR>
  " nnoremap <silent> <Leader>D <Cmd>History:<CR>
  " nnoremap <silent> <Leader>sh <Cmd>History/<CR>
  nnoremap <silent> <Leader>E <Cmd>call VSCodeNotify('workbench.action.quickOpen')<CR>
  " nnoremap <silent> <Leader>sl <Cmd>BLines<CR>
  " nnoremap <silent> <Leader>sL <Cmd>Lines<CR>
  " nnoremap <silent> <Leader>C <Cmd>Colors<CR>
  nnoremap <silent> <Leader>o <Cmd>call VSCodeNotify('workbench.action.gotoSymbol')<CR>
  nnoremap <silent> <Leader>O <Cmd>call VSCodeNotify('workbench.action.showAllSymbols')<CR>
  nnoremap <silent> <Leader>ff <Cmd>call VSCodeNotify('fzf-quick-open.runFzfFile')<CR>
  nnoremap <silent> bl <Cmd>call VSCodeNotify('workbench.action.showAllEditorsByMostRecentlyUsed')<CR>

  " Mnemonic: Code Execute
  nnoremap <silent> <Leader>cee <Cmd>call VSCodeNotify('jupyter.runcurrentcell')<CR>
  nnoremap <silent> <Leader>cen <Cmd>call VSCodeNotify('jupyter.runcurrentcelladvance')<CR>
  nnoremap <silent> <Leader>cei <Cmd>call VSCodeNotify('jupyter.runallcellsabove.palette')<CR>
  nnoremap <silent> <Leader>cek <Cmd>call VSCodeNotify('jupyter.runcurrentcellandallbelow.palette')<CR>
  nnoremap <silent> <Leader>cea <Cmd>call VSCodeNotify('jupyter.runallcells')<CR>

  finish
endif  " g:VSCODE_MODE

" Resize window, no equivalent in VSCode.
nnoremap <Leader>w_ <C-W>_
xnoremap <Leader>w_ <C-W>_

Plug 'simeji/winresizer', { 'on':  [ 'WinResizerStartResize',
    \ 'WinResizerStartMove', 'WinResizerStartFocus'] }
" Since the plugin is lazy loaded, we map C-r directly.
nnoremap <Leader>wr <Cmd>WinResizerStartResize<CR>
let g:winresizer_start_key = '<C-R>'
let g:winresizer_keycode_left = 106
let g:winresizer_keycode_down = 107
let g:winresizer_keycode_right = 108
let g:winresizer_keycode_up = 105

Plug 'infokiller/fzf', {'dir': g:submodules_dir . '/terminal/fzf'}
" fzf.vim needs to be renamed because of a maktaba bug which outputs errors when
" plugins have a dot in their name.
Plug 'infokiller/fzf.vim', {'dir': g:plugins_dir . '/fzf-vim'}

nnoremap <silent> bl <Cmd>Buffers<CR>

function! s:FzfFilesNoIgnore(args, bang) abort
  try
    let l:prev_default_command = $FZF_DEFAULT_COMMAND
    let l:find_cmd_template = '%s -L . -mindepth 1 \( -fstype sysfs -o -fstype devfs -o -fstype devtmpfs -o -fstype proc \) -prune -o -print 2> /dev/null | cut -b3-'
    if executable('bfs')
      let $FZF_DEFAULT_COMMAND = printf(l:find_cmd_template, 'bfs')
    elseif executable('rg')
      let $FZF_DEFAULT_COMMAND = 'rg --no-ignore --files'
    else
      let $FZF_DEFAULT_COMMAND = printf(l:find_cmd_template, 'find')
    endif
    call fzf#vim#files(a:args, fzf#vim#with_preview(), a:bang)
  finally
    let $FZF_DEFAULT_COMMAND = l:prev_default_command
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
nnoremap <Leader>fs <Cmd>w<CR>
nnoremap <silent> <Leader>ff <Cmd>Files<CR>
nnoremap <silent> <Leader>fd <Cmd>Files <C-R>=expand('%:h')<CR><CR>
nnoremap <silent> <Leader>fF <Cmd>FilesNoIgnore<CR>

Plug 'mtth/scratch.vim', { 'on': ['Scratch', 'ScratchSelection'] }
let g:scratch_top = 1
let g:scratch_no_mappings = 1
nnoremap <M-s> <Cmd>Scratch<CR>
xnoremap <M-s> <Cmd>ScratchSelection<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                     Tmux                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'christoomey/vim-tmux-navigator'
" Plug 'benmills/vimux'

" Navigating windows without using the Ctrl+W prefix, integrated with tmux.

" Don't navigate out of vim when tmux is zoomed.
let g:tmux_navigator_disable_when_zoomed = 1
let g:tmux_navigator_no_mappings = 1

" NOTE: <M-;> doesn't work, not sure why. Also, adding this keybinding makes vim
" identify key sequences like Esc-k as <Alt-k>, which causes it to shift focus
" to another pane.
" nnoremap <silent> <M-;> <Cmd>TmuxNavigateLast<CR>
" NOTE: command mode is handled separately, because using <Cmd> in this case
" will navigate tmux/vim but keep us in command mode, which will look like the
" focus didn't change.
for s:mode in ['n', 'x', 'i', 't']
  exec printf('%snoremap <silent> <M-j> <Cmd>TmuxNavigateLeft<CR>', s:mode)
  exec printf('%snoremap <silent> <M-k> <Cmd>TmuxNavigateDown<CR>', s:mode)
  exec printf('%snoremap <silent> <M-i> <Cmd>TmuxNavigateUp<CR>', s:mode)
  exec printf('%snoremap <silent> <M-l> <Cmd>TmuxNavigateRight<CR>', s:mode)
  exec printf('%snoremap <silent> <M-w> <Cmd>TmuxNavigatePrevious<CR>', s:mode)
endfor
" The commands below exit the command line before navigating. The typed command
" line should still be in the history, so no data should be lost.
cnoremap <silent> <M-j> <C-C>:TmuxNavigateLeft<CR>
cnoremap <silent> <M-k> <C-C>:TmuxNavigateDown<CR>
cnoremap <silent> <M-l> <C-C>:TmuxNavigateUp<CR>
cnoremap <silent> <M-i> <C-C>:TmuxNavigateRight<CR>
cnoremap <silent> <M-w> <C-C>:TmuxNavigatePrevious<CR>

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
nnoremap <Leader>yn <Cmd>let @+ = expand('%:t')<CR>
" Copy current file full path to clipboard
nnoremap <Leader>yp <Cmd>let @+ = expand('%:p')<CR>
" Copy current dir to clipboard
nnoremap <Leader>yd <Cmd>let @+ = expand('%:p:h')<CR>

nnoremap <Leader>cdh <Cmd>cd<CR>
nnoremap <Leader>cdf <Cmd>cd %:p:h<CR>
nnoremap <Leader>cdd <Cmd>RangerCD<CR>
nnoremap <Leader>cdl <Cmd>RangerLCD<CR>
" nnoremap <Leader>cde <Cmd>RangerEdit<CR>
nnoremap <Leader>fe <Cmd>RangerEdit<CR>
nnoremap <expr> <Leader>cdr '<Cmd>cd ' . FindRootDirectory() . '<CR>'

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
" nnoremap <Leader>fe <Cmd>NERDTreeToggle<CR>

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

function! s:MaybeSetDiffOptions() abort
  if &diff
    " Syntax highlighting in diff mode is confusing me because the color overlap
    " with the colors used for changed lines/part of lines.
    setlocal syntax=off
    " Navigate diff changes with Ctrl+{p,n}
    nnoremap <buffer> <C-P> [c
    nnoremap <buffer> <C-N> ]c
    nnoremap <buffer> du <Cmd>diffupdate<CR>
    nnoremap <buffer> dp <Cmd>diffput<CR>
    nnoremap <buffer> dg <Cmd>diffget<CR>
  else
    if !empty(&filetype)
      setlocal syntax=on
    endif
    silent! nunmap <buffer> <C-P>
    silent! nunmap <buffer> <C-N>
    silent! nunmap <buffer> du
    silent! nunmap <buffer> dp
    silent! nunmap <buffer> dg
  endif
endfunction

augroup vimrc
  autocmd WinNew,WinEnter,BufNew,BufEnter * call s:MaybeSetDiffOptions()
  autocmd OptionSet diff call s:MaybeSetDiffOptions()
augroup END

" DiffUpdated is needed for diffs triggered by fugitive to work.
" DiffUpdated is not supported in older versions of vim.
if exists('##DiffUpdated')
  augroup vimrc
    autocmd DiffUpdated * call s:MaybeSetDiffOptions()
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
set switchbuf=uselast

" Make tabs and trailing spaces visible when requested.
" set listchars=tab:>-,trail:·,eol:$,nbsp:☣
set listchars=tab:»\ ,trail:·,eol:↲,precedes:‹,extends:›,nbsp:☣
" tab:\!\ ,,extends:❯,precedes:❮
nnoremap <silent> <Leader>tw <Cmd>set list!<CR>

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
" nnoremap <silent> <Leader>th <Cmd>BrightestToggle<CR>
let g:cursorword = 0
nnoremap <silent> <Leader>th <Cmd>call vimrc#ToggleOption('g:cursorword') <Bar>
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
" nnoremap <silent> <Space> <Cmd>WhichKey '<Space>'<CR>
" xnoremap <silent> <Space> <Cmd>WhichKeyVisual '<Space>'<CR>

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

" nnoremap <silent> <Leader>d <Cmd>call
"     \ fzf#vim#commands({'down': '~40%', 'options': '--no-extended +x'})<CR>
nnoremap <silent> <Leader>d <Cmd>Commands<CR>
nnoremap <silent> <Leader>D <Cmd>History:<CR>
nnoremap <silent> <Leader>sh <Cmd>History/<CR>
nnoremap <silent> <Leader>E <Cmd>History<CR>
nnoremap <silent> <Leader>C <Cmd>Colors<CR>
nnoremap <silent> <Leader>h <Cmd>Helptags<CR>
nnoremap <silent> <Leader>sl <Cmd>BLines<CR>
nnoremap <silent> <Leader>sL <Cmd>Lines<CR>

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
nnoremap <silent> <Leader>ti <Cmd>IndentLinesToggle<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                   Zen mode                                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'junegunn/goyo.vim'

nnoremap <silent> <M-F> <Cmd>Goyo<CR>
nnoremap <silent> <Leader>F <Cmd>Goyo<CR>

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
nnoremap <silent> <Leader>tl <Cmd>Limelight!!<CR>

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
    \              ['autoindent', 'venv', 'filetype'],
    \              ['linter_checking', 'linter_errors',
    \               'linter_warnings', 'linter_ok'] ],
    \ },
    \ 'component': {
    \   'column_info': '𛱴%-2c',
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
    \   'venv':       'LightlineVirtualEnv',
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
  if exists('*FugitiveHead')
    return FugitiveHead()
  endif
  " fugitive#head was removed in commit b81c59b
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

function! g:LightlineVirtualEnv() abort
  if &filetype is# 'python'
    if !empty($CONDA_DEFAULT_ENV)
      return $CONDA_DEFAULT_ENV
    endif
  endif
  return ''
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
function! s:RefreshScreen() abort
  " nohlsearch doesn't work in user functions, so we must do it directly in the
  " mapping.
  nohlsearch
  checktime
  if exists('*clever_f#reset')
    call clever_f#reset()
  endif
  if exists('*brightest#hl_clear')
    call brightest#hl_clear()
  endif
  if &diff
    diffupdate
  endif
  if &filetype is# 'go' && exists(':GoCoverageClear')
    GoCoverageClear
  endif
  if exists(':ALELint') && get(g:, 'ale_enabled', 1) && get(b:, 'ale_enabled', 1)
    ALELint
  endif
  if &filetype is# 'python' && exists('*coverage_highlight#get_current') &&
        \ !empty(coverage_highlight#get_current())
    HighlightCoverage
  endif
  " This must be the last command, otherwise the cursor jumps to the first char
  " on the line.
  mode
endfunction

" Clear screen and current search highlight with Ctrl+L.
" Don't get used to it too much though, L is an important navigation key.
for s:mode in ['n', 'x', 'i', 's']
  " NOTE: nohlsearch doesn't work in user functions, so we must do it directly
  " in the mapping.
  exec printf('%snoremap <silent> <C-L> <Cmd>nohl <Bar> call <SID>RefreshScreen()<CR>', s:mode)
endfor

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                 Colorscheme                                  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" nvim-solarized-lua has issues with nvim 0.7
" https://github.com/ishan9299/nvim-solarized-lua/commit/f8e4e60a2873b6f1a28c837ab217deb1bfdc723e
if has('nvim-0.8')
  Plug 'ishan9299/nvim-solarized-lua'
  let s:solarized_variant = 'solarized'
else
  Plug 'lifepillar/vim-solarized8'
  let s:solarized_variant = 'solarized8'
  " Plug 'flazz/vim-colorschemes'
endif


function! VimrcSetColorScheme() abort
  set background=dark
  exec 'colorscheme ' . s:solarized_variant
  " These highlight groups must be set after the colorscheme, since the
  " colorscheme resets all preexisting groups.
  highlight ActiveWindow guibg=#657b83
  highlight InactiveWindow guibg=#00242e
  " I changed DiffText to show the part of line changed as having yellow
  " background. The rest are the defaults of DiffChange from solarized8.
  highlight! DiffText cterm=inverse,bold gui=inverse,bold ctermbg=5 guifg=#b58900 guibg=#002b36 guisp=#b58900
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
    autocmd BufEnter * call s:MaybeSetDiffOptions()
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
nnoremap U <Cmd>UndotreeToggle<CR>

" NOTE: As of 2020-05-16, fuzzy tag finding is done with vista.
nnoremap <silent> <Leader>o <Cmd>BTags<CR>
nnoremap <silent> <Leader>O <Cmd>Tags<CR>

" Plug 'liuchengxu/vista.vim'
" nnoremap <silent> <Leader>O <Cmd>Vista finder!<CR>
" xnoremap <Leader>O ""y:Vista finder! <Bar>
"     \ call feedkeys('<C-R>=substitute(@", "'", "''", 'g')<CR>', 'n')<CR>
nnoremap <Leader>wt <Cmd>Vista!!<CR>

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

nnoremap <silent> <Leader>tc <Cmd>call <SID>ToggleConceal()<CR>
