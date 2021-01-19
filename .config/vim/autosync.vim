" When a file has been detected to have been changed outside of Vim and it has
" not been changed inside of Vim, automatically read it again, without
" bothering me.
" References:
" - https://github.com/djoshea/vim-autoread
set autoread
" Save the buffer if it's modified after using various commands (switching
" buffers, quit, exit, etc.)
set autowrite autowriteall

let g:vimrc_autowrite_buffers = 1
" Minimum duration in milliseconds between consecutive buffer/file syncs.
let g:vimrc_autosync_interval = 3000

function! s:SyncBuffer(buf_dict, force) abort
  " call vimrc#Log('Syncing buffer: %s', a:buf_dict.name)
  " We only care buffers that have an associated local file.
  if !vimrc#IsBufferWithFile(a:buf_dict)
    return
  endif
  if !a:force && !vimrc#IsRemoteFile(a:buf_dict['name'])
    return
  endif
  " Create the directories leading to the file path if they don't exist yet.
  call vimrc#Log('Creating dir: %s', a:buf_dict['name'])
  silent! call mkdir(fnamemodify(a:buf_dict['name'], ':h'), 'p', 0700)
  " Reload buffer from file.
  " echom printf('Reading buffer from disk: %s', a:buf_dict.name)
  " `checktime` checks for changes to file one time after `updatetime`
  " milliseconds of inactivity in normal mode. Without this, autoread doesn't
  " work well, because vim only uses it after invoking an external command. See: 
  " - autocmd FocusGained echo 'focus gained'
  " - http://stackoverflow.com/a/18866818
  " I don't remember why `silent` is needed here, but at the very least it seems
  " needed to prevent errors from appearing when it's invoked in command line
  " mode: https://vi.stackexchange.com/q/13692
  exec printf('silent! checktime %d', a:buf_dict['bufnr'])
  " NOTE: As of 2020-02-09, I disabled writing the buffers to disk in this
  " function because the vim commands `:write` and `:update` seem to only work
  " on the focused buffer. Instead, I'm using `:wall` to write all buffers.
  " Auto write is enabled only for buffer types where it makes sense.
  " Note that it's also disabled for the quickfix and loclist, since they can
  " contain changes that are applied to multiple files (see quickfix-reflector
  " plugin).
  " let l:buftype = getbufvar(a:buf_dict['bufnr'], '&buftype')
  " let l:readonly = getbufvar(a:buf_dict.bufnr, '&readonly')
  " if g:vimrc_autowrite_buffers && !l:readonly && strlen(a:buf_dict.name) &&
  "     \ index(['', 'acwrite', 'help'], l:buftype) >= 0 &&
  "     \ match(a:buf_dict.name, '^suda://') == -1
  "   " I tried to use `w` instead of `wa`, but then if I edit the same files in
  "   " two vim instances I get warnings like "the file has been changed since
  "   " reading it!!!"
  "   exec printf('silent! update! %s', a:buf_dict.name)
  " endif
endfunction

function! s:SyncAllBuffers(force) abort
  let l:has_remote_buffers = 0
  for l:buf_dict in getbufinfo({'bufloaded': 1})
    if vimrc#IsRemoteFile(l:buf_dict['name'])
      let l:has_remote_buffers = 1
      continue
    endif
    let l:buftype = getbufvar(l:buf_dict['bufnr'], '&buftype')
    " if l:buftype is# 'quickfix' && l:buf_dict['changed']
    "   let l:has_modified_quickfix = 1
    "   continue
    " endif
    if l:buf_dict['listed']
      call s:SyncBuffer(l:buf_dict, a:force)
    endif
  endfor
  if a:force || (g:vimrc_autowrite_buffers && !l:has_remote_buffers)
    silent! wall
  endif
endfunction

" The goal of this function is to throttle the excessive autosaving caused by
" the `TextChanged` and `TextChangedI` events, and by the `CursorHold` and
" `CursorHoldI` events when `updatetime` is low. However, it doesn't
" text.
let s:autosync_timer_active = v:false
" NOTE(infokiller): this function can't be script local because it's passed to
" `timer_start`.
function! SyncAllBuffersThrottled(...) abort
  " If we got an argument, it means we were called from timer_start.
  if a:0 == 1
    call vimrc#Log('Called from timer')
    let s:last_sync_time = reltime()
    call s:SyncAllBuffers(0)
    let s:autosync_timer_active = v:false
    return
  endif
  if s:autosync_timer_active == v:true
    call vimrc#Log('autosync timer active, bailing out')
    return
  endif
  let l:now = reltime()
  if !exists('s:last_sync_time')
    call vimrc#Log('Called for the first time')
    let s:last_sync_time = l:now
  endif
  let l:ms_before_next_sync = float2nr(
        \ 1000.0 * reltimefloat(reltime(l:now, s:last_sync_time)) +
        \ g:vimrc_autosync_interval)
  call vimrc#Log('l:ms_before_next_sync = ' . l:ms_before_next_sync)
  if l:ms_before_next_sync <= 0
    let s:last_sync_time = l:now
    call s:SyncAllBuffers(0)
  else
    let s:autosync_timer_active = v:true
    call timer_start(l:ms_before_next_sync, 'SyncAllBuffersThrottled')
  endif
endfunction

" TODO: Add an option to do more frequent saves using timer_start [1] or more
" events (like CursorHold, CursorHoldI, CursorMoved, CursorMovedI).
" [1] https://stackoverflow.com/a/53860166/1014208
" TODO: Consider using vim-autoread [2]
" [2] https://github.com/chrisbra/vim-autoread
augroup vimrc
  " Notes:
  " - Originally this also had the InsertLeave event, but it triggers a bug with
  "   vim-operator-surround where the undo doesn't work correctly.
  " - Originally this also had the CursorHold and CursorHoldI events, but they
  "   don't seem necessary if I use TextChanged and TextChangedI.
  " - When FocusLost is triggered because of moving to a new buffer,
  "   SyncBuffer will see the new buffer as the "current" buffer. Therefore, we
  "   can't just save the current buffer in this case, because we won't save the
  "   previously focused buffer if it had changes.
  autocmd FocusLost,FocusGained,BufLeave,WinLeave * nested call <SID>SyncAllBuffers(0)
  autocmd QuitPre * nested call <SID>SyncAllBuffers(1)
  " autocmd CursorHold,CursorHoldI * nested call <SID>SyncAllBuffers(0)
  autocmd TextChanged,TextChangedI * nested call SyncAllBuffersThrottled()
augroup END

function! s:ToggleAutosave() abort
  if g:vimrc_autowrite_buffers
    let g:vimrc_autowrite_buffers = 0
    set noautowrite noautowriteall
  else
    let g:vimrc_autowrite_buffers = 1
    set autowrite autowriteall
  endif
endfunction

nnoremap <Leader>tas <Cmd>call <SID>ToggleAutosave()<CR>
