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
"let g:ale_pattern_options = {'\/opt\/dev\/*.rs$': {'ale_enabled': 0}}
"Enable quickfix
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
let g:ale_open_list = 1
let g:ale_keep_list_window_open = 1
let g:ale_list_window_size = 8
let g:ale_pattern_options_enabled = 1
let g:ale_hover_preview = 1

"let g:ale_set_echo_cursor = 0
"let g:ale_set_virtualtext_cursor = 0
"let g:ale_cursor_detail = 0
"let g:ale_set_balloons = 0

"config env rust-analyzer.diagnostics.disabled": ["inactive-code"],
let g:ale_rust_analyzer_config = {
\		'diagnostics': {
\			'disabled': ["inactive-code"]
\		}
\}

colo rusty
set foldmethod=syntax

"ENV for rusty-tags invocation.
let g:rust_src_path=trim(system("rustc --print sysroot"))."/lib/rustlib/src/rust/library"
let $RUST_SRC_PATH=g:rust_src_path
let &tags="rusty-tags.vi,".g:rust_src_path."/rusty-tags.vi"

set tagcase=smart 
"see tag-matchlist ie use :ts to get a tag picklist for multiple matches.


"Activate Ale autocomplete ie ctrl-x ctrl-a in insert mode.
imap <C-A> <Plug>(ale_complete)

map \gd :ALEGoToDefinition
map \cl :cexpr []
"map \ae :let ale_enabled=0
map \ae :ALEEnable <RETURN>
map \ad :ALEDisable <RETURN>

map \cb :!clear; cargo build 
map \cr :!clear; cargo run
map \ct :!clear; cargo test -- --nocapture
map \ft :%!rustfmt

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

let b:undo_ftplugin = ""

augroup END

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set noet sw=2 ts=2:
