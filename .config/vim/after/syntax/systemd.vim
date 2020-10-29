" As of nvim 0.4.4 and vim 8.2, the systemd syntax file shipped just runs the
" dosini one. However, the systemd syntax file shipped with polyglot is actually
" different and defines its own syntax items. To be compatible with both, we try
" to detect if the polyglot syntax items are defined. Since vim doesn't expose
" an API to check which syntax items are defined, we use `syntax list` and see
" if there's an error.
" NOTE: we can't just modify both syntax items, because then spell checking
" doesn't work correctly.
function! s:FixSystemdSyntax() abort
  let l:is_dosini_syntax = 0
  try
    silent syntax list sdComment
  catch /E28/
    let l:is_dosini_syntax = 1
  endtry
  if l:is_dosini_syntax
    runtime! syntax/dosini.vim
    return
  endif
  syntax keyword sdTodo contained TODO NOTE EXP XXX FIXME
  " NOTE: the default syntax file doesn't add @Spell to sdComment, which makes
  " spell checking enabled on all the file instead of comments only. This fixes
  " it.
  syntax clear sdComment
  syntax match sdComment /^[;#].*/ contains=sdTodo,@Spell containedin=ALL
  " Fix the systemd syntax file requiring that system Exec programs start be
  " absolute paths, which was changed in systemd to allow simple filenames[1].
  " [1] https://github.com/systemd/systemd/commit/5008da1ec1cf2cf8c15b702c4052e3a49583095d
  syntax clear sdExecFile
  syntax match sdExecFile contained /\S\+/ nextgroup=sdExecArgs
endfunction

call s:FixSystemdSyntax()
