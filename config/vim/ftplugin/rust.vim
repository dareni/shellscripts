
"leg g:ale_completion_symbols = { 'method': 'hello'}
"let g:ale_linters_explicit=1
"let g:ale_linters_ignore= {'rust': ['cargo']}
"let g:ale_keep_list_window_open = 0
"let g:ale_hover_preview = 1
"
"When rust file is not part of a cargo project use rustc linter.
let cargo_op=system('cargo verify-project')
if v:shell_error != 0
  "No cargo project so use rustc
  let g:ale_linters={'rust': ['rustc']}
else
  "Runs faster without cargo
  let g:ale_linters={'rust':['analyzer']}
endif

"None of these seem to be reliable so disable.
"Only the lint on save is reliable.
let g:ale_lint_on_text_changed= 0
let g:ale_lint_on_insert_leave = 0
let g:ale_completion_enabled = 0

let g:ale_set_quickfix = 1
let g:ale_list_window_size = 5
let g:ale_open_list = 1

colo rusty
if $TERM =='alacritty'
   hi Normal guibg=NONE ctermbg=NONE
   hi EndOfBuffer guibg=NONE ctermbg=NONE
   hi Folded guibg=NONE ctermbg=NONE
   hi MatchParen ctermfg=200 ctermbg=NONE
endif

set foldmethod=syntax

let $RUST_SRC_PATH=trim(system("rustc --print sysroot"))."/lib/rustlib/src/rust/library"
let &tags="rusty-tags.vi"
set tagcase=smart

"Activate Ale autocomplete ie ctrl-a in insert mode(imap).
"Not available without rust-analyzer
inoremap <C-A> <Plug>(ale_complete)

map <leader>ll <Plug>(ale_lint)

nnoremap <leader>ai <Plug>(ale_info)

map <leader>gd <Plug>(ale_go_to_definition)
"open a window for display of what is under the cursor.
map <leader>ah :ALEHover <RETURN>
map <leader>cl :cexpr []
map <leader>ae <Plug>(ale_enable)
map <leader>ad <Plug>(ale_disable)

map <leader>cb :!clear; cargo build
map <leader>cr :!clear; cargo run
map <leader>ct :!clear; cargo test -- --nocapture
map <leader>ft :%!rustfmt

function! RustyTags()
  call system("rusty-tags vi")
  "let l:tpath=system("pwd")
  "let l:tpath= trim(l:tpath)."/rusty-tags.vi"
  "let &tags=l:tpath.",".g:rust_src_path."/rusty-tags.vi"
endfunction
"run rusty-tags
map \rt :call RustyTags() <RETURN>

function! GdbSetup()
  set mouse=a
  "let g:termdebug_popup = 0
  let g:termdebug_wide = 163
  packadd termdebug
endfunction

map \rg :call GdbSetup()

