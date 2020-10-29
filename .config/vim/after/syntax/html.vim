" The vim distributed syntax file doesn't define a comment cluster, so we must
" override the comment match. The downside is that if the comment keyword is
" updated upstream we won't get the new updates.
syntax case match
syntax keyword htmlTodo contained TODO NOTE EXP FIXME XXX TBD
highlight link htmlTodo Todo
" Comments (the real ones or the old netscape ones)
if exists('html_wrong_comments')
  syn region htmlComment                start=+<!--+    end=+--\s*>+ contains=@Spell,htmlTodo
else
  syn region htmlComment                start=+<!+      end=+>+   contains=htmlCommentPart,htmlCommentError,@Spell,htmlTodo
  syn match  htmlCommentError contained "[^><!]"
  syn region htmlCommentPart  contained start=+--+      end=+--\s*+  contains=@htmlPreProc,@Spell,htmlTodo
endif
