" The vim distributed syntax file doesn't define a comment cluster, so we must
" override the comment keyword. The downside is that if the comment keyword is
" updated upstream we won't get the new updates.
syntax keyword tmuxTodo contained TODO NOTE EXP XXX FIXME
" NOTE: the default syntax file doesn't add @Spell to sdComment, which makes
" spell checking enabled on all the file instead of comments only. This fixes
" it.
syntax clear tmuxComment
syntax region tmuxComment start=/#/ skip=/\\\@<!\\$/ end=/$/ contains=tmuxTodo,@Spell
