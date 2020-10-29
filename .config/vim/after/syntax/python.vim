" The vim distributed syntax file doesn't define a comment cluster, so we must
" override the comment keyword. The downside is that if the comment keyword is
" updated upstream we won't get the new updates.

" NOTE: The vim distributed syntax file actually includes "NOTE" in the pythonTodo
" keyword, but vim-polyglot overrides it.

" NOTE: `:syntax keyword` doesn't match chars that are not in `iskeyword`, or
" any word followed by a char that is not in `iskeyword`. In python a colon is
" a keyword char, so that means that "NOTE:" won't be matched by, hence we must
" use `:syntax match`.
function! s:SetPythonTodoSyntax() abort
  syntax clear pythonTodo
  syntax case match
  syntax match pythonTodo contained "\v(TODO|NOTE|EXP|FIXME|XXX|TBD)\ze(\(\w+\))?:(\s|$)"
endfunction

call s:SetPythonTodoSyntax()

" NOTE: It seems that the `:syntax clear pythonTodo` called above does not
" clear the previous definition, which causes things like '<TODO>' match in
" pythonTodo in comments. This is a workaround that re-runs the syntax clearing
" command when the buffer is entered.
augroup vimrc
  autocmd BufWinEnter * ++once call <SID>SetPythonTodoSyntax()
augroup END
