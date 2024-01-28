" Maintained at: git@github.com:dareni/shellscripts.git
" Rust plugin for autocomplete, debug etc.
" Link to ~/.vim/ftplugin/

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:save_cpo = &cpo
set cpo&vim

augroup rust.vim
autocmd!

let g:ale_linters = {'rust': ['analyzer', 'cargo', 'rls']}
"let g:ale_linters = {'rust': ['analyzer', 'cargo', 'rls', 'rustc']}
let g:ale_fixers = { 'rust': ['rustfmt', 'trim_whitespace', 'remove_trailing_lines'] }
let g:ale_completion_enabled = 1
let g:ale_sign_column_always = 1
let g:airline#extensions#ale#enabled = 1
"Only lint project files
let g:ale_pattern_options = {'\/opt\/dev\/*.rs$': {'ale_enabled': 0}}
"Enable quickfix
let g:ale_set_loclist = 1
let g:ale_set_quickfix = 1
let g:ale_open_list = 1
let g:ale_keep_list_window_open = 1
let g:ale_list_window_size = 5
let g:ale_pattern_options_enabled = 1
let g:ale_hover_preview = 1

"Activate Ale autocomplete ie ctrl-x ctrl-a in insert mode.
imap <C-A> <Plug>(ale_complete)

map \gd :ALEGoToDefinition
map \cl :cexpr []
map \da :let ale_enabled=0

map \cr :!clear; cargo run
map \ct :!clear; cargo test -- --nocapture
map \ft :%!rustfmt

function! RustyTags()
  call system("rusty-tags vi")
  let l:tpath=system("pwd")
  let l:tpath= trim(l:tpath)."/rusty-tags.vi"
  let &tags=l:tpath
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

let b:undo_ftplugin = ""

augroup END

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set noet sw=8 ts=8:
