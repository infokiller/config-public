" The syntax file from https://github.com/kevinoid/vim-jsonc doesn't define a
" comment cluster, so we must override the comment keyword. The downside is that
" if the comment keyword is updated upstream we won't get the new updates.

syntax clear jsonCommentTodo
syntax case match
syntax match jsonCommentTodo contained "\v(TODO|NOTE|EXP|FIXME|XXX|TBD)\ze(\(\w+\))?:(\s|$)"
highlight link jsonCommentTodo Todo
