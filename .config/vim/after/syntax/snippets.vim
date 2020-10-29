" The vim distributed syntax file doesn't define a comment cluster, so we must
" override the comment keyword. The downside is that if the comment keyword is
" updated upstream we won't get the new updates.
syntax case match
syntax keyword snipTODO contained display TODO NOTE EXP FIXME XXX
