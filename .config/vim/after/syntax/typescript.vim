" The vim distributed syntax file defines a comment cluster, but it's not
" sufficient to add a custom keyword for highlighting to work, so we override
" the comment keyword. The downside is that if the comment keyword is updated
" upstream we won't get the new updates.
syntax case match
syntax keyword typescriptCommentTodo TODO NOTE EXP FIXME XXX TBD
