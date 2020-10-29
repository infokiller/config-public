syntax case match
syntax match myProtoTodo contained "\v(\s|\/\/)\zs(TODO|NOTE|EXP|FIXME|XXX|TBD)\ze(:|\(\w\+\))(\s|$)"
highlight link myProtoTodo Todo
" It seems that the syntax/proto.vim changed the comment group name, so we add
" it to both.
syntax cluster protoCommentGrp add=myProtoTodo
syntax cluster pbCommentGrp add=myProtoTodo
