syntax case match
syntax match myShTodo contained "\v(NOTE|EXP)\ze(\(\w+\))?:(\s|$)"
" if exists('b:is_bash')
"   syntax match myShTodo contained "\<NOTE\ze:\=\>"
" else
"   syntax keyword myShTodo contained NOTE EXP
" endif
highlight link myShTodo Todo
syntax cluster shCommentGroup add=myShTodo
