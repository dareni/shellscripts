#!/usr/local/bin/bash
# Maintained at: git@github.com:dareni/shellscripts.git
#### sweetpea ####
# Link to .fvwm/fvwm.sh executed from init.fvwm by:
# + I Exec exec ~/.fvwm/fvwm.sh init

CMD=$1

do_init() {
    #Top right 1680+1920-70-115
    #Broken 1680 so subtract that from the horizontal spacings.
    TIME_POS=185
    DATE_POS=120
    XLOAD_POS=300
    TRAY_POS=350

    SCR_RES=`xrandr |grep "^Screen 0:" |awk '{print $8" "$10}'`
    X=${SCR_RES%% *}
    Y=${SCR_RES##* }
    Y=${Y%%,}

    TIME_POS=$(($X-$TIME_POS))
    DATE_POS=$(($X-$DATE_POS))
    XLOAD_POS=$(($X-$XLOAD_POS))
    TRAY_POS=$(($X-$TRAY_POS))

    xclock -digital -update 1 -norender -padding -5 -geometry 70x14+$TIME_POS+0 -strftime " %H:%M:%S" &
    xclock -digital  -norender -padding -5 -geometry 115x14+$DATE_POS+0 -strftime  " %a %b %d %Y" &
    xload -geometry 100x28+$XLOAD_POS+0 -nolabel &
    stalonetray -i 16 --geometry 1x1+$TRAY_POS+0 --grow-gravity NE &

#    xclock -digital -update 1 -norender -padding -5 -geometry 70x14+1735+0 -strftime " %H:%M:%S" &
#    xclock -digital  -norender -padding -5 -geometry 115x14+1800+0 -strftime  " %a %b %d %Y" &
#    xload -geometry 100x28+1620+0 -nolabel &
#    stalonetray -i 16 --geometry 1x1+1570+0 --grow-gravity NE &
#    xterm +sb -g 100x58+0+0 -fn 6x13 &
#    xterm +sb -g 100x22+0+772 -fn 6x13 &
}

case $CMD in
    init)
        do_init
    ;;
    restart)
        do_restart
    ;;
esac
