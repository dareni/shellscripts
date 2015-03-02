#!/usr/local/bin/bash
# Maintained at: git@github.com:dareni/shellscripts.git
#### sweetpea ####
# Link to .fvwm/fvwm.sh executed from .fvwmrc by:
# + I Exec exec ~/.fvwm/fvwm.sh init

CMD=$1

do_init() {
    #Top right 1680+1920-70-115
    #Broken 1680 so subtract that from the horizontal spacings.
    xclock -digital -update 1 -norender -padding -5 -geometry 70x14+1735+0 -strftime " %H:%M:%S" &
    xclock -digital  -norender -padding -5 -geometry 115x14+1800+0 -strftime  " %a %b %d %Y" &
    xload -geometry 100x28+1620+0 -nolabel &
    stalonetray -i 16 --geometry 1x1+1570+0 --grow-gravity NE &
    xterm +sb -g 100x58+0+0 -fn 6x13 &
    xterm +sb -g 100x22+0+772 -fn 6x13 &
}

case $CMD in
    init)
        do_init
    ;;
    restart)
        do_restart
    ;;
esac
