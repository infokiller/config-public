scriptencoding utf-8
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                  Spellcheck                                  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let &spellfile = Concat(g:VIM_CONFIG_DIR, '/spell/en.utf-8.add')
" Don't correct me on uncapitalized words which are common in source code.
set spellcapcheck=''

Plug 'inkarkat/vim-ingo-library' | Plug 'infokiller/vim-spellcheck'
let g:SpellCheck_DefineAuxiliaryCommands = 0
let g:SpellCheck_DefineQuickfixMappings = 0

let g:SpellCheck_QuickfixHighlight = 1
augroup vimrc
  " Override vim-SpellCheck quickfix highlighting. The default setting seems
  " wrong.
  autocmd Syntax qf
      \ highlight link qfSpellErrorWord          SpellBad |
      \ highlight link qfSpellErrorWordInContext SpellBad |
      \ highlight link qfSpellContext            Normal
augroup END

" Turn off noisy linters by default.
" - languagetool has many false positives in markdown files. See also:
"   https://github.com/languagetool-org/languagetool/issues/445
let g:ale_linters_ignore = ['languagetool', 'alex', 'proselint', 'writegood']

function! VimrcEnableSpellCheck(do_extra_checks) abort
  let b:SpellCheck_RunOnALECycle = 1
  setlocal spell
  " Mnemonic: Spell Add
  nnoremap <buffer> <Leader>sa zg<C-L>
  " Mnemonic: Spell Dict
  nnoremap <buffer> <Leader>sd z=
  SpellLCheck!
  if a:do_extra_checks
    let b:ale_linters_ignore = []
    ALELint
  endif
endfunction

function! VimrcDisableSpellCheck() abort
  let b:SpellCheck_RunOnALECycle = 0
  " Clear linting results.
  call ale#other_source#ShowResults(bufnr(), g:SpellCheck_ALELinterName, [])
  setlocal nospell
  silent! nunmap <buffer> <Leader>sa
  silent! nunmap <buffer> <Leader>sd
  if exists('b:ale_linters_ignore')
    unlet b:ale_linters_ignore
  endif
endfunction

function! s:ToggleSpellCheck(do_extra_checks) abort
  if !&l:spell
    call VimrcEnableSpellCheck(a:do_extra_checks)
  else
    call VimrcDisableSpellCheck()
  endif
endfunction

" Toggle spell mode
nnoremap <silent> <Leader>ts <Cmd>call <SID>ToggleSpellCheck(0)<CR>
xnoremap <silent> <Leader>ts :call <SID>ToggleSpellCheck(0)<CR>
nnoremap <silent> <Leader>tS <Cmd>call <SID>ToggleSpellCheck(1)<CR>
xnoremap <silent> <Leader>tS :call <SID>ToggleSpellCheck(1)<CR>

" Plug 'rhysd/vim-grammarous'
" " Use the system LanguageTool command instead of downloading it.
" let g:grammarous#languagetool_cmd = 'languagetool'
" let g:grammarous#use_location_list = 1
" let g:grammarous#move_to_first_error = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                            Insert mode completion                            "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set infercase  " Consider the case in autocompletion
" Autocomplete with dictionary words when spell check is on
set complete+=kspell

" Insert the longest common text of all matches, and show the menu even if
" there's only one match. See also:
" http://vim.wikia.com/wiki/Make_Vim_completion_popup_menu_work_just_like_in_an_IDE
" NOTE: the "longest" option breaks YouCompleteMe. When loading the vimrc for
" the first time this doesn't have any effect, since YouCompleteMe removes it,
" but when resourcing vimrc it causes insert mode completion to break. See also:
" https://github.com/ycm-core/YouCompleteMe/blob/master/autoload/youcompleteme.vim#L498-L503
" set completeopt=longest,menuone
set completeopt=menuone

" Selects the current completion and hide the pop up menu if the pop up menu is
" visible, otherwise insert a newline.
function! s:SelectCompletionOrNewline() abort
  if pumvisible()
    " Double quotes are required for these keys to be recognized.
    " The second argument, set to 'm', causes remapping to be active (like in
    " map vs noremap), and is required because <C-Y> is mapped in YouCompleteMe
    " to a command that stops the completion and marks it as stopped.  If we had
    " used inoremap, YouCompleteMe wouldn't have marked the completion as
    " stopped, and this could cause some issues according to YouCompleteMe's
    " code.
    call feedkeys("\<C-Y>\<Space>", 'm')
  else
    " Double quotes are required for the special keys to be recognized.
    " Note that feedkeys is used with the 'n' argument. This is critical so that
    " the remapping won't be recursive.
    call feedkeys("\<Plug>(vimrc-cr)", 'm')
  endif
  return ''
endfunction

inoremap <expr> <CR> <SID>SelectCompletionOrNewline()

function! s:CompletionUpOrDown(is_down) abort
  if pumvisible()
    " Double quotes are required for these keys to be recognized.
    let l:pum_key = a:is_down ? "\<C-N>" : "\<C-P>"
    call feedkeys(l:pum_key, 'n')
  else
    " Double quotes are required for these keys to be recognized.
    " Go down/up by visual line using the 'g' prefix.
    let l:no_pum_key = a:is_down ?
        \ "\<Plug>(vimrc-insert-down)" : "\<Plug>(vimrc-insert-up)"
    " Double quotes are required for the special keys to be recognized.
    call feedkeys(l:no_pum_key, 'm')
  endif
  return ''
endfunction

inoremap <expr> <Down> <SID>CompletionUpOrDown(1)
inoremap <expr> <Up> <SID>CompletionUpOrDown(0)

function! s:TogglePreview() abort
  if &completeopt =~# 'preview'
    setlocal completeopt-=preview
  else
    setlocal completeopt+=preview
  endif
endfunction

nnoremap <Leader>tpw <Cmd>call <SID>TogglePreview()<CR>

let g:ycm_installer = Concat(g:REPO_ROOT, '/install/build-youcompleteme')
Plug 'Valloric/YouCompleteMe', { 'do': g:ycm_installer }

" Keys for navigating the completion menu.
" By default YouCompleteMe uses <Up> as well which conflicts with my mappings.
let g:ycm_key_list_select_completion = ['<Tab>']
" By default YouCompleteMe uses <Down> as well which conflicts with my mappings.
let g:ycm_key_list_previous_completion = ['<S-Tab>']

" Collect identifiers from comments and strings for YCM completions.
let g:ycm_collect_identifiers_from_comments_and_strings = 1
" Complete in comments as well.
let g:ycm_complete_in_comments = 1
let g:ycm_filetype_blacklist = {
    \ 'tagbar' : 1,
    \ 'vista' : 1,
    \ 'qf' : 1,
    \ 'netrw': 1,
    \ 'unite' : 1,
    \ 'vimwiki' : 1,
    \ 'pandoc' : 1,
    \ 'infolog' : 1,
    \ 'mail' : 1,
\ }
" Without this, peekaboo freezes in neovim (but not in vim). See:
" https://github.com/junegunn/vim-peekaboo/issues/64
let g:ycm_filetype_blacklist['peekaboo'] = 1

" Mnemonic: Code Open
nnoremap <Leader>co <Cmd>YcmCompleter GoTo<CR>
augroup vimrc
  autocmd FileType typescript
      \ nnoremap <buffer> <Leader>co <Cmd>YcmCompleter GoToDefinition<CR>
  autocmd FileType help
      \ nnoremap <buffer> <Leader>co <Cmd>call feedkeys("<C-]>", 'n')<CR>
  autocmd FileType man
      \ nnoremap <buffer> <Leader>co <Cmd>Man<CR>
  " TODO: Fix this for regular vim
augroup END
" Mnemonic: Code Help
nnoremap <Leader>ch <Cmd>YcmCompleter GetDoc<CR>

" Issues with CompleteParameter.vim:
" - <C-L> mapping (same as UltiSnips) conflicts with RefreshScreenCommand. I
"   think UltiSnips doesn't cause a conflict because it only remaps the keys
"   after a snippet was triggered, and undoes the mapping later after editing
"   continues.
" - Autopair doesn't work when editing an argumet (for example inserting a quote
"   doesn't insert a corresponding closing quote).
" Plug 'tenfyzhong/CompleteParameter.vim'
" let g:complete_parameter_use_ultisnips_mapping = 1
" inoremap <silent><expr> ( complete_parameter#pre_complete('()')
" smap <C-J> <Plug>(complete_parameter#goto_previous_parameter)
" imap <C-J> <Plug>(complete_parameter#goto_previous_parameter)
" smap <C-L> <Plug>(complete_parameter#goto_next_parameter)
" imap <C-L> <Plug>(complete_parameter#goto_next_parameter)

" NOTE: As of 2020-04-26, this doesn't work well for me: in a python file which
" I tested it, the preview window appears at the top and disappears quickly, and
" if the `preview` option is on I get two duplicate preview windows.
" Plug 'ncm2/float-preview.nvim'
" let g:float_preview#docked = 1

Plug 'wellle/tmux-complete.vim'
" Add words from tmux panes as possible YCM completions.
let g:tmuxcomplete#trigger = 'omnifunc'

inoremap <expr> <C-X><C-T>
    \ fzf#complete('tmux-list-words --all-but-current --scroll 1000 --min 5')

" NOTE: As of 2019-09-17, fzf-complete-word doesn't work on Arch because it
" requires the `words` package.
let g:list_dict_completion_words_cmd = Concat(
    \ g:VIM_CONFIG_DIR, '/list-dict-completion-words')
inoremap <expr> <C-X><C-K> fzf#vim#complete(g:list_dict_completion_words_cmd)
imap <C-X><C-F> <Plug>(fzf-complete-path)
imap <C-X><C-J> <Plug>(fzf-complete-file-ag)
imap <C-X><C-L> <Plug>(fzf-complete-line)

Plug 'esc/vim-zsh-completion'

" github-complete recommends installing vimproc for async communication.
Plug 'Shougo/vimproc.vim' | Plug 'rhysd/github-complete.vim'
let g:github_complete_enable_omni_completion = 0
imap <C-X><C-G> <Plug>(github-complete-manual-completion)

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                            Linting and formatting                            "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 80 columns by default. Filetype overrides are in after/ftplugin.
set textwidth=80
set formatoptions=tcqjlron

" Use * and - as as additional list patterns (by default only numbers are used).
" This improves the formatting of comments with list items that span multiple
" lines.
let &formatlistpat = '^\s*\(\d\+[\]:.)}\t ]\|[-*]\)\s*'

Plug 'google/vim-maktaba'
" Glaive is used to configure codefmt's maktaba flags.
Plug 'google/vim-glaive'
Plug 'google/vim-codefmt', { 'on':  ['FormatCode', 'FormatLines'] }
" Plug 'Chiel92/vim-autoformat'
" Without this setting, the cursor jumps when I'm editing a file with an
" editorconfig file. It seems that EditorConfig runs "trim_trailing_whitespace"
" on BufWritePre, which presumably doesn't work well with my file auto saving.
let g:EditorConfig_disable_rules = ['trim_trailing_whitespace']
Plug 'editorconfig/editorconfig-vim'

" ALE linter {{{ "
Plug 'w0rp/ale'
" let g:ale_sign_error = ''
let g:ale_sign_error = '✘'
let g:ale_sign_warning = '▲'
" Don't lint every time the text is changed (not slow because ALE is async, but
" potentially not battery friendly on my laptops, and may show temporary errors
" while I'm still editing).
let g:ale_lint_on_text_changed = 'never'
" Lint files the first time they're focused in a window.
let g:ale_lint_on_enter = 1
" Lint files on every save. I automatically save files after no more than 5
" seconds from the moment they were modified.
" TODO: autosaving can happen while I'm still editing in insert mode, which can
" be distracting and have a high false positive rate. It may be better to
" implement my own linting policy, for example only lint in normal mode if there
" were no modifications in the last N seconds.
let g:ale_lint_on_save = 1
" Fixing on save is disabled because it doesn't interact well with autosaving:
" since autosaving might occur while I'm editing, it can remove trailing
" whitespace that I just typed.
let g:ale_fix_on_save = 0

function! s:ALESetForBuffer(bufnr, value) abort
  call vimrc#Log('Setting ALE for bufnr: ' . a:bufnr . ' to: ' . a:value )
  call setbufvar(a:bufnr, 'ale_enabled', a:value)
  " If we're enabling linting for the current buffer, explicitly ask ALE to lint
  " it, because otherwise ALE won't lint it till the next time it's entered. For
  " the other buffers it doesn't matter, since ALE will lint them when they're
  " entered. I guess that I could also just call `ALEEnableBuffer`.
  if a:value && a:bufnr == bufnr('')
    " NOTE: ale#Queue mostly works, but has an issue with markdown files where
    " they don't show linting results when they're opened (although linting is
    " enabled for them). ALELint fixes this.
    " call ale#Queue(0, 0, a:bufnr )
    ALELint
  endif
endfunction

" Prettier formatting doesn't work with files that don't have markdown file
" extensions, such as when editing files in Firenvim. This fixes it.
" NOTE: This doesn't work because prettier doesn't work in markdown with line
" ranges: https://github.com/prettier/prettier/issues/5008
" function! s:MyFormatLines() abort
"   if &filetype isnot# 'markdown'
"     FormatLines
"     return
"   endif
"   let l:options = maktaba#plugin#Get('codefmt').Flag('prettier_options')
"   call maktaba#plugin#Get('codefmt').Flag('prettier_options',
"       \ ['--parser', 'markdown'])
"   try
"     FormatLines
"   finally
"     call maktaba#plugin#Get('codefmt').Flag('prettier_options', l:options)
"   endtry
" endfunction

nnoremap <Leader>te <Cmd>ALEToggleBuffer<CR>
xnoremap <Leader>te :ALEToggleBuffer<CR>
" ALEFix doesn't support line ranges [1], so it's only used for whole files.
" [1] https://github.com/dense-analysis/ale/issues/850
nnoremap <Leader>cf <Cmd>ALEFix<CR>
xnoremap <Leader>cf :FormatLines<CR>
nnoremap <Leader>fc <Cmd>echoerr 'Keybinding removed'<CR>
xnoremap <Leader>fc <Cmd>echoerr 'Keybinding removed'<CR>
" As of 2020-07-07, I disabled running FormatCode after ALEFixPost because it
" can mix different fixers. For example, codefmt only supports js-beautify for
" CSS, while ALE doesn't support it.
" augroup vimrc
"   autocmd User ALEFixPost FormatCode
" augroup END
let g:airline#extensions#ale#enabled = 1
let g:ale_fixers = get(g:, 'ale_fixers', {})
let g:ale_fixers['*'] = ['remove_trailing_lines', 'trim_whitespace']
" [Neovim only]: show the warning/error message near the line.
let g:ale_virtualtext_cursor = 1
let g:ale_virtualtext_delay = 50
let g:ale_virtualtext_prefix = '  '
" let g:ale_virtualtext_prefix = ' [ALE] '

Plug 'prabirshrestha/async.vim'
let g:vimrc_enable_autolint = 1
let s:AUTOLINT_CHECKER = Concat(g:VIM_CONFIG_DIR, '/should-enable-lint')
let g:autolint_git_remotes_whitelist = get(g:, 'autolint_git_remotes_whitelist', '/infokiller/')
" I used to disable ALE in $HOME/.local except $HOME/.local/bin, but not that's
" handled by should-enable-lint. For future reference:
" ALE has the g:ale_pattern_options that can be used to disable it for certain
" filenames, but it has two issues that prevented me from using it:
" 1. It has a race condition with `MaybeEnableLinting`
" 2. It always triggers on a buffer, while I want to enable/disable the linting
"    once and let the user the option to override it without interference
" let g:autolint_paths_blacklist = printf('\V\C\^%s/.local/\(bin/\)\@!',
"     \ escape($HOME, '\'))
let g:autolint_paths_blacklist = 'a^'
let s:file_to_lint_enabled = {}
let s:autolint_jobid_to_file = {}
function! s:MaybeEnableLinting(filepath) abort
  let l:buf_dict = vimrc#PathToBufDict(a:filepath)
  call vimrc#Log('filepath: %s, bufdict: %s', a:filepath, l:buf_dict)
  " vimrc#PathToBufDict returns -1 instead of a dict if the buffer was not
  " found.
  if type(l:buf_dict) == type(0)
    return
  endif
  let l:bufnr = l:buf_dict['bufnr']
  " Bail out if autolinting is disabled, we couldn't get the buffer
  " corresponding to the file, or ALE was already set for the buffer, since we
  " don't want to override another setting, we only want to set a default for
  " the buffer (though there's a race condition anyway, so we may still in fact
  " override it).
  if !g:vimrc_enable_autolint || has_key(getbufvar(l:bufnr, ''), 'ale_enabled')
    return
  endif
  if has_key(s:file_to_lint_enabled, a:filepath)
    call s:ALESetForBuffer(l:bufnr, s:file_to_lint_enabled[a:filepath])
    return
  endif
  " Disable linting by default.
  call s:ALESetForBuffer(l:bufnr, 0)
  if !vimrc#IsBufferWithFile(l:buf_dict) ||
      \ a:filepath =~# g:autolint_paths_blacklist
    return
  endif
  function! s:ALESetForFile(file, value) abort
    let s:file_to_lint_enabled[a:file] = a:value
    for l:buf_dict in getbufinfo()
      if l:buf_dict['name'] is# a:file
        call s:ALESetForBuffer(l:buf_dict['bufnr'], a:value)
      endif
    endfor
  endfunction
  function! s:OnShouldEnableLint(jobid, exit_code, event_type) abort
    call assert_true(a:event_type is# 'exit')
  call vimrc#Log('exit code: %s', a:exit_code)
    let l:file = s:autolint_jobid_to_file[a:jobid]
    " If the autolint state was already determined, no need to continue.
    if has_key(s:file_to_lint_enabled, l:file)
      return
    endif
    call s:ALESetForFile(l:file, !a:exit_code)
  endfunction
  call vimrc#Log('cmd: %s', [s:AUTOLINT_CHECKER, a:filepath, 
        \ g:autolint_git_remotes_whitelist])
  let l:jobid = async#job#start([s:AUTOLINT_CHECKER, a:filepath, 
        \ g:autolint_git_remotes_whitelist], {
        \ 'stdout_buffered': 1,
        \ 'on_exit': function('s:OnShouldEnableLint'),
  \ })
  if l:jobid <= 0
    echoerr 'vimrc: failed running command'
  endif
  let s:autolint_jobid_to_file[l:jobid] = a:filepath
endfunction
augroup vimrc
  autocmd BufRead * call s:MaybeEnableLinting(expand('<afile>:p'))
augroup END

" Mnemonic: Toggle Auto Errors
nnoremap <Leader>tae <Cmd>call vimrc#ToggleOption('vimrc_enable_autolint')<CR>
" }}} ALE linter "

" Disable YCM diagnostics since we already get them from ALE.
let g:ycm_show_diagnostics_ui = 0
let g:ycm_enable_diagnostic_signs = 0
let g:ycm_enable_diagnostic_highlighting = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                   Snippets                                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-snippets depends on ultisnips
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'

" Using <Tab> conflicts with YouCompleteMe, so we remap snippet expansion.
let g:UltiSnipsExpandTrigger = '<C-K>'
" I was previously using Tab and Shift-Tab to navigate the snippet parameters,
" but the problem with that is that then I can't use them to navigate the auto
" completion suggestions while editing a parameter.
" let g:UltiSnipsJumpBackwardTrigger = '<S-Tab>'
" let g:UltiSnipsJumpForwardTrigger  = '<Tab>'
let g:UltiSnipsJumpBackwardTrigger = '<C-J>'
let g:UltiSnipsJumpForwardTrigger  = '<C-L>'

" Use single quotes in python snippets
let g:ultisnips_python_quoting_style = 'single'
" Use Google style docstrings
let g:ultisnips_python_style = 'google'

" Disable C-j in insert mode in case I'm trigger happy with the snippets
" bindings.
inoremap <C-J> <Nop>

function! s:ConfigSnippetFile() abort
  " Use spaces in snippet files. For some reason they use tabs by default.
  setlocal expandtab
  " Unmap the text objects defined by ultisnip, which slows down line movement
  " in visual mode.
  silent! xunmap <buffer> iS
  silent! xunmap <buffer> aS
endfunction


augroup vimrc
  " NOTE: filetype doesn't work for this autocmd, the ultisnips default seems to
  " override its changes.
  autocmd BufEnter *.snippets call s:ConfigSnippetFile()
augroup END

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                           Documentation generation                           "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Plug 'kkoomen/vim-doge', { 'on': ['DogeGenerate', 'DogeCreateDocStandard'] }
let g:doge_doc_standard_python = 'google'
let g:doge_enable_mappings = 0
" Mnemonic: Code Add Documentation
nnoremap <Leader>cad <Cmd>DogeGenerate<CR>
" Mnemonic: Code Generate Documentation
nnoremap <Leader>cgd <Cmd>DogeGenerate<CR>
" Note that these mappings are removed after all the todos in the documentation
" are removed, so they can still be used for other stuff.
let g:doge_mapping_comment_jump_forward = '<M-n>'
let g:doge_mapping_comment_jump_backward = '<M-p>'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                     Tags                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NOTE: I disabled gutentags for some time before 2020-06-10 because of an issue
" [1] which I can't reproduce now. I experimented with using vista to generate
" tags and keep them up to date.
" [1] https://github.com/ludovicchabant/vim-gutentags/issues/269
Plug 'ludovicchabant/vim-gutentags'
" Use the file name .tags instead of tags for the tag file so that it's hidden
" by default.
" NOTE: This only has an effect when not using gutentags, since gutentags uses
" g:gutentags_cache_dir to centralize the tags.
let &tags = '.tags'
" json is used for storing large data in some of my projects, so I disable tags
" generation for it.
let g:fzf_tags_command = printf('list-searched-files | grep -v ''\.json$'' | xargs --no-run-if-empty --delimiter=''\n'' ctags -f %s --languages=-json', &tags)

" Centralize all tags files in this directory to avoid polluting projects with
" tags files.
let g:gutentags_cache_dir = Concat(g:VIM_CACHE_DIR, '/tags')
" Resolves symlinks in paths in the tags file.
let g:gutentags_resolve_symlinks = 1
" When the project root is a VCS repo, only compute tags for files in the repo.
" Otherwise, gutentags will generate tags for every file under the project root,
" including generated files, which consumes too much resources.
" Also, disable project tags generation for json files which seem to generate an
" excessive number of tags.
let g:gutentags_file_list_command = {
    \ 'markers': {
        \ '.git': 'list-searched-files | grep -v ''\.json$''',
        \ '.hg': 'hg files',
        \ },
\ }
let g:gutentags_define_advanced_commands = 1
let g:gutentags_exclude_filetypes = ['json']

" function! s:fzf_generate_tags() abort
"   let l:files = systemlist('list-searched-files | grep -v ''\.json$''')
"   let l:files_arg = join(map(l:files, '"''" . v:val . "''"'), ' ')
"   call system(printf('ctags -f ''%s'' --languages=-json %s',
"         \ &tags, l:files_arg))
" endfunction
" let g:Fzf_tags_function = funcref('s:fzf_generate_tags')

let g:vista_ctags_project_opts = '--languages=-json'
let g:vista_ctags_cmd = { 'json': 'true' }

" As of 2020-05-15, I'm using vista for automatic tag generation as well, so I
" stopped lazy loading it.
" TODO: Verify gutentags and vista don't conflict.
Plug 'liuchengxu/vista.vim', { 'on': ['Vista', 'Vista!', 'Vista!!'] }
" Plug 'liuchengxu/vista.vim'

" NOTE: As of 2019-06-11, I switched to vista which has support for async tag
" fetching, looks more modern and maintained, and doesn't interfere with my
" keybindings (tagbar remaps i).
" Plug 'majutsushi/tagbar'
" let g:tagbar_type_go = {
"     \ 'ctagstype' : 'go',
"     \ 'kinds'     : [
"         \ 'p:package',
"         \ 'i:imports:1',
"         \ 'c:constants',
"         \ 'v:variables',
"         \ 't:types',
"         \ 'n:interfaces',
"         \ 'w:fields',
"         \ 'e:embedded',
"         \ 'm:methods',
"         \ 'r:constructor',
"         \ 'f:functions'
"     \ ],
"     \ 'sro' : '.',
"     \ 'kind2scope' : {
"         \ 't' : 'ctype',
"         \ 'n' : 'ntype'
"     \ },
"     \ 'scope2kind' : {
"         \ 'ctype' : 't',
"         \ 'ntype' : 'n'
"     \ },
"     \ 'ctagsbin'  : 'gotags',
"     \ 'ctagsargs' : '-sort -silent'
" \ }
"
" let g:tagbar_type_markdown = {
"   \ 'ctagstype' : 'markdown',
"   \ 'kinds' : [
"       \ 'h:headings',
"       \ 'l:links',
"       \ 'i:images'
"   \ ],
"   \ 'sort' : 0
" \ }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                     Git                                      "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:RunTerminalTrueColor(cmd) abort
  let l:cmd = printf('env COLORTERM=%s %s', $COLORTERM, a:cmd)
  exec 'terminal ' . l:cmd
  startinsert
endfunction

" Plug 'tpope/vim-git'
nnoremap <Leader>gc <Cmd>call <SID>RunTerminalTrueColor('git commit')<CR>
nnoremap <Leader>gcp <Cmd>call <SID>RunTerminalTrueColor('git commit && git push')<CR>

Plug 'jreybert/vimagit'
nnoremap <Leader>gm <Cmd>Magit<CR>
augroup vimrc
  autocmd User VimagitEnterCommit nested startinsert
augroup END

" NOTE: As of 2020-02-13, I'm experimenting with gina as a fugitive replacement
" because fugitive had some issues. I'm still loading the fugitive plugins for
" comparing it to Gina, but the keybindings are now disabled.
Plug 'tpope/vim-fugitive'
Plug 'shumphrey/fugitive-gitlab.vim'
Plug 'tpope/vim-rhubarb'
" " Git add file.
" nnoremap <Leader>gaf <Cmd>Gwrite<CR>
" " Interactive status
" nnoremap <Leader>gs <Cmd>Gstatus<CR>
" " nnoremap <Leader>gc <Cmd>Gcommit<CR>
" nnoremap <Leader>gd <Cmd>Gvdiff<CR>
" nnoremap <Leader>gl <Cmd>Gllog<CR>
" nnoremap <Leader>gb <Cmd>Gblame<CR>
" nnoremap <Leader>go <Cmd>Gbrowse<CR>
" nnoremap <Leader>gpu <Cmd>Git push<CR>
" nnoremap <Leader>gpl <Cmd>Git pull<CR>
" nnoremap <Leader>gco :<C-U>Git checkout<Space>
" nnoremap <Leader>gmv :<C-U>Gmove<Space>
" " Reset file using `git checkout --`. Can then use undo to get back the file
" " with the changes.
" nnoremap <Leader>grs <Cmd>Gread<CR>
" nnoremap <Leader>grm <Cmd>Gremove<CR>

Plug 'lambdalisue/gina.vim'
" editorconfig-vim recommends adding this so that it works well with fugitive
" plugin.
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'gina://.*']

function! s:GitRestoreFile() abort
  call system('git reset -- ' . shellescape(resolve(expand('%:p'))))
  call system('git checkout -- ' . shellescape(resolve(expand('%:p'))))
  silent edit!
endfunction

nnoremap <Leader>gaf <Cmd>update <Bar> exec 'Gina add ' . expand('%:p') <Bar> GitGutter<CR>
nnoremap <Leader>gs <Cmd>tabnew <Bar> Gina status<CR>
nnoremap <Leader>gd <Cmd>Gina compare<CR>
nnoremap <Leader>gl <Cmd>Gina log<CR>
nnoremap <Leader>gb <Cmd>Gina blame<CR>
" The colons at the end of `Gina browse` make it guess the file path as well.
nnoremap <Leader>go <Cmd>Gina browse :<CR>
xnoremap <Leader>go :Gina browse :<CR>
" Mnemonic: Git Yank Remote
nnoremap <Leader>gyr <Cmd>Gina browse --yank --exact :<CR>
xnoremap <Leader>gyr :Gina browse --yank --exact :<CR>
nnoremap <Leader>gpu <Cmd>Gina push<CR>
nnoremap <Leader>gpu <Cmd>Gina pull<CR>
nnoremap <Leader>gco :<C-U>Gina checkout<Space>
nnoremap <Leader>grs <Cmd>call <SID>GitRestoreFile()<CR>
nnoremap <Leader>grm <Cmd>exec 'Gina rm ' . expand('%:p') <Bar> bd<CR>
nnoremap <expr> <Leader>gmv ":\<C-U>" . 'Gina mv ' . expand('%:p') . ' '

Plug 'airblade/vim-gitgutter'
" Disable keymappings as they are currently unused and interfere with the
" helptags mapping.
let g:gitgutter_map_keys = 0
" Highlight the line numbers of changed lines (in addition to the sign).
let g:gitgutter_highlight_linenrs = 1

nmap [h <Plug>(GitGutterPrevHunk)
nmap ]h <Plug>(GitGutterNextHunk)
nmap <Leader>gh <Plug>(GitGutterPreviewHunk)
nmap <Leader>ghs <Plug>(GitGutterStageHunk)
xmap <Leader>ghs <Plug>(GitGutterStageHunk)
nmap <Leader>ghu <Plug>(GitGutterUndoHunk)
" The caddexpr is a workaround to the setqflist function not triggering
" the QuickFixCmdPost event.
nnoremap <silent> <Leader>ghl :<C-U>GitGutterQuickFix <Bar> caddexpr [] <Bar>
    \ execute 'autocmd BufWinEnter * ++once nested call feedkeys("\<lt>C-w>p", "n")' <Bar> copen <CR>

" Workaround for an issue where the hunks are updated very slowly in neovim in
" certain files (like ~/.bashrc). Seems to go away when disabling YCM, but I
" didn't have enough time to dig into it.
augroup vimrc
  autocmd TextChanged,InsertLeave * call gitgutter#process_buffer(bufnr(''), 0)
augroup END

Plug 'rhysd/committia.vim'
let g:committia_hooks = {}
function! g:committia_hooks.edit_open(info) abort
  " Only consider unrecognized words as spelling errors, but ignore
  " issues with capitalization, local words, and rare words.
  let g:SpellCheck_ConsideredErrorTypes = ['bad']
  highlight clear SpellCap
  call VimrcEnableSpellCheck(0)
  " If there's no commit message, set it to "updates". Note that git-config has
  " the `commit.template` setting that I can use to set the default commit, but
  " then if I don't edit it git will complain about it, whereas in this case it
  " won't.
  if a:info.vcs is# 'git' && getline(1) is# ''
      call setline(1, 'updates')
      " Without setting the file to modified, autosync won't save it, and git
      " will complain that the commit message is empty.
      set modified
      " startinsert
  end
  " Scroll the diff window from the commit message buffer, even in insert
  " mode.
  nmap <buffer> <C-D> <Plug>(committia-scroll-diff-down-half)
  imap <buffer> <C-D> <Plug>(committia-scroll-diff-down-half)
  nmap <buffer> <C-U> <Plug>(committia-scroll-diff-up-half)
  imap <buffer> <C-U> <Plug>(committia-scroll-diff-up-half)
endfunction

Plug 'rhysd/conflict-marker.vim'
let g:conflict_marker_enable_mappings = 0
nmap [x <Plug>(conflict-marker-prev-hunk)
nmap ]x <Plug>(conflict-marker-next-hunk)

" TODO: This doesn't highlight the searches.
function! s:SearchConflictMarkers() abort
  let @/ = '\v^(\<|\=|\>|\|){5,}'
  silent! normal! n
endfunction

nnoremap <silent> <Leader>sx <Cmd>call <SID>SearchConflictMarkers()<CR>

" [[B]Commits] Customize the options used by 'git log':
let g:fzf_commits_log_options = '--color=always --pretty=myshort'

" fzf-gitignore is neovim only
if has('nvim')
  Plug 'fszymanski/fzf-gitignore'
  let g:fzf_gitignore_no_maps = 1

  " We override the command as a workaround for a strange issue where the first
  " time the fetching command is called it's returning v:null.
  function! s:FzfGitignoreWrapper() abort
    " It seems that remote plugin functions are autoloaded, so we can't use
    " `exists` to check if they exist. Instead, we call the function, which we
    " need to do anyway to work around the main issue, and call
    " `UpdateRemotePlugins`, which is slow, only if it fails.
    try
      call _fzf_gitignore_get_all_templates()
    catch /E117/
      UpdateRemotePlugins
      call _fzf_gitignore_get_all_templates()
    endtry
    call fzf_gitignore#run()
  endfunction
  augroup vimrc
    autocmd VimEnter * command! FzfGitignore call <SID>FzfGitignoreWrapper()
  augroup END
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                   Python                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" As of 2018-11-13, python-mode is causing major slowness in undo/redo so I'm
" disabling it. In addition, it includes plugins that I don't use like
" autopep8 (I use yapf).
" Therefore, I'm adding individual python plugins below.
" Plug 'klen/python-mode'
" Disable rope from pymode, which seems to conflict with jedi.
let g:pymode_rope = 0
" Disable pymode motion commands.
let g:pymode_motion = 0
" Disable lint checks (I already use ALE).
let g:pymode_lint = 0
" let g:pymode_rope_goto_definition_bind = '<C-]>'
let g:pymode_run_bind = '<Leader>R'
let g:pymode_doc_bind = '<Leader>H'

Plug 'davidhalter/jedi-vim'
" Disable jedi omnicompletion (already set by YouCompleteMe), default
" keybindings, and showing call signatures.
let g:jedi#auto_initialization = 0
" Without this call signatures don't work for me.
let g:jedi#show_call_signatures_delay = 0
" Keybindings the are defined in YouCompleteMe are commented out.
" let g:jedi#goto_command = '<Leader>co'
" let g:jedi#documentation_command = '<Leader>ch'
" let g:jedi#rename_command = '<Leader>cr'
nnoremap <Leader>cr <Cmd>echoerr 'vimrc: no renaming support'<CR>
augroup vimrc
  autocmd FileType python nnoremap <buffer> <Leader>cr <Cmd>call jedi#rename()<CR>
  " jedi's goto command has better semantics than YCM when using it on an
  " imported function. For example, in the following code:
  "
  " 1. from foo import bar
  " 2. bar()
  "
  " When using goto on bar in line 2, YCM goes to the import statement in line 1
  " instead of bar's implementation.
  "
  " Note however that the jedi#goto command is not async so a goto call can
  " freeze the editor. It seems to be async in YCM as well, however YCM seems
  " more responsive, possibly because it uses a timeout.
  autocmd FileType python nnoremap <buffer> <Leader>co <Cmd>call jedi#goto()<CR>
  autocmd FileType python ++once call jedi#configure_call_signatures()
augroup END

" NOTE: As of 2020-02-20, I'm using vim-codefmt and ale which support yapf, so I
" don't think I need this plugin.
" Plug 'mindriot101/vim-yapf'
let g:ale_linters = get(g:, 'ale_linters', {})
let g:ale_linters['python'] = ['pylint']
let g:ale_fixers = get(g:, 'ale_fixers', {})
let g:ale_fixers['python'] = ['isort', 'yapf']

Plug 'jpalardy/vim-slime'
let g:slime_target = 'tmux'
let g:slime_paste_file = Concat(g:VIM_DATA_DIR, '/slime_paste')
" By default use the other pane as the slime REPL.
let g:slime_python_ipython = 1
if vimrc#base#IsInsideTmux()
  let g:slime_default_config =
      \ {'socket_name': split($TMUX, ',')[0], 'target_pane': ':.2'}
endif

" ivanov/vim-ipython looks unmaintained with the last activity on 2015-06-24. I
" tried some of its forks but they didn't work.
" Plug 'ivanov/vim-ipython'
" Plug 'wilywampa/vim-ipython'

" https://blogs.aalto.fi/marijn/2017/11/13/integrating-vim-and-jupyter-qtconsole/
if exists(':pythonx')
  " This is required for jupyter-vim to work in vim (neovim works without it).
  set pyxversion=3
  Plug 'jupyter-vim/jupyter-vim', { 'on': ['JupyterConnect'] }
  let g:jupyter_mapkeys = 0
endif

Plug 'goerz/jupytext.vim'
let g:jupytext_fmt = 'py:percent'

function! s:SetJupytextSettings() abort
  " There are often many linting errors in notebooks because of wildcard imports
  " and other stuff, so we disable linting by default as well.
  let b:ale_enabled = 0
  if exists(':ALEResetBuffer')
    ALEResetBuffer
  endif
  " TODO: Support a count.
  nnoremap <buffer> zi <Cmd>call search('# %%', 'Wseb')<CR>
  nnoremap <buffer> zk <Cmd>call search('# %%', 'Wse')<CR>
endfunction

function! s:MaybeSetJupytextSettings() abort
  if search('jupytext_version:', 'n')
    call <SID>SetJupytextSettings()
  endif
endfunction

function! s:OnJupytextVimConversion() abort
  " Notebooks are often very large because of their output, so YouCompleteMe may
  " disable itself. However, since we use jupytext, the actual content read into
  " the buffer will be much smaller, so we disable YCM's handling of large
  " files.
  let b:ycm_largefile = 0
  " GitGutter seems to think that the whole buffer is changed (probably because
  " it compares it to the ipynb file contents in the repo).
  call gitgutter#buffer_disable()
  call s:SetJupytextSettings()
endfunction

augroup vimrc
  autocmd BufReadPre,BufEnter *.ipynb call <SID>OnJupytextVimConversion()
  autocmd BufReadPost *.py call <SID>MaybeSetJupytextSettings()
augroup END

" Hack for reducing false positives in pylint that are created because the
" pylint doesn't seem to get the value of PYTHONPATH that is exported to vim.
if empty($PYTHONPATH)
  let $PYTHONPATH = '.'
endif
let g:ale_python_pylint_options = Concat(
    \ "--init-hook 'import sys; sys.path += [\"", $PYTHONPATH, "\"]'")
let g:ale_python_pylint_change_directory = 0

" Set VIRTUALENV from CONDA_PREFIX so that jedi-vim completions will work in the
" conda environment. See also: https://github.com/davidhalter/jedi-vim/issues/907#issuecomment-462209633
if empty($VIRTUAL_ENV)
  if !empty($CONDA_PREFIX)
    let $VIRTUAL_ENV = $CONDA_PREFIX
  else
    let $VIRTUAL_ENV = Concat($HOME, '/.local/pkg/conda')
  endif
endif

" Neovim recommends setting g:python3_host_prog so that the pynvim module is
" always available, regardless of the currently active virtual environment.
if has('nvim')
  if executable('/usr/bin/python3')
    let g:python3_host_prog = '/usr/bin/python3'
  elseif executable('/bin/python3')
    let g:python3_host_prog = '/bin/python3'
  endif
else
  " NOTE: As of 2020-02-15, this is needed so that YouCompleteMe works with
  " regular vim.
  " When python is dynamically compiled, regular vim can load either python 2 or
  " python 3, but not both. It seems that some plugin is loading python 2, which
  " causes an error message from YouCompleteMe when it tries to use python 3.
  " Using has('python3') loads python 3. See also `:help python-2-and-3` in
  " regular vim.
  call has('python3')
endif

augroup vimrc
  " Files that I edit inside IPython files usually reference interactive
  " variables, so there will be many errors.
  autocmd BufReadPost,BufNewFile ipython_edit*.py let b:ale_enabled = 0
augroup END

Plug 'raimon49/requirements.txt.vim', {'for': 'requirements'}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                    Golang                                    "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NOTE: vim-go must be added to vim-plug before vim-polyglot. See also:
" https://github.com/sheerun/vim-polyglot/issues/309
Plug 'fatih/vim-go'
let g:go_textobj_enabled = 0
let g:go_doc_keywordprg_enabled = 0
let g:go_def_mapping_enabled = 0
" Don't run anything on save by default, since combined with autosync, this can
" cause the buffer to change while I'm in the middle of editing.
let g:go_fmt_autosave = 0
let g:go_imports_autosave = 0
let g:go_mod_fmt_autosave = 0
let g:go_asmfmt_autosave = 0
let g:go_metalinter_autosave = 0

let g:ale_linters = get(g:, 'ale_linters', {})
" Add gopls as well? seems it's already started by both vim-go and YCM.
let g:ale_linters['go'] = ['gofmt', 'golint', 'govet', 'gobuild']

let g:ale_fixers = get(g:, 'ale_fixers', {})
let g:ale_fixers['go'] = ['goimports', 'gofmt']

" augroup vimrc
"   " This configures vim-codefmt to use goimports instead of gofmt, which both
"   " formats the code and fixes imports. However, this command must be run after
"   " glaive is initialized.
"   autocmd FileType go ++once Glaive codefmt gofmt_executable='goimports'
" augroup END

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                               Shell scripting                                "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Recognize variables that are commonly used in my shell scripts.
let $REPO_ROOT = g:REPO_ROOT
let $SUBMODULES_DIR = Concat(g:REPO_ROOT, '/submodules')
let $BASH_CONFIG_DIR = Concat(g:REPO_ROOT, '/.config/bash')
let $XDG_CONFIG_HOME = get(environ(), 'XDG_CONFIG_HOME',
      \ Concat($HOME, '/.config'))
augroup vimrc
  autocmd BufEnter * let $DIR = expand('%:h')
augroup END

" ALE has issues with bash scripts that don't have a shebang line, which I'm
" using for "libraries" that should be only sourced and not executed directly,
" so this function tries to fix it.
function! s:FixALEForBashLibraries() abort
  " TODO: Remove setting b:ale_sh_shellcheck_dialect and use `# shellcheck
  " shell=bash` instead in any non-executable scripts once the ALE PR is merged
  " and released: https://github.com/dense-analysis/ale/pull/3216
  let b:ale_sh_shellcheck_dialect = 'bash'
  " ALE assumes the shell is sh without a shebang line, which will cause an
  " error with the "shell" linter.
  let b:ale_linters_ignore = ['shell']
endfunction

let g:ale_fixers = get(g:, 'ale_fixers', {})
let g:ale_fixers['sh'] = ['shfmt']
let g:ale_sh_shfmt_options = '-i 2 -sr -ci'
augroup vimrc
  autocmd BufReadPost,BufNewFile 
      \ .envrc,*/.config/bash/*.sh,*/.my_scripts/lib/*.sh,*/install/aconfmgr/**
      \ call <SID>FixALEForBashLibraries()
augroup END

let g:ycm_language_server = get(g:, 'ycm_language_server', [])
let g:ycm_language_server += [
    \ {
    \   'name': 'bash',
    \   'cmdline': ['bash-language-server', 'start'],
    \   'filetypes': ['sh', 'bash'],
    \ },
\ ]

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                 web: Javascript, Typescript, HTML, CSS, JSON                 "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NOTE: I used to have separate plugins for every language before switching to
" vim-polyglot. They're kept here for documentation, and will be removed if I
" end up staying with vim-polygot.

" Plug 'hail2u/vim-css3-syntax'
" Plug 'infokiller/Vim-Jinja2-Syntax'
" " Both leafgarland/typescript-vim and HerringtonDarkholme/yats.vim provide
" " syntax highlighting for typescript (yats also has stuff like UltiSnips
" " snippets), but yats was painfully slow when converting web-search-navigator
" " to typescript, so I'm switched to typescript-vim for now.
" Plug 'leafgarland/typescript-vim'
" " Plug 'HerringtonDarkholme/yats.vim'
" Plug 'othree/html5.vim'
" Plug 'pangloss/vim-javascript'

" Adds a jsonc filetype that supports comments.
" Another alternative: https://github.com/neoclide/jsonc.vim
Plug 'kevinoid/vim-jsonc'
" Plug 'elzr/vim-json'

augroup vimrc
  autocmd FileType javascript,typescript let b:codefmt_formatter = 'prettier'
augroup END

let g:ale_fixers = get(g:, 'ale_fixers', {})
" NOTE: prettier-eslint doesn't work:
" https://github.com/prettier/prettier-eslint-cli/issues/208
let g:ale_fixers['javascript'] = ['prettier', 'eslint']
let g:ale_fixers['typescript'] = ['prettier', 'eslint']
let g:ale_fixers['css'] = ['stylelint']
let g:ale_fixers['json'] = ['prettier']
let g:ale_fixers['jsonc'] = ['prettier']

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                   Markdown                                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ale_fixers = get(g:, 'ale_fixers', {})
let g:ale_fixers['markdown'] = ['prettier']

" Plug 'suan/vim-instant-markdown'
let g:instant_markdown_autostart = 0
" Plug 'shime/vim-livedown'
Plug 'iamcco/markdown-preview.nvim'
let g:mkdp_auto_start = 0
let g:mkdp_auto_close = 0

" Async.vim is used for checking that the npm binary that markdown-preview
" requires is installed.
Plug 'prabirshrestha/async.vim'
let s:did_check_markdown_preview = 0

function! s:CheckMarkdownPreviewInstalled() abort
  if s:did_check_markdown_preview
    return
  endif
  let s:did_check_markdown_preview = 1
  let l:dir = Concat(g:plugs['markdown-preview.nvim']['dir'], '/app')
  function! s:OnYarnEvent(jobid, data, event_type) abort
    if a:event_type is# 'stderr'
      let s:yarn_stderr = a:data
      " It seems that echoerr doesn't work with newlines, so we print it in a
      " loop.
      for l:line in a:data
        if !empty(l:line)
          " NOTE: As of 2019-12-15, yarn outputs a warning about "Invalid bin
          " entry" but everything seems to work, so this is disabled.
          " call vimrc#Error(l:line)
        endif
      endfor
    elseif a:event_type is# 'exit' && a:data != 0
      " stderr may not be available at this point, so we print it
      " separately.
      echoerr printf('Installing markdown preview exited with error')
    endif
  endfunction
  let l:jobid = async#job#start(['yarn', 'install'], {
        \ 'cwd': l:dir,
        \ 'stderr_buffered': 1,
        \ 'on_stderr': function('s:OnYarnEvent'),
        \ 'on_exit': function('s:OnYarnEvent'),
  \ })
  if l:jobid <= 0
    echoerr 'Could not execute markdown preview installation'
  endif
endfunction

augroup vimrc
  autocmd FileType ++once markdown call <SID>CheckMarkdownPreviewInstalled()
augroup END

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                    Latex                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" When a file has the tex extension, vim won't necessarily set filetype to tex,
" unless this option is set. See: https://superuser.com/q/208177/407543
let g:tex_flavor = 'latex'
let g:tex_conceal = 'abdgm'

Plug 'lervag/vimtex'
let g:vimtex_mappings_enabled = 0
let g:vimtex_view_method = 'zathura'
" Zathura is firejailed which causes vimtex to think it's not compiled with
" libsynctex, although it is (at least on archlinux).
let g:vimtex_view_zathura_check_libsynctex = 0
" Don't open the quickfix window automatically if the compilation had errors or
" warnings.
let g:ycm_semantic_triggers = get(g:, 'ycm_semantic_triggers', {})
augroup vimrc
  " NOTE: g:vimtex#re#youcompleteme will be autoloaded on first access
  autocmd VimEnter * let g:ycm_semantic_triggers['tex'] = g:vimtex#re#youcompleteme
augroup END

Plug 'KeitaNakamura/tex-conceal.vim', {'for': 'tex'}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                            Misc language settings                            "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" See https://github.com/sheerun/vim-polyglot/issues/162
let g:jsx_ext_required = 1
let g:no_csv_maps = 1
" Syntax, indentation, and other basic language support for many languages.
Plug 'sheerun/vim-polyglot'
let g:polyglot_disabled = ['go', 'jsonc']

Plug 'jamessan/vim-gnupg'

Plug 'hjson/vim-hjson'

" Use https://github.com/hadolint/hadolint either locally or via docker.
let g:ale_dockerfile_hadolint_use_docker = 'yes'

let g:ale_fixers = get(g:, 'ale_fixers', {})
let g:ale_fixers['bzl'] = ['buildifier']

Plug 'dhruvasagar/vim-table-mode', { 'on': ['Tableize', 'TableModeRealign'] }
let g:table_mode_disable_mappings = 1
let g:table_mode_delimiter = '|'
nnoremap <Leader>ctt <Cmd>Tableize<CR>
xnoremap <Leader>ctt :Tableize<CR>
nnoremap <Leader>cta <Cmd>TableModeRealign<CR>

" Plug 'Matt-Deacalion/vim-systemd-syntax'
" chrisbra/csv.vim is included in polyglot
" " Plug 'chrisbra/csv.vim'
" Plug 'uarun/vim-protobuf'
