set tabstop=2
set shiftwidth=2
set expandtab
"break on space for wrap
set linebreak
set wrap
"indent by 2 spaces the broken line
set showbreak=\ \
set foldmethod=marker
colo asu1dark

if $TERM == 'alacritty' || $TERM == 'tmux-256color'
   hi Normal guibg=NONE ctermbg=NONE
   hi EndOfBuffer guibg=NONE ctermbg=NONE
   hi Folded guibg=NONE ctermbg=NONE
   hi MatchParen ctermfg=200 ctermbg=NONE
endif
