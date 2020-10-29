" The vim distributed syntax file does actually define a comment cluster, but in
" this case we want to override the default todo keyword, which is defined as
" case insensitive in the distributed syntax file.
syntax case match
syntax keyword texTodo contained TODO NOTE EXP FIXME XXX TBD COMBAK
