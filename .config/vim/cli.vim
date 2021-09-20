""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                           Command line completion                            "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set wildmenu  " Enhanced command completion.
" Complete till the longest match and show all matches, also iterate over the
" matches.
set wildmode=longest:full,full
set wildignorecase  " Ignore case when auto completing.
set wildignore+=.hg,.git,.svn                    " Version control
set wildignore+=*.aux,*.out,*.toc                " LaTeX intermediate files
set wildignore+=*.jpg,*.bmp,*.gif,*.png,*.jpeg   " binary images
set wildignore+=*.o,*.obj,*.exe,*.dll,*.manifest " compiled object files
set wildignore+=*.spl                            " compiled spelling word lists
set wildignore+=*.pyc                            " Python byte code
" Use tab for command mode completion.
set wildchar=<Tab>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                             Command line editing                             "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Make Ctrl-a go to the beginning of the command line. Ctrl-e already works by
" default.
cnoremap <C-A> <Home>

" TODO: Fix EditCmdline in VSCode.
" Edit current command in normal buffer similar behavior to readline/zsh.
cnoremap <expr> <C-X><C-E> vimrc#EditCmdline()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                  Searching                                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'rhysd/clever-f.vim'
" Plug 'Lokaltog/vim-easymotion'

" Makes vim's regex engine "not stupid". See :h magic.
set magic
" If search term is all lowercase search will be case insensitive. Otherwise,
" search will be case sensitive.
set ignorecase smartcase
set incsearch    " Incremental search.
set hlsearch     " Highlight matches of previous searches.
set shortmess-=S " Show the search index ("[m/n] matches").

" Remap Ctrl+F to find. We intentionally use regular mappings here so that any
" mappings applied to / will be applied here as well.
" Also, use "very magic" searching by default, which is much more similar to the
" syntax I use in rg and other tools.
nnoremap <C-F> /\v
inoremap <C-F> <Esc>/\v
nnoremap / /\v
xnoremap / /\v

" Only highlight the current word when using * but don't jump to the next one.
" NOTE: Using * causes scrolling to the next match so we avoid it.
" Use "very nomagic" search mode because it's easiest to escape - only requires
" escaping forward and back slashes.
nnoremap * <Cmd>let @/ = printf('\V\<%s\>', escape(expand('<cword>'), '/\'))
    \ \| call histadd('/', @/) \| set hls<CR>
nnoremap # <Cmd>let @/ = printf('\V\<%s\>', escape(expand('<cword>'), '/\')) 
    \ \| call histadd('/', @/) \| let v:searchforward = 0 \| set hls<CR>
nnoremap g* <Cmd>let @/ = printf('\V%s', escape(expand('<cword>'), '/\')) 
    \ \| call histadd('/', @/) \| set hls<CR>
nnoremap g# <Cmd>let @/ = printf('\V%s', escape(expand('<cword>'), '/\')) 
    \ \| call histadd('/', @/) \| let v:searchforward = 0 \| set hls<CR>

Plug 'thinca/vim-visualstar'
" Make visual star plugin behave the same as my normal search settings: don't
" jump to the next match.
let g:visualstar_no_default_key_mappings = 1
xmap * <Plug>(visualstar-*)N
xmap g* <Plug>(visualstar-g*)N
xmap # <Plug>(visualstar-#)N
xmap g# <Plug>(visualstar-g#)N

Plug 'rhysd/devdocs.vim'
nnoremap <Leader>sd :<C-U>DevDocs<Space>
" nnoremap <expr> <Leader>sd Concat('*:DevDocs ', expand('<cword>'))
xnoremap <Leader>sd ""y:DevDocs<Space><C-R>"<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                  Replacing                                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set gdefault     " Global search/replace by default.
" Live feedback on substitutions. As of 2018-12-09, only available in neovim.
if exists('&inccommand')
  set inccommand=nosplit
endif

" This seems to cause issues in vscode

" NOTE: VSCode has issues with the search commands:
" - The "%s" mapping causes issues when searching
" - Trailing left movements result in "trailing characters" errors
" - bufdo and argdo commands don't work, even without confirmation.
" confirmation, so they're only used if not in VSCode.
"
" I should probably map the bufdo and argdo replacement keybindings to vscode
" native commands.

" Search and replace current word in current buffer.
nnoremap <expr> <Leader>rr printf(
    \ ":\<C-U>normal *<CR>:\<C-U>" . '%%s/\V\<%s\>/%s/%s', 
    \ escape(expand('<cword>'), '/\'), 
    \ expand('<cword>'), 
    \ g:VSCODE_MODE ? '' : "\<Left>")
" Search and replace current selection in current buffer.
" Use "very nomagic" search mode because it's easiest to escape - only requires
" escaping forward and back slashes.
xnoremap <expr> <Leader>rr Concat('""y:%s/\V', 
    \ "\<C-R>", '=escape(@", "/\\")', "\<CR>/",
    \ "\<C-R>", '=escape(@", "/\\")', "\<CR>/I",
    \ g:VSCODE_MODE ? '' : repeat("\<Left>", 2))

if g:VSCODE_MODE
  finish
endif

" Search and replace current word in all buffers.
" The e flag is required to avoid errors when a buffer does not have a match.
nnoremap <expr> <Leader>rb Concat('*:', "\<C-U>",
    \ 'bufdo %s//', expand('<cword>'), '/eI', 
    \ g:VSCODE_MODE ? '' : 'c' . repeat("\<Left>", 4))
" Search and replace current word in all args.
" The e flag is required to avoid errors when a buffer does not have a match.
nnoremap <expr> <Leader>ra Concat('*:', "\<C-U>",
    \ 'argdo %s//', expand('<cword>'), '/eI',
    \ g:VSCODE_MODE ? '' : 'c' . repeat("\<Left>", 4))
" Search and replace current selection in all buffers.
" Use "very nomagic" search mode because it's easiest to escape - only requires
" escaping forward and back slashes.
" The e flag is required to avoid errors when a buffer does not have a match.
xnoremap <expr> <Leader>rb Concat('""y:bufdo %s/\V',
    \ "\<C-R>", '=escape(@", "/\\")', "\<CR>/",
    \ "\<C-R>", '=escape(@", "/\\")', "\<CR>/eI",
    \ g:VSCODE_MODE ? '' : 'c' . repeat("\<Left>", 4))
" Search and replace current selection in all args.
" Use "very nomagic" search mode because it's easiest to escape - only requires
" escaping forward and back slashes.
" The e flag is required to avoid errors when a buffer does not have a match.
xnoremap <expr> <Leader>ra Concat('""y:argdo %s/\V',
    \ "\<C-R>", '=escape(@", "/\\")', "\<CR>/",
    \ "\<C-R>", '=escape(@", "/\\")', "\<CR>/eI",
    \ g:VSCODE_MODE ? '' : 'c' . repeat("\<Left>", 4))

" Note that getcmdpos should be 1 because the cursor doesn't move till the map
" input can be resolved.
cnoremap <expr> %s ((getcmdtype() == ':' && getcmdpos() == 1) ? '%s/\v' : '%s')

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                 Sudo saving                                  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'lambdalisue/suda.vim'
" This mapping will allow us to save a file we don't have permission to save
" *after* we have already opened it.
if has('nvim')
  " NOTE: sudo is broken in nvim, see also:
  " https://github.com/neovim/neovim/issues/8217#issuecomment-380563447
  " Therefore, I'm now using a plugin.
  " cnoremap <expr> w!! get({':': 'w suda://%'}, getcmdtype(), 'w!!')
  command! -bar -count=0 SudoWrite w suda://%
else
  cnoremap <expr> w!!
      \ get({':': 'w !sudo tee % >/dev/null'}, getcmdtype(), 'w!!')
endif

" Provides SudoWrite and other misc commands (moving and finding files, etc).
" NOTE: As of 2019-09-18, I don't really use this plugin since I'm using
" suda.vim, and I'm invoking most file related commands from a shell.
" Plug 'tpope/vim-eunuch'
