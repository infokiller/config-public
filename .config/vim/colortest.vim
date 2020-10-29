" Copied from https://vim.fandom.com/wiki/View_all_colors_available_to_gvim
" Some modifications to make it more flexible.
"
" Example usage for GUI color test:
"
" vim -c "set termguicolors | so ~/.config/vim/colortest.vim | call GUIColorTest('/tmp/gui-vim-color-test.tmp', {'red_begin': 0, 'red_end':0, 'green_begin': 20, 'green_end': 50, 'green_stride': 1, 'blue_begin': 20, 'blue_end': 60, 'blue_stride': 1 })"
"
" Example usage for terminal color test:
"
" vim -c "set notermguicolors | so ~/.config/vim/colortest.vim | call TerminalColorTest('terminal-vim-color-test.tmp', 256, 1)"

function! TerminalColorTest(outfile, fgend, bgend)
  let result = []
  for fg in range(a:fgend)
    for bg in range(a:bgend)
      let kw = printf('%-7s', printf('c_%d_%d', fg, bg))
      let h = printf('hi %s ctermfg=%d ctermbg=%d', kw, fg, bg)
      let s = printf('syn keyword %s %s', kw, kw)
      call add(result, printf('%-32s | %s', h, s))
    endfor
  endfor
  call writefile(result, a:outfile)
  execute 'edit '.a:outfile
  source %
endfunction
command! TerminalColorTest call TerminalColorTest('/tmp/terminal-vim-color-test.vim', 256, 16)

function! GUIColorTest(outfile, range_dict)
  let result = []
  let l:red_begin = get(a:range_dict, 'red_begin', 0)
  let l:red_end = get(a:range_dict, 'red_end', 255)
  let l:red_stride = get(a:range_dict, 'red_stride', 16)
  let l:green_begin = get(a:range_dict, 'green_begin', 0)
  let l:green_end = get(a:range_dict, 'green_end', 255)
  let l:green_stride = get(a:range_dict, 'green_stride', 16)
  let l:blue_begin = get(a:range_dict, 'blue_begin', 0)
  let l:blue_end = get(a:range_dict, 'blue_end', 255)
  let l:blue_stride = get(a:range_dict, 'blue_stride', 16)
  for red in range(l:red_begin, l:red_end, l:red_stride)
    for green in range(l:green_begin, l:green_end, l:green_stride)
      for blue in range(l:blue_begin, l:blue_end, l:blue_stride)
        let kw = printf('%-13s', printf('c_%d_%d_%d', red, green, blue))
        let fg = printf('#%02x%02x%02x', red, green, blue)
        let bg = '#002b36'
        let h = printf('hi %s guifg=%s guibg=%s', kw, fg, bg)
        let s = printf('syn keyword %s %s', kw, kw)
        call add(result, printf('%s | %s', h, s))
      endfor
    endfor
  endfor
  call writefile(result, a:outfile)
  execute 'edit '.a:outfile
  source %
endfunction
command! GUIColorTest call GUIColorTest('/tmp/gui-vim-color-test.vim')
