" Helper used by functions below to accept either a single string or the same
" arguments as printf.
function! s:FormatMessage(message_or_format, extra_args) abort
  if empty(a:extra_args)
    return a:message_or_format
  endif
  return call('printf', [a:message_or_format] + a:extra_args)
endfunction

function! vimrc#Warning(message_or_format, ...) abort
  echohl WarningMsg
  echomsg s:FormatMessage(a:message_or_format, a:000)
  echohl None
endfunction

function! vimrc#Error(message_or_format, ...) abort
  echohl ErrorMsg
  echomsg s:FormatMessage(a:message_or_format, a:000)
  echohl None
endfunction

let g:vimrc_enable_logging = get(g:, 'vimrc_enable_logging', 
      \ get(environ(), 'VIMRC_DEBUG', 0))
let s:LOG_FILE = expand('~/tmp/vimrc.log')
silent! call mkdir(fnamemodify(s:LOG_FILE, ':h'), 'p')

" If it's a single argument, write it as is. Otherwise, use printf.
function! vimrc#Log(message_or_format, ...) abort
  if !g:vimrc_enable_logging
    return
  endif
  let l:message = s:FormatMessage(a:message_or_format, a:000)
  let l:dt = execute('pythonx import datetime; 
        \ print(datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f"))')
  " If this function was not called from an autocmd, <sfile> will expand into
  " the format: 'function {name}[{lnum}]..vimrc#Log'.
  " If the function is script local, the name will also be prefixed with
  " '<SNR>[0-9]*_'.
  let l:context = expand('<sfile>')
  if l:context =~# '\v\Cfunction (.+)\.\.vimrc#Log$'
    let l:matches = matchlist(l:context, 
          \ '\v\Cfunction (.*\.\.)?(\<SNR\>\d*_)?(.+)\.\.vimrc#Log$')
    let l:context = empty(l:matches[2]) ? '' : 's:'
    let l:context = l:context . l:matches[3]
  elseif !empty(expand('<amatch>'))
    let l:amatch = expand('<amatch>')
    let l:afile = expand('<afile>')
    let l:context = 'autocmd: ' . l:amatch
    if l:afile isnot# l:amatch
     let l:context = printf('%s (%s)', l:context, fnamemodify(l:afile, ':~:.'))
    endif
  else
    let l:context = 'unknown'
  endif
  call writefile([printf('[%s] %s: %s', l:dt, l:context, l:message)], 
      \ s:LOG_FILE, 'a')
endfunction

function! vimrc#ToggleOption(name, ...) abort
  let l:default = a:0 > 0 ? a:1 : 1
  let l:new_value = l:default
  if exists(a:name)
    let l:new_value = !eval(a:name)
  endif
  call vimrc#Log('Name: %s, new value: %s', a:name, l:new_value)
  exec printf('let %s = %s', a:name, l:new_value)
endfunction

function! vimrc#GetCommandForMode(cmd) abort
  let l:mode = mode()
  let l:normal_cmd = ':'.a:cmd."\<cr>"
  if l:mode is# 'n'
    return l:normal_cmd
  endif
  if l:mode is# 'v' || l:mode is# 'V' || l:mode is# "\<C-v>" || l:mode is# 's'
    let l:cmd = "\<Esc>".l:normal_cmd.'gv'
    if l:mode is# 's'
      let l:cmd .= "\<C-g>"
    endif
    " Escape single quotes in the command so that wrapping it with single quotes
    " yields a valid string.
    let l:escaped_cmd = substitute(l:cmd, "'", "''", 'g')
    " Without feedkeys with the 't' mode, the `gv` command is not executed at
    " the end.
    call feedkeys("\<Esc>".l:cmd, 'nt')
    return ''
  endif
  if l:mode is# 'i' || l:mode is# 's'
    return "\<C-o>".l:normal_cmd
  endif
  if l:mode is# 'c' && (getcmdtype() is# ':' || getcmdtype() is# '/' || getcmdtype() is# '?')
    let l:cmd = "\<C-c>" . l:normal_cmd . getcmdtype()
    if !empty(getcmdline())
      let l:cmd .= "\<Up>"
    endif
    return l:cmd
  endif
  echoerr 'Mode not implemented: ' . l:mode
endfunction

" Example usage from a shell:
" > vim -c ':call vimrc#ListBuiltinKeybindingsWithKey("i")'
function! vimrc#ListBuiltinKeybindingsWithKey(key) abort
  " Generate all help tags for loaded plugins.
  call plug#helptags()
  " Search all tags with the key with up to 3 chars before or after it.
  exec printf('helpgrep \V\c*\.\{0,3}%s\.\{0,3}*', escape(tolower(a:key), '/\\'))
  if empty(getqflist())
    return
  endif
  close
  copen
  " Filter tags with 5 or more chars.
  Reject \v\*[^\*]{5,}\*
  " Filter irrelevant tags.
  Reject \v\*(E\d+|\%?:[^\*]+|grep|\+\w{3,}|User|home|end|q_in|cvim|API|xim|sfile|nvi|-.|-vim|\$VIM|'vi'|UI|TUI|GUI|\*[^\*]*\*| vim\\d|Q_..|/inc|book|ACL|DOS|OS2|yank|case|suda|ale|\<(A|D)-|META|Tab|Lua|bars|Mark|s/\\.|less|\<lt\>|,mb:|sub\\s|\+xim)\*
  " Filter tags from irrelevant help files.
  Reject \v(pi_zip|pi_gzip|pi_netrw|pattern|options|eval|deprecated|recoverplugin|vim-slime|uganda|arabic|message|if_pyth|mbyte|tips|autocmd|usr_\d*|if_lua|if_ruby|ft_rust|todo|starting|os_unix|os_qnx|os_vms|gui_x11|version\d).txt
  Reject \vefm=
endfunction

function! vimrc#UpdateDisplayFromTmux() abort
  if !vimrc#base#IsInsideTmux()
    return
  endif
  let l:display = trim(system('tmux show-environment DISPLAY'))
  if v:shell_error != 0
    echoerr 'Failed setting DISPLAY from tmux'
    return
  endif
  " Output should start with "DISPLAY=", we verify it and use the value to set
  " DISPLAY inside vim.
  let l:prefix = 'DISPLAY='
  if !maktaba#string#StartsWith(l:display, l:prefix)
    echoerr printf('Got unexpected output from tmux: %s', l:display)
    return
  endif
  let $DISPLAY = l:display[strlen(l:prefix):]
endfunction

" Getting a buffer given a filename (for example using `setbufvar`) requires
" providing a pattern, which means that if we want an exact match we have to
" deal with escaping. Hence this function iterates over all buffers and compares
" their names.
function! vimrc#PathToBufDict(filepath) abort
  for l:buf_dict in getbufinfo()
    if l:buf_dict['name'] is# a:filepath
      return l:buf_dict
    endif
  endfor
  return -1
endfunction

let s:BUFFER_TYPES_WITH_FILES = ['', 'nowrite', 'acwrite', 'help']
let s:REMOTE_FILES_PROTOCOLS =
      \ ['dav', 'fetch', 'ftp', 'http', 'rcp', 'rsync', 'scp', 'sftp']

function! vimrc#IsBufferWithFile(buf_dict) abort
  let l:buftype = getbufvar(a:buf_dict['bufnr'], '&buftype')
  call vimrc#Log('Buffer name: %s, type: %s', a:buf_dict['name'], l:buftype)
  if a:buf_dict['name'] =~# '\v\C^(gina)://'
    return 0
  endif
  return index(s:BUFFER_TYPES_WITH_FILES, l:buftype) >= 0 &&
      \ !empty(a:buf_dict['name'])
endfunction

function! vimrc#IsRemoteFile(filename) abort
  if empty(a:filename)
    return 0
  endif
  let l:protocol = split(a:filename, '://')[0]
  return index(s:REMOTE_FILES_PROTOCOLS, l:protocol) >= 0
endfunction

function! vimrc#IsBufferWithLocalFile(buf_dict) abort
  return vimrc#IsBufferWithFile(a:buf_dict) && !vimrc#IsRemoteFile(a:buf_dict['name'])
endfunction

function! vimrc#EditCmdline() abort
  let l:cmdtype = getcmdtype()
  if l:cmdtype is# ':'
    " Double quotes are required for this to work.
    return "\<C-F>"
  elseif l:cmdtype is# '/' || l:cmdtype is# '?'
    let l:cmdline = getcmdline()
    let l:cmdpos = getcmdpos()
    " NOTE: <C-C> must be used to exit command line mode - <Esc> only works if
    " typed interactively be the user. See also:
    " https://github.com/neovim/neovim/issues/11041
    " Note that <C-C> also adds the command to the history, so there's no need
    " to type it ourselves.
    let l:setpos_cmd = Concat(':call setpos(".", [0, getpos(".")[1], ',
        \ l:cmdpos, ', 0])', "\<CR>")
    return Concat("\<C-C>q/\<Up>", l:setpos_cmd)
  endif
endfunction

" Open files in their last edit location. See also:
" - :help last-position-jump
" - https://github.com/mhinz/vim-galore#restore-cursor-position-when-opening-file
" - http://vim.wikia.com/wiki/Restore_cursor_to_file_position_in_previous_editing_session
function! vimrc#SetPreviousPosition() abort
  " Don't set the previous position in diff mode, because it often moves the
  " cursor to a line that is folded at the end of the file and can make it seem
  " like there's no diff in the initial view.
  if &diff
    return
  endif
  let l:prev_pos = getpos("'\"")
  let l:prev_line = l:prev_pos[1]
  let l:prev_col = l:prev_pos[2]
  if l:prev_line <= line('$') && l:prev_col <= col([l:prev_line, '$'])
      \ && (l:prev_line > 1 || l:prev_col > 1)
    call setpos('.', l:prev_pos)
    normal! zv
  endif
endfunction

" navigation and editing.
" Put ex commands (internal vim commands) output in a new buffer for easy
" You can use prefix modifiers such as (`:rightbelow`, `:tab`, and `:topleft`)
" to specify how to open the output.
" Based on: http://vim.wikia.com/wiki/Capture_ex_command_output
function! vimrc#EditExOutput(cmd, mods) abort
  let l:mods = a:mods
  if empty(l:mods)
    let l:mods = 'vertical'
  endif
  let l:message = ''
  redir =>> l:message
  silent execute a:cmd
  redir END
  if empty(l:message)
    echoerr 'no output'
  else
    execute l:mods . ' new'
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nomodified
    silent put=l:message
  endif
endfunction
