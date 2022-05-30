" This file contains settings that are shared between all modes of vim: regular
" vim, VSCode, Athame, Firenvim, and any other contexts where vim is used as the
" editing backend for a single text buffer.
" vint complains about needing to set scriptencoding because of multibyte chars,
" but still gives a warning with these lines.
" vint: -ProhibitEncodingOptionAfterScriptEncoding
set encoding=utf-8
scriptencoding utf-8
" vint: +ProhibitEncodingOptionAfterScriptEncoding

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                         Consistent vim/nvim defaults                         "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set consistent defaults between vim and neovim. Some options that appear in 
" `:help vim_diff.txt` are not set the same, see below.
" See also: 
" ~/.config/vim/diff-vim-nvim-defaults
" /usr/share/vim/vim82/defaults.vim
set sessionoptions=blank,buffers,curdir,folds,help,options,tabpages,winsize,terminal,unix,slash
set viewoptions=folds,cursor,curdir,slash,unix
if !has('nvim-0.6')
  set autoindent
  set autoread
  set background=dark
  set backspace=indent,eol,start
  " vint: -ProhibitSetNoCompatible
  set nocompatible
  set complete-=i
  set cscopeverbose
  set display=lastline
  if has('nvim-0.4.4')
    set display+=msgsep
  endif
  " encoding is set above and in vimrc
  " set encoding=utf-8
  set fillchars=vert:\|,fold:·
  set formatoptions=tcqj
  " NOTE: fsync is disabled by default in nvim for performance reasons, but nvim
  " also flushes the files to disk on CursorHold and other events, hence it's
  " relatively safe. For vim we keep the default of fsync being enabled.
  set hidden
  set nojoinspaces
  if has('langmap') && exists('+langremap')
    " No need to set the deprecated langnoremap because it is set automatically to
    " the inverse of langremap.
    " set langnoremap
    set nolangremap
  endif
  set nrformats-=octal
  set ruler
  " sessionoptions is set above
  set shortmess+=F | set shortmess-=S
  set showcmd
  set sidescroll=1
  set smarttab
  set nostartofline
  set switchbuf=uselast
  set tabpagemax=50
  set ttimeoutlen=50
  set ttyfast  " Indicates a fast terminal connection.
  " viewoptions is set above
  set wildmenu
  set wildoptions=tagfile
  " https://github.com/neovim/neovim/pull/9607
  if has('nvim-0.4.4')
    set wildoptions+=pum
  endif
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                               General settings                               "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
syntax on

augroup vimrc
  autocmd BufReadPost * call vimrc#base#SetPreviousPosition()
augroup END

set hidden  " Keep hidden buffers loaded.

" Use a 1000ms timeout when waiting for a key sequence to complete.
set timeout
set timeoutlen=1000
" Use a 10ms timeout when waiting for a key code sequence to complete. A key
" code sequence usually starts with an <Esc> followed by more keys, and is often
" what's sent to vim when an Alt combo is pressed.
set ttimeout
set ttimeoutlen=10
" If this many milliseconds nothing is typed the swap file will be written to
" disk and the CursorHold event is fired.
" Used by autosaving and auto refreshing git-gutter.
set updatetime=100

" Move to previous line when pressing left on the first column of a line (and
" the same for the last and right).
set whichwrap+=<,>,h,l,[,]
" Allow backspacing over autoindent, line breaks (join lines) and the start of
" insert.
set backspace=indent,eol,start
" Allow selecting beyond end of lines in visual block mode.
set virtualedit=block

set foldenable         " Enable folding
set foldlevelstart=10  " Open most folds by default
set foldnestmax=10     " 10 nested fold max
set foldmethod=marker  " Fold based on markers

" History size for commands and search patterns.
set history=10000
" Remember more in viminfo (last buffers, registers, search history, etc)
set viminfo='1000,<500,s1000,h
if has('shada')
  let &shada = &viminfo
else
  " Neovim has a different viminfo format, so vim and neovim can't share this
  " file. See also: https://github.com/neovim/neovim/issues/3469
  let &viminfo = Concat(&viminfo, ',n', g:VIM_DATA_DIR, '/viminfo')
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                               General mappings                               "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Use space as the leader key which seems the most ergonomic and comfortable
" choice.
let mapleader = ' '

" The biggest deviations I'm making from stock vim are:
"
" 1. Using 'jkil' instead of 'hjkl' for moving the cursor in normal mode.
"
"    Stock vim: h: left, j: down, k: up, l: right
"    My config: j: left, k: down, i: up, l: right
"
"    This means that I need another keybinding to replace 'i', but I also have a
"    new free key: 'h'.
"    If I want to use these keybindings in visual mode too, it becomes more
"    complicated because 'i' is used a lot for text objects (for example 'iw' to
"    select the inner word).
"
" 2. Mapping 'w' to 'b', i.e. 'w' is used to move backwards word-wise. This
"    frees another key: 'b'. Since 'h' is above 'b' in QWERTY, I can take
"    advantage of this to define keybindings for some up/down movement. However,
"    I haven't done it yet.
"
" 3. Mapping 'IJKL' in normal and visual modes.

" Use shift+i to get into insert mode instead of i. This is necessary because
" i will be occupied for movement.

" Consistent movement in normal and visual modes.
let g:vimrc_consistent_movement = get(g:, 'vimrc_consistent_movement', 1)

nnoremap <Leader>i i
if g:vimrc_consistent_movement
  xnoremap <Leader>i i
endif
nnoremap <Leader>I I
xnoremap <Leader>I I

" Use ijkl for movement, which is more natural for me and is consistent with the
" inverted T shape of the arrow keys. Also, use the g+{movement} variants for
" movements which makes the movement keys work on screen lines" instead of on
" "file lines"; now, when we have a long line that wraps to multiple screen
" lines, j and k behave as we expect them to.

" When navigating up/down a line and not given an explicit count, move by
" **display** line (after wrapping). If given a count larger than 5, insert the
" current location to the jump list.
function! s:SmartCursorLineMovementCmd(direction) abort
  if index(['up', 'down'], a:direction) == -1
    call vimrc#Error('Invalid direction: %s', a:direction)
    return
  endif
  let l:key = a:direction is# 'down' ? 'j' : 'k'
  if v:count
    return (v:count > 5 ? "m'" . v:count : '') . l:key
  endif
  return 'g' . l:key
  " As of 2022-05-30, this code causes issues when holding the up/down keys- the
  " cursor jumps a bit without making progress. I don't remember why I wrote it
  " in the first place, it was probably needed in some older version of VSCode
  " Neovim.
  " if !g:VSCODE_MODE
  "   return 'g' . l:key
  " endif
  " let l:params = printf("{ 'to': '%s', 'by': 'wrappedLine', 'value': %d }", 
  "     \ a:direction, v:count ? v:count : 1)
  " return printf("\<Cmd>call VSCodeNotify('cursorMove', %s)\<CR>", l:params)
endfunction

" Normal mode.
nnoremap j <Left>
nnoremap <expr> k <SID>SmartCursorLineMovementCmd('down')
nnoremap <expr> i <SID>SmartCursorLineMovementCmd('up')
nnoremap <expr> <Down> <SID>SmartCursorLineMovementCmd('down')
nnoremap <expr> <Up> <SID>SmartCursorLineMovementCmd('up')
nnoremap l <Right>

" Visual mode.
if g:vimrc_consistent_movement
  xnoremap j <Left>
  " Move by visual lines, but only in visual character mode, not visual line mode.
  " See also: https://vi.stackexchange.com/a/9279
  xnoremap <expr> k mode() is# 'v' ? 'gj' : 'j'
  xnoremap <expr> i mode() is# 'v' ? 'gk' : 'k'
  xnoremap l <Right>
else
  xnoremap j <Cmd>echoerr 'Keybinding removed'<CR>
  " Move by visual lines, but only in visual character mode, not visual line mode.
  " See also: https://vi.stackexchange.com/a/9279
  xnoremap <expr> <Down> mode() is# 'v' ? 'gj' : 'j'
  xnoremap k <Cmd>echoerr 'Keybinding removed'<CR>
  xnoremap <expr> <Up> mode() is# 'v' ? 'gk' : 'k'
  xnoremap l <Cmd>echoerr 'Keybinding removed'<CR>
endif

" Expose plug mappings that are used later.
inoremap <Plug>(vimrc-insert-down) <C-O>g<Down>
inoremap <Plug>(vimrc-insert-up) <C-O>g<Up>
imap <Down> <Plug>(vimrc-insert-down)
imap <Up> <Plug>(vimrc-insert-up)

" Use w/e for words movements and disable b. e is already mapped correctly by
" default.
nnoremap w b
xnoremap w b
onoremap w b
nnoremap W B
xnoremap W B
onoremap W B

" Make Ctrl-e/y go faster
nnoremap <C-E> 3<C-E>
nnoremap <C-Y> 3<C-Y>

" Remap jk in insert mode to return to normal mode.
inoremap jk <Esc>

" Delete backwards with Ctrl+Backspace and forward with Ctrl+Delete.
inoremap <C-BS> <C-W>
cnoremap <C-BS> <C-W>
tnoremap <C-BS> <C-W>
inoremap <C-DEL> <C-O>de

" Navigate folds
nnoremap zi zk
xnoremap zi zk
nnoremap zk zj
xnoremap zk zj

" Initially I used the following keymapping. This collides with the vim
" easymotion default prefix so I disabled it for now.
" nnoremap <Leader><Leader> :
nnoremap <Leader>; :
xnoremap <Leader>; :

" By default join lines without the leading spaces which is often indentation in
" code I work with.
nnoremap gj J
xnoremap gj J

" Unmap Q which goes into ex mode, which I never use.
nnoremap  Q <Nop>
xnoremap  Q <Nop>
nnoremap gQ <Nop>

" Unmap <C-Q>, which is used as my tmux prefix key. <C-V> is the same.
noremap <C-Q> <Cmd>echoerr 'Keybinding removed'<CR>
noremap! <C-Q> <Cmd>echoerr 'Keybinding removed'<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                 Indentation                                  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Indentation settings
" TODO: investigate whether `copyindent` is worth enabling.
set autoindent     " Copy indentation level from previous line.
set smartindent    " Smart auto-indenting for new lines.
set smarttab       " Tab emits shiftwidth spaces for first chars on a line.
set expandtab      " Use spaces when tab is used.
set shiftwidth=2   " 2 space indent by default.
set softtabstop=2
set tabstop=2      " Show 2 spaces instead of tabs.
set shiftround     " Round indent to multiple of shiftwidth with < and >.

" Using '<' and '>' in visual mode to shift code by a tab-width left/right by
" default exits visual mode. With this mapping we remain in visual mode after
" such an operation.
xnoremap < <gv
xnoremap > >gv

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                  Copy/paste                                  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Copy to selection clipboard in addition to the default register, but don't
" copy to the primary clipboard. This is later done but only for yank
" operations.
set clipboard=unnamedplus
" Other plugins (integrations, etc)
" NOTE: As of 2019-09-17, this plugin seems not needed - bracketed paste works
" even without it in both neovim and vim.
" Plug 'ConradIrwin/vim-bracketed-paste'

" Make Y consistent with C and D.
nnoremap Y "+y$

" Options toggling with leader + t + *
" Toggle paste
nnoremap <Leader>tp <Cmd>set paste!<CR>

Plug 'svermeulen/vim-easyclip'
let g:EasyClipYankHistorySize = 1000
let g:EasyClipShareYanksDirectory = g:VIM_DATA_DIR
let g:EasyClipEnableBlackHoleRedirect = 1
let g:EasyClipUseSubstituteDefaults = 0
let g:EasyClipUseYankDefaults = 0
let g:EasyClipUseCutDefaults = 0
let g:EasyClipUsePasteDefault = 0
let g:EasyClipUsePasteToggleDefaults = 0

nmap S <Plug>SubstituteOverMotionMap
nmap SS <Plug>SubstituteToEndOfLine
xmap S <Plug>XEasyClipPaste
nmap M <Plug>MoveMotionPlug
xmap M <Plug>MoveMotionXPlug
nmap MM <Plug>MoveMotionLinePlug

" Map Ctrl+V to paste from system clipboard in insert and command mode.
" NOTE: As of 2019-09-17, this no longer seems to be needed because of bracketed
" paste detection. In fact, it's actually better to use the built-in bracketed
" paste detection instead of these mappings, because then it works correctly in
" all modes and I can also use <C-V> for its default behavior.
" cnoremap <C-V> <Plug>EasyClipCommandModePaste
" nnoremap <C-V> "+p
" inoremap <C-V> <C-O><Plug>EasyClipInsertModePaste

Plug 'matze/vim-move'
let g:move_map_keys = 0
" Autoindenting sometimes misbehaves, so disable it.
let g:move_auto_indent = 0

" Move lines up/down.
xmap I <Plug>MoveBlockUp
xmap K <Plug>MoveBlockDown
" Move blocks left/right in regular visual mode. Change indentation in visual
" line mode.
xnoremap <expr> J mode() is# 'v' ? "\<Plug>MoveBlockLeft" : '<gv'
xnoremap <expr> L mode() is# 'v' ? "\<Plug>MoveBlockRight" : '>gv'

" " Moving lines up and down similar to
" " http://vim.wikia.com/wiki/Moving_lines_up_or_down
" xnoremap I <Cmd>m '<-2<CR>
" xnoremap K <Cmd>m '>+1<CR>
" " More convenient indent/deindent in visual mode.
" xnoremap J <gv
" xnoremap L >gv

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                              Undo, Redo, Repeat                              "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set undofile          " Use persistent undo
set undolevels=10000  " More undo memory (default is 1000)

" CTRL-U and CTRL-W in insert mode cannot be undone.  Use CTRL-G u to first
" break undo, so that we can undo those changes after inserting a line break.
" For more info, see: http://vim.wikia.com/wiki/Recover_from_accidental_Ctrl-U
inoremap <C-U> <C-G>u<C-U>
inoremap <C-W> <C-G>u<C-W>

Plug 'tpope/vim-repeat'
let g:vim_repeat_default_mappings = 0

nmap . <Plug>(RepeatDot)

" NOTE: As of 2020-04-28, vim-highlightedundo is disabled because:
" - It's very slow when the undo has a large diff. To reproduce, try to comment
"   1000+ lines in a file and then undo. See also the issue I opened [1].
" - It interferes with editing when I'm repeating the undo key (starts spitting
"   out unrelated text from the plugin mappings).
" [1] https://github.com/machakann/vim-highlightedundo/issues/4
" Plug 'machakann/vim-highlightedundo'

nnoremap <silent> <Plug>(MyUndo)     <Cmd>call vimrc#undo#Undo(v:count)<CR>
nnoremap <silent> <Plug>(MyUndoLine) <Cmd>call vimrc#undo#UndoLine(v:count)<CR>
nnoremap <silent> <Plug>(MyRedo)     <Cmd>call vimrc#undo#Redo(v:count)<CR>

" Undo/Redo with u/Alt+u in normal mode.
nmap u     <Plug>(MyUndo)
nmap <M-u> <Plug>(MyRedo)
" Not typed directly- I'm using scripts to define a global undo/redo that works
" in terminals and outside.
nmap <M-_> <Plug>(MyUndo)
nmap <M-+> <Plug>(RepeatRedo)
" nnoremap <M-_> u
" nnoremap <M-+> <C-R>
" NOTE: vim-repeat mappings don't seem to work in visual or insert modes, but
" that's not important because I rarely need to undo/redo in these modes.
" imap <M-_> <C-o><Plug>(RepeatUndo)<C-o><C-o>
" imap <M-+> <C-o><Plug>(RepeatRedo)<C-o><C-o>
" xmap <M-_> <Esc><Plug>(RepeatUndo)gv
" xmap <M-+> <Esc><Plug>(RepeatRedo)gv
inoremap <M-_> <C-O>u
inoremap <M-+> <C-O><C-R>
xnoremap <M-_> <Esc>ugv
xnoremap <M-+> <Esc><C-R>gv
" NOTE: As of 2019-09-19, I could not find a way to use undo/redo in vim's
" command line, so I'm just disabling the regular keybindings to avoid the
" insertion of weird characters.
cnoremap <M-_> <Nop>
cnoremap <M-+> <Nop>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                 Text objects                                 "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'tpope/vim-abolish'

" NOTE: As of 2019-10-06, anyblock is disabled in favor of targets.vim.
" Plug 'kana/vim-textobj-user' | Plug 'rhysd/vim-textobj-anyblock'
" let g:textobj_anyblock_no_default_key_mappings = 1
" " Needed because i is remapped in my vimrc. See also:
" " https://github.com/rhysd/vim-textobj-anyblock/issues/13
" let g:textobj#anyblock#no_remap_block_mapping = 1
" omap ib <Plug>(textobj-anyblock-i)
" omap ab <Plug>(textobj-anyblock-a)
" xmap <Leader>ib <Plug>(textobj-anyblock-i)
" xmap ab <Plug>(textobj-anyblock-a)

" Surround plugins overview:
"
" - vim-surround: original plugin I used. Didn't like its keymappings and other
"   things I don't remember (I also don't remember if the keymappings could be
"   configured to my taste), and replaced it with vim-operator-surround, which
"   is also simpler and better tested according to the author [1]. In further
"   testing, it doesn't respect surrounding whitespace (like
"   vim-operator-surround, see below).
" - vim-operator-surround: was replaced by vim-sandwich because the former
"   doesn't respect leading and trailing whitespace in visual mode [2]. For
"   example, if I select " a " and surround it with parenthesis, the result is
"   "(a)" instead of "( a )".
" - vim-sandwich pros:
"   - Highlightes the surrounded text and/or the surroundings after the operator
"     is started, which provides visual feedback.
"   - Supports counts for selecting further out (for example selecting the outer
"     parenthesis in "((test))" when the cursor is inside).
"   vim-sandwich cons:
"   - `<Plug>(operator-sandwich-replace)` is slow [3]
"
" - Issues common to all surround plugins above:
"   - Cursor is moved after operations
"
" [1] https://github.com/rhysd/vim-operator-surround#policy-of-this-plugin-or-the-reason-why-i-dont-use-vim-surround
" [2] https://github.com/rhysd/vim-operator-surround/issues/33
" [3] https://github.com/machakann/vim-sandwich/issues/94
let g:vimrc_surround_plugin = get(g:, 'vimrc_surround_plugin', 'vim-sandwich')

if g:vimrc_surround_plugin is# 'vim-surround'
  Plug 'tpope/vim-surround'
elseif g:vimrc_surround_plugin is# 'vim-operator-surround'
  Plug 'kana/vim-operator-user' | Plug 'rhysd/vim-operator-surround'
  nmap sa <Plug>(operator-surround-append)
  xmap sa <Plug>(operator-surround-append)
  nmap sd <Plug>(operator-surround-delete)
  xmap sd <Plug>(operator-surround-delete)
  nmap sr <Plug>(operator-surround-replace)
  xmap sr <Plug>(operator-surround-replace)
  " nmap sdd <Plug>(operator-surround-delete)<Plug>(textobj-anyblock-a)
  " nmap srr <Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)
  nmap sdd <Plug>(operator-surround-delete)<Leader>aB
  nmap srr <Plug>(operator-surround-replace)<Leader>aB
else
  if g:vimrc_surround_plugin isnot# 'vim-sandwich'
    call vimrc#Warning('Unknown surround plugin: %s, using default', 
        \ g:vimrc_surround_plugin)
  endif
  Plug 'machakann/vim-sandwich'
  let g:sandwich_no_default_key_mappings = 1
  let g:operator_sandwich_no_default_key_mappings = 1
  let g:textobj_sandwich_no_default_key_mappings = 1
  nmap sa <Plug>(operator-sandwich-add)
  xmap sa <Plug>(operator-sandwich-add)
  nmap sd <Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)
  xmap sd <Plug>(operator-sandwich-delete)
  nmap sr <Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)
  xmap sr <Plug>(operator-sandwich-replace)
  nmap sdd <Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)
  nmap srr <Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)
endif
" Unmap s (default vim command for substitution) so that there won't be a delay
" waiting for the next key.
nnoremap s <Nop>
xnoremap s <Nop>

Plug 'AndrewRadev/sideways.vim'
" NOTE: mappings are defined along with targets.vim mappings below.
" Argument text object based on sideways plugin.
" omap ia <Plug>SidewaysArgumentTextobjI
" omap aa <Plug>SidewaysArgumentTextobjA
" xmap <Leader>ia <Plug>SidewaysArgumentTextobjI
" xmap aa <Plug>SidewaysArgumentTextobjA
" Move args
nnoremap [a <Cmd>SidewaysLeft<CR>
nnoremap ]a <Cmd>SidewaysRight<CR>

" The line text object is used in expand-region if it's available.
" Plug 'kana/vim-textobj-user' | Plug 'kana/vim-textobj-line'
" let g:textobj_line_no_default_key_mappings = 1

Plug 'infokiller/vim-expand-region'
let g:expand_region_text_objects = {
    \ 'iw'  :0,
    \ 'iW'  :0,
    \ 'i"'  :0,
    \ 'i''' :0,
    \ 'i)'  :1,
    \ 'a)'  :1,
    \ 'i]'  :1,
    \ 'a]'  :1,
    \ 'i>'  :1,
    \ 'a>'  :1,
    \ 'i}'  :1,
    \ 'a}'  :1,
    \ 'it'  :1,
    \ 'at'  :1,
    \ 'is'  :0,
    \ 'ip'  :0,
\ }

Plug 'wellle/targets.vim'
" Targets that are around the cursor, whether the start/end in the current line
" or not.
let s:TARGETS_AROUND_CURSOR = 'cc cr cb cB lc ac Ac lr lb ar ab lB Ar aB Ab AB'
" Targets that are distant (i.e. start after the cursor position or end before
" the cursor position).
let s:TARGETS_DISTANT_VISIBLE = 'rr ll rb al rB Al bb aa bB Aa'
" Always prefer targets that contain the cursor position, even if they span
" multiple lines. For example, assume the following text file ('|' wraps the
" cursor position):
"
" foo(
"   |b|ar(a, b), c)
"
" If you now type "daa" (delete inside argument), I expect `bar(a, b), ` to be
" deleted and not `a, `.
" Also, enable automatic seeking for distant targets, but with a lower priority
" than targets that wrap the current cursor position, and only if one of the
" target ends is visible on screen.
let g:targets_seekRanges =
      \ printf('%s %s', s:TARGETS_AROUND_CURSOR, s:TARGETS_DISTANT_VISIBLE)

if g:vimrc_consistent_movement
  let g:targets_aiAI = ['<Leader>a', '<Leader>i', '<Leader>A', '<Leader>I']
  let g:targets_mapped_aiAI = ['a', 'i', 'A', 'I']

  " Helper function for mapping <Leader>i to i in visual block modes, where it
  " can be used to insert text to lines in a block, but for regular visual mode
  " and visual line mode keep it (used later for text objects). The same is done
  " for <Leader>I.
  function! s:InsertOrTextobj(key) abort
    if mode() is# "\<C-v>"
      call feedkeys(a:key, 'n')
      return ''
    endif
    return targets#e('x', a:key, a:key)
  endfunction

  " Define leader-less mappings in operator pending mode to replace sideways.vim
  " and vim-textobj-anyblock.
  function! s:TargetWithSuffix(prefix, suffix) abort
    " Note that feedkeys will queue these chars for processing, so they will
    " actually only take effect after the returned keys are processed.
    call feedkeys(a:suffix, 'n')
    return targets#e('o', a:prefix, a:prefix)
  endfunction

  function! s:MapTargets() abort
    " targets.vim won't map a key if it's already mapped, so we must map it
    " manually here.
    xmap <expr> <Leader>i <SID>InsertOrTextobj('i')
    xmap <expr> <Leader>I <SID>InsertOrTextobj('I')

    omap <expr> i targets#e('o', 'i', 'i')
    omap <expr> a targets#e('o', 'a', 'a')
    " NOTE: I'm using 'Ia' here to be consistent with the behavior of
    " sideways.vim.
    " NOTE: As of 2019-12-16, targets.vim is disabled for arguments text objects
    " because it fails in the following case: `foo('a,b')`. See also:
    " https://github.com/wellle/targets.vim/issues/107
    " omap <expr> ia <SID>TargetWithSuffix('I', 'a')
    " omap <expr> ila <SID>TargetWithSuffix('I', 'la')
    " omap <expr> ina <SID>TargetWithSuffix('I', 'na')
    omap ia <Plug>SidewaysArgumentTextobjI
    omap aa <Plug>SidewaysArgumentTextobjA
    xmap <Leader>ia <Plug>SidewaysArgumentTextobjI
    xmap <Leader>aa <Plug>SidewaysArgumentTextobjA
    " for l:prefix in ['i', 'a']
    "   for l:suffix in ['b','lb', 'nb', 'B', 'lB', 'nB', 'q', 'lq', 'nq']
    "     exec printf("omap <expr> %s <SID>TargetWithSuffix('%s', '%s')",
    "         \ l:prefix, l:prefix, l:prefix.l:suffix)
    "   endfor
    " endfor
  endfunction

  call s:MapTargets()
else
  let g:targets_aiAI = ['a', 'i', '<Leader>a', '<Leader>i']
  let g:targets_mapped_aiAI = ['a', 'i', 'A', 'I']
endif

augroup vimrc
  " Add 'iB'/'aB'/'IB'/'AB' text objects for selecting between any separator,
  " bracket, quote, or tag.
  " TODO: This is slow in large files, fix this. See:
  " https://github.com/wellle/targets.vim/issues/250
  autocmd User targets#mappings#user call targets#mappings#extend({
      \ 'B': {
      \     'separator': [{'d':','}, {'d':'.'}, {'d':';'}, {'d':':'}, {'d':'+'}, {'d':'-'},
      \                   {'d':'='}, {'d':'~'}, {'d':'_'}, {'d':'*'}, {'d':'#'}, {'d':'/'},
      \                   {'d':'\'}, {'d':'|'}, {'d':'&'}, {'d':'$'}],
      \     'pair':      [{'o':'(', 'c':')'}, {'o':'[', 'c':']'}, {'o':'{', 'c':'}'}, {'o':'<', 'c':'>'}],
      \     'quote':     [{'d':"'"}, {'d':'"'}, {'d':'`'}],
      \     'tag':       [{}],
      \     },
  \ })
augroup END

" Disabled since it's not used and introduces a conflict in visual mode
" keybindings.
" Plug 'michaeljsmith/vim-indent-object'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                   Autopair                                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set showmatch        " When a bracket is inserted, briefly jump to the matching one.
set matchpairs+=<:>  " By default only '()', '{}', and '[]' are matched.

runtime macros/matchit.vim
Plug 'Valloric/MatchTagAlways', { 'for': ['xml', 'html'] }

" auto-pairs won in the following auto closers comparison:
" http://aftnn.org/post/75730734352/vim-auto-closers-compared
" NOTE: As of 2019-10-22, I switched back to using delimitMate, which actually
" looks less buggy and has tests.
" Plug 'jiangmiao/auto-pairs'

" Disable AutoPairs mappings
" let g:AutoPairsShortcutToggle = ''
" let g:AutoPairsShortcutFastWrap = ''
" let g:AutoPairsShortcutJump = ''
" let g:AutoPairsShortcutBackInsert = ''
" let g:AutoPairsMapBS = 0
" let g:AutoPairsMapCh = 0
" let g:AutoPairsMapCR = 0
" let g:AutoPairsCenterLine = 0
" let g:AutoPairsMapSpace = 0

Plug 'Raimondi/delimitMate'

" delimitMate won't trigger in comments by default. This makes it work in
" comments as well.
let g:delimitMate_excluded_regions = ''
" When inserting a space inside an empty pair, add a matching space at the end.
let g:delimitMate_expand_space = 1
let g:delimitMate_expand_cr = 0
let g:delimitMate_matchpairs = '(:),[:],{:}'
" Break undo sequence and use delimitMate's "smart" CR.
imap <Plug>(vimrc-cr) <C-G>u<Plug>delimitMateCR
imap <CR> <Plug>(vimrc-cr)
" Add dummy mapping for <Plug>delimitMateS-Tab to prevent shift-tab from being
" remapped.
imap <Plug>(delimitMate_nop) <Plug>delimitMateS-Tab

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                  Commenting                                  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
augroup vimrc
  " Default to hash comments for files that don't define it.
  autocmd BufReadPost,BufNewFile,FileType * if empty(&commentstring) || empty(&filetype)
      \ | setlocal commentstring=#%s | endif
  " As of 2020-05-13, I'm using after/ftplugin directory to set the
  " commentstring, since otherwise it gets overridden in the regular ftplugin
  " files.
  " " Override default systemd, crontab, and gitconfig comments to use hashes.
  " autocmd BufReadPost,BufNewFile,FileType *
  "     \ if index(['systemd', 'crontab', 'dosini', 'gitconfig'], &ft) >= 0
  "     \ | setlocal commentstring=#%s | endif
augroup END

" Plug 'tpope/vim-commentary'
" Must use map and not noremap here because the Plug commands are also mapped.
" nmap <Leader>c<Leader> <Plug>CommentaryLine
" xmap <Leader>c<Leader> <Plug>Commentary

Plug 'tomtom/tcomment_vim', { 'on':
    \ ['TComment', 'TCommentAs', 'TCommentRight', 'TCommentMaybeInline'] }
let g:tcomment_maps = 0
" When commenting a region in a markdown file, try to guess the filetype by the
" syntax groups in the region. This is needed to support embedded filetypes
" (fenced code blocks), though it doesn't work consistently.
let g:tcomment#filetype#guess_markdown = 1
let g:tcomment_types = {
    \ 'text'      : ['# %s'],
    \ 'systemd'   : ['# %s'],
    \ 'crontab'   : ['# %s'],
    \ 'dosini'    : ['# %s'],
    \ 'gitconfig' : ['# %s'],
    \ 'cpp'       : ['// %s'],
    \ 'proto'     : ['// %s'],
    \ 'xkb'       : ['// %s'],
    \ 'json'      : ['// %s'],
    \ 'markdown'  : ['<!-- %s -->'],
\ }
nnoremap <Leader>c<Leader> <Cmd>TComment<CR>
xnoremap <Leader>c<Leader> :TComment<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                           Jumplist and Changelist                            "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plug 'infokiller/vim-EnhancedJumps'

let g:EnhancedJumps_no_mappings = 1
" Back and forward in the jump list using J and L, similar to the Chrome
" bindings I use (alt+j, alt+l). Also, center the line on the screen after
" jumping.

if g:VSCODE_MODE
  nnoremap J <Cmd>call VSCodeNotify('workbench.action.navigateBack')<CR>
  nnoremap L <Cmd>call VSCodeNotify('workbench.action.navigateForward')<CR>
else
  nnoremap J <C-O>zz
  nnoremap L <C-I>zz
endif
" " Similar to the above for the change list.
nnoremap K g;zz
nnoremap I g,zz
" NOTE: As of 2019-10-30, I disabled these mappings because I suspend they have
" some issues.
" nmap J <Plug>EnhancedJumpsOlderzz
" nmap L <Plug>EnhancedJumpsNewerzz
" nmap K <Plug>EnhancedJumpsFarFallbackChangeOlderzz
" nmap I <Plug>EnhancedJumpsFarFallbackChangeNewerzz

" Navigate jump list
nnoremap [j <C-O>zz
nnoremap ]j <C-I>zz
" Navigate change list
nnoremap [c g;zz
nnoremap ]c g,zz

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                          Enhanced Quickfix/Loclist                           "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Consider changing these to use my custom quickfix/loclist navigation
" functions.
" Navigate quickfix list
nnoremap [q <Cmd>cprev<CR>zz
nnoremap ]q <Cmd>cnext<CR>zz
" Navigate location list
nnoremap [l <Cmd>lprev<CR>zz
nnoremap ]l <Cmd>lnext<CR>zz

" Used for the following features:
" - Hiding quickfix buffers from buffer navigation commands like `:bn`
" - Quitting if the last window is a location/quickfix window
" - Closing the location window after the parent window is closed
" - Toggling location/quickfix windows
" - Keeping history of lists and navigating history with left/right
Plug 'romainl/vim-qf'
" The quickfix list is used for things like multi file search, in which case I
" usually want to open it automatically, but the location list is often used for
" things that are frequently updated in the background, like spelling errors
" (vim-spellcheck) or lint errors (ALE). In these cases, I don't want it to open
" automatically, because it interrupts my flow.
" As of 2020-06-01, I disabled opening the quickfix list automatically, as I
" prefer to make this decision per action. Multi file search seems to be working
" out of the box with ferret.
let g:qf_auto_open_quickfix = 0
let g:qf_auto_open_loclist = 0
nmap <Leader>jq <Plug>(qf_qf_toggle)
nmap <Leader>jl <Plug>(qf_loc_toggle)

" Make replacement directly in the quickfix window.
Plug 'stefandtw/quickfix-reflector.vim'

" Plug 'Valloric/ListToggle'
" " Plug 'milkypostman/vim-togglelist'
" let g:toggle_list_no_mappings = 1
" let g:lt_quickfix_list_toggle_map = '<Leader>jq'
" let g:lt_location_list_toggle_map = '<Leader>jl'

Plug 'infokiller/vim-errorlist'
let g:error_list_post_command = 'normal! zz'
let g:error_list_max_items = 2000

" Navigate quickfix list with Ctrl+{p,n}
nnoremap <C-P> <Cmd>QuickFixPrev<CR>
nnoremap <C-N> <Cmd>QuickFixNext<CR>

" Navigate location list with Alt+{p,n}
if g:VSCODE_MODE
  nnoremap <M-p> <Cmd>call VSCodeNotify('editor.action.marker.prev')<CR>
  nnoremap <M-n> <Cmd>call VSCodeNotify('editor.action.marker.next')<CR>
else
  nnoremap <M-p> <Cmd>LoclistPrev<CR>
  nnoremap <M-n> <Cmd>LoclistNext<CR>
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                  Bookmarks                                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plug 'kshenoy/vim-signature'
" Plug 'MattesGroeger/vim-bookmarks'

let g:bookmark_auto_save_file = Concat(g:VIM_DATA_DIR, '/vim-bookmarks')

" Only use a subset of letters for marks for now, the rest are used for commands
" (prev/next mark, list marks, etc).
let g:SignatureIncludeMarks = 'abcdefghijkoqrstuvwxyz'

let g:SignatureMap = {
  \ 'Leader'             :  'm',
  \ 'PlaceNextMark'      :  'mM',
  \ 'ToggleMarkAtLine'   :  'mm',
  \ 'PurgeMarksAtLine'   :  'm-',
  \ 'DeleteMark'         :  'mD',
  \ 'PurgeMarks'         :  'mDD',
  \ 'PurgeMarkers'       :  'mDm',
  \ 'GotoNextLineAlpha'  :  "']",
  \ 'GotoPrevLineAlpha'  :  "'[",
  \ 'GotoNextSpotAlpha'  :  '`]',
  \ 'GotoPrevSpotAlpha'  :  '`[',
  \ 'GotoNextLineByPos'  :  "]'",
  \ 'GotoPrevLineByPos'  :  "['",
  \ 'GotoNextSpotByPos'  :  'mn',
  \ 'GotoPrevSpotByPos'  :  'mp',
  \ 'GotoNextMarker'     :  ']-',
  \ 'GotoPrevMarker'     :  '[-',
  \ 'GotoNextMarkerAny'  :  ']=',
  \ 'GotoPrevMarkerAny'  :  '[=',
  \ 'ListBufferMarks'    :  'ml',
  \ 'ListBufferMarkers'  :  'm?'
  \ }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                  Modelines                                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Disable modelines which are insecure, and instead use the securemodelines
" plugin which only enables a safe subset of modelines features. See also:
" https://github.com/numirias/security/blob/f885bb/doc/2019-06-04_ace-vim-neovim.md
set nomodeline
Plug 'ciaranm/securemodelines'
" Only added commentstring to plugin defaults.
let g:secure_modelines_allowed_items = [
    \ 'textwidth',   'tw',
    \ 'softtabstop', 'sts',
    \ 'tabstop',     'ts',
    \ 'shiftwidth',  'sw',
    \ 'expandtab',   'et',   'noexpandtab', 'noet',
    \ 'commentstring',
    \ 'filetype',    'ft',
    \ 'foldmethod',  'fdm',
    \ 'readonly',    'ro',   'noreadonly', 'noro',
    \ 'rightleft',   'rl',   'norightleft', 'norl',
    \ 'cindent',     'cin',  'nocindent', 'nocin',
    \ 'smartindent', 'si',   'nosmartindent', 'nosi',
    \ 'autoindent',  'ai',   'noautoindent', 'noai',
    \ 'spell', 'nospell',
    \ 'spelllang'
\ ]

" If exrc is on, it automatically loads any .exrc or .vimrc files in the local
" directory, which is a big security risk. The default for this option should be
" off anyway for any version of vim I'll be using (neovim even removed this
" option), but setting this explicitly is harmless. See also:
" https://github.com/vim/vim/issues/1015
set noexrc
set secure 

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                     Misc                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Several vim ftplugins in the default distribution use these settings to
" determine if they should remap keys. There is also the general
" `g:no_plugin_maps` setting which can disable the mappings for all these
" ftplugins, but I don't use it because vim (but not nvim) defines the man
" mappings using <SID>, so I can't replicate these mappings in my vimrc.
"
" This list can be generated by the following command:
" \rg -I -N -o '"(g:)?no_\w+_maps?"' /usr/share/{n,}vim | \
"   grep -v 'no_(plugin|man)_maps' | sort -u | py -x 'x[1:-1]' | \
"   py -x 'x if x.startswith("g:") else "g:" + x' | \
"   py -x '"let {} = 1".format(x)'
"
" As of 2020-05-31, this is configure in the ftplugin directories for each
" filetype.
" let g:no_man_maps = 1
" let g:no_cobol_maps = 1
" let g:no_cucumber_maps = 1
" let g:no_eiffel_maps = 1
" let g:no_gitrebase_maps = 1
" let g:no_pdf_maps = 1
" let g:no_ruby_maps = 1
" let g:no_lprolog_maps = 1
" let g:no_mail_maps = 1
" let g:no_ocaml_maps = 1
" let g:no_spec_maps = 1
" let g:no_vim_maps = 1
" let g:no_zimbu_maps = 1

Plug 'wakatime/vim-wakatime'
if !empty($DISPLAY) && $HOST_ALIAS =~# '\v\C^(zeus|hera)'
  Plug 'ActivityWatch/aw-watcher-vim'
endif
