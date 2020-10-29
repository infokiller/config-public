" Functions in this file should not depend on anything else and are expected to
" be used directly in my vim config (i.e. autoloading will always be done), so
" this file should be kept minimal.

function! vimrc#base#IsInsideTmux() abort
  if exists('s:IS_INSIDE_TMUX')
    return s:IS_INSIDE_TMUX
  endif
  let s:IS_INSIDE_TMUX = exists('$TMUX')
  return s:IS_INSIDE_TMUX
endfunction

function! vimrc#base#IsInsideSSH() abort
  return !empty($SSH_CLIENT) || !empty($SSH_TTY) || !empty($SSH_CONNECTION)
endfunction

" Open files in their last edit location. See also:
" - :help last-position-jump
" - https://github.com/mhinz/vim-galore#restore-cursor-position-when-opening-file
" - http://vim.wikia.com/wiki/Restore_cursor_to_file_position_in_previous_editing_session
function! vimrc#base#SetPreviousPosition() abort
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
