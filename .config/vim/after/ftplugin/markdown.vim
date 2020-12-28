setlocal textwidth=0
setlocal conceallevel=2
let b:delimitMate_nesting_quotes = ['`']
" Prettier formatting doesn't work with files that don't have markdown file
" extensions, such as when editing files in Firenvim. This fixes it.
let b:ale_javascript_prettier_options = '--parser markdown'
" Many websites such as Trello are sensitive to a single line break, so prettier
" will cause long lines to be split to multiple lines. See:
" https://prettier.io/docs/en/options.html#prose-wrap
" NOTE: for some reason using g:FIRENVIM_MODE doesn't work: it's set to v:true
" although it should be set to 0.
if !get(g:, 'started_by_firenvim', 0)
  let b:ale_javascript_prettier_options .= ' --prose-wrap always'
endif
