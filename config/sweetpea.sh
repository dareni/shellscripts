#!/usr/local/bin/bash
#### sweetpea ####
CMD=$1

do_init() {
    #Top right 1680+1920-70-115
    xclock -digital -update 1 -norender -padding -5 -geometry 70x14+3415+0 -strftime " %H:%M:%S"
    xclock -digital  -norender -padding -5 -geometry 115x14+3480+0 -strftime  " %a %b %d %Y"
    xload -geometry 100x28+3300+0 -nolabel
    stalonetray -i 16 --geometry 1x1+3250+0 --grow-gravity NE
    xterm +sb -g 100x58+1680+0 -fn 6x13
    xterm +sb -g 100x22+1680+772 -fn 6x13
}

case $CMD in
    init)
        do_init
    ;;
    restart)
        do_restart
    ;;
esac
