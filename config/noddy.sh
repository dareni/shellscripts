#!/usr/local/bin/bash
# Maintained at: git@github.com:dareni/shellscripts.git
#### noddy ####
# Link to .fvwm/fvwm.sh executed from .fvwmrc by:
# + I Exec exec ~/.fvwm/fvwm.sh init

CMD=$1

do_init() {
    xbacklight -set 0 &
    #Allow right margin of 111
    #Width 115 pos=1920-115-70=1735 - 111 = 1624
    xclock -digital  -norender -padding -5 -geometry 115x14+1624+0 -strftime  " %a %b %d %Y" &
    #Width 70 pos=1920-70=1850 - 111 = 1739
    xclock -digital -update 1 -norender -padding -5 -geometry 70x14+1739+0 -strftime " %H:%M:%S" &
    xload -geometry 100x28+1500+0 -nolabel &
    stalonetray -i 16 --geometry 1x1+1450+0 --grow-gravity NE &
    xterm +sb -g 100x58+1314+15 -fn 6x13 &
    xterm +sb -g 100x22+1314+780 -fn 6x13 &
}

case $CMD in
    init)
        do_init
    ;;
    restart)
        do_restart
    ;;
esac
