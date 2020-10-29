syntax case match
syntax keyword dtTodo contained TODO NOTE EXP FIXME XXX TBD
highlight link dtTodo Todo
syntax match  dtComment /^\s*#.*$/ contains=@Spell,dtTodo
