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
if $TERM == 'alacritty' || $TERM == 'tmux-256color'
   hi Normal guibg=NONE ctermbg=NONE
   hi EndOfBuffer guibg=NONE ctermbg=NONE
   hi Folded guibg=NONE ctermbg=NONE
   hi MatchParen ctermfg=200 ctermbg=NONE
   hi Comment ctermfg=223
   hi Special ctermfg=223
endif

"setup program counter and breakpoint colours.
if &background == "dark"
  hi debugPC term=reverse ctermbg=darkblue guibg=darkblue
  hi debugBreakpoint term=reverse ctermbg=red guibg=red
  hi LineNr       term=NONE cterm=NONE ctermfg=Red         ctermbg=Black

else
  hi debugPC term=reverse ctermbg=lightblue guibg=lightblue
  hi debugBreakpoint term=reverse ctermbg=red guibg=red
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

"{{{ RustyFormat()
function! RustyFormat()
  let pos = getcurpos()
  %!rustfmt
  call setpos('.', pos)
endfunction
"}}}
map <leader>ft :call RustyFormat() <RETURN>

"{{{ RustyTags()
"Not using tags now.
"Using ALE rust-analyzer <leader>gd go definition function.
function! RustyTags()
  call system("rusty-tags vi")
  "let l:tpath=system("pwd")
  "let l:tpath= trim(l:tpath)."/rusty-tags.vi"
  "let &tags=l:tpath.",".g:rust_src_path."/rusty-tags.vi"
endfunction
"}}}
map <leader> :call RustyTags() <RETURN>

"{{{ DebugTest()
"debug the test under the cursor.
function DebugTest()
  "Get the  #[test] function name above the cursor.
  "First position the cursor on the next line in case it is on #[test].
  let l:pos = getcurpos()
  let l:pos[1]+=1
  call setpos('.', l:pos)
  "Search for the fn line.
  call search('#[test\].*$\n.*fn', 'bec')
  let l:fn_name = getline('.')
  let l:fn_start_pos = matchend(fn_name, 'fn *')
  let l:fn_end_pos = match(fn_name, '(')
  "Extract the function name.
  let l:fn_name = strpart(l:fn_name, l:fn_start_pos, l:fn_end_pos-l:fn_start_pos)
  "Get build the test executable and get its name.
  silent let l:cargo_op = systemlist('cargo build --tests --message-format json')
  for line in l:cargo_op
    if line =~ '^{'
      let l:json=json_decode(line)
      if has_key(l:json, "executable")
        let l:exe = l:json["executable"]
        if l:exe != v:null
          break
        endif
      endif
    endif
  endfor
  if len(l:exe) <= 0
    throw "'cargo build --test -message-format json' failed"
  endif
  "Configure debugger options.
  call GdbSetup()
  "Capture the line number of the function for the first breakpoint.
  let l:pos = getcurpos()
  "Start gdb, set the breakpoint and run.
  call execute("TermdebugCommand "..l:exe.." --nocapture ".. l:fn_name)
  call TermDebugSendCommand(printf('break %d', l:pos[1]))
  call TermDebugSendCommand(printf('run'))
  "Note: does not seem to any way to navigate out of the gdb window with
  "vimscript.
endfunction
"}}}
nnoremap <leader>rdt :call DebugTest()<CR>

"{{{ GdbSetup()
function! GdbSetup()
  set mouse=a
  "let g:termdebug_popup = 0
  let g:termdebug_wide = 163
  let g:termdebugger="rust-gdb"
  "set trace-commands on
  "set logging on
  "and then tail the log in another shell:
  "cd where/gdb/is/running
  "tail -f gdb.txt
  "the sets can be added to ~/.gdbinit or ./.gdbinit
  "gdb commands: info b, info locals, info args, display d, print p, run r,
  "break b, layout, layout split, next n, step s, finish,
  "continue c
  "run {program args}
  "frame x to enter scope x. (f x)
  "close layout with ctrl-x a, ctrl-l for screen refresh.
  "watch x to watch var x.
  "set x= to set a value for x.
  packadd termdebug
	augroup debug_aug
	  autocmd!
    "autocmd WinClosed * :!echo closed<afile> >> /tmp/vibuf.out
    autocmd WinClosed * :call GdbTearDown()
	augroup END
  "map debugger binds here.
endfunction
"}}}
"{{{ GdbTearDown()
function! GdbTearDown()
  try
    call TermDebugSendCommand('info line')
    "unmap debugger binds here.
  catch
    autocmd! debug_aug
  endtry
endfunction
"}}}
