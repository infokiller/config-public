syntax case match
syntax clear vimTodo
syntax match vimTodo contained '\v(\s|")\zs(TODO|NOTE|EXP|FIXME|XXX|TBD)\ze(:|\(\w\+\))(\s|$)'
syntax cluster vimCommentGroup add=vimTodo
" The vim syntax includes highlighting for "comment leaders", which seem to be 
" any upper case words with a colon. To make the highlighting consistent, I link
" it to the Todo group.
highlight! link vimCommentTitle Todo
