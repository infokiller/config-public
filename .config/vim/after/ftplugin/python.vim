" smartindent has issues with python comments, see: http://goo.gl/vFHOk2
" This is a workaround.
setlocal nosmartindent
" Disable code autowrapping which often breaks python code.
setlocal formatoptions-=t
" Automatically add space after starting a comment.
inoremap <buffer> #  X<C-H>#<Space>

let b:delimitMate_nesting_quotes = ['"', "'"]
