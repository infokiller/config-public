" NOTE: As of 2019-06-02, these lines don't seem to have an effect.
" set runtimepath^=~/.vim runtimepath+=~/.vim/after
" let &packpath = &runtimepath

let s:script_dir = expand('<sfile>:p:h')
execute 'source ' . s:script_dir . '/../vim/vimrc'
