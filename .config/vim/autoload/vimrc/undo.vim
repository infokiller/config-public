" Like `repeat#wrap` but enables feeding keys with remappings so that `<Plug>`
" mappings can be used.  This is needed to combine vim-repeat and
" vim-highlightedundo.
function! vimrc#undo#RepeatWrap(command, count, feedkeys_mode) abort
  let l:preserve = (g:repeat_tick == b:changedtick)
  call feedkeys((a:count ? a:count : '').a:command, a:feedkeys_mode)
  execute (&foldopen =~# 'undo\|all' ? 'norm! zv' : '')
  if l:preserve
    let g:repeat_tick = b:changedtick
  endif
endfunction

function! vimrc#undo#ShouldUseSimpleUndo() abort
  if exists('s:should_use_simple_undo')
    return s:should_use_simple_undo
  endif
  if g:VSCODE_MODE
    let s:should_use_simple_undo = 1
  else
    let s:should_use_simple_undo =
        \ empty(maparg('<Plug>(highlightedundo-undo)'))
  endif
  return s:should_use_simple_undo
endfunction

function! vimrc#undo#Undo(count) abort
  if vimrc#undo#ShouldUseSimpleUndo()
    call vimrc#undo#RepeatWrap('u', a:count, 'n')
  else
    call vimrc#undo#RepeatWrap("\<Plug>(highlightedundo-undo)", a:count, 'm')
  endif
endfunction
function! vimrc#undo#UndoLine(count) abort
  if vimrc#undo#ShouldUseSimpleUndo()
    call vimrc#undo#RepeatWrap('U', a:count, 'n')
  else
    call vimrc#undo#RepeatWrap("\<Plug>(highlightedundo-Undo)", a:count, 'm')
  endif
endfunction
function! vimrc#undo#Redo(count) abort
  if vimrc#undo#ShouldUseSimpleUndo()
    call vimrc#undo#RepeatWrap("\<C-R>", a:count, 'n')
  else
    call vimrc#undo#RepeatWrap("\<Plug>(highlightedundo-redo)", a:count, 'm')
  endif
endfunction
