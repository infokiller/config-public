" The vim distributed syntax file doesn't define a comment cluster, so we must
" override the comment match. The downside is that if the comment keyword is
" updated upstream we won't get the new updates.
syntax case match
syntax keyword gitcommitTodo contained TODO NOTE EXP FIXME XXX TBD
highlight link gitcommitTodo Todo
syntax match gitcommitComment	"^#.*" contains=@Spell,gitcommitTodo
