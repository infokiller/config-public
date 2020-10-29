if g:VSCODE_MODE
  function! vimrc#actions#LastBuffer() abort
    " TODO: This only opens the list of recently used editors but requires
    " another Enter press to open the previous one. I tried to use the `type`
    " command to type enter but it doesn't work (it types it in the open
    " editor). It seems that I should be able to write an extension for this
    " using the `onDidChangeActiveTextEditor` event to track the previous
    " editor: https://code.visualstudio.com/api/references/vscode-api#window
    call VSCodeNotify('workbench.action.quickOpenPreviousRecentlyUsedEditorInGroup')
  endfunction
else
  function! vimrc#actions#LastBuffer() abort
    " If the alternate file doesn't exist buf the number of buffers is larger than
    " 1, switch to the next buffer. Otherwise, try to edit the alternate file
    " (which will give an error if it doesn't exist).
    " NOTE: Previously `expand('#')` only worked when called inline, not in a
    " function, but I can no longer reproduce it.
    if !strlen(expand('#')) && len(getbufinfo()) > 1
      bn
    else
      try
        e#
      catch /E194/
        call vimrc#Warning('No alternate file')
      endtry
    endif
  endfunction
endif
