setlocal textwidth=0
setlocal conceallevel=2
let b:delimitMate_nesting_quotes = ['`']
" Prettier formatting doesn't work with files that don't have markdown file
" extensions, such as when editing files in Firenvim. This fixes it.
let b:ale_javascript_prettier_options = '--parser markdown --prose-wrap always'
