#!/usr/local/bin/bash
# Maintained at: git@github.com:dareni/shellscripts.git
#### noddy ####
# Link to .fvwm/fvwm.sh executed from init.fvwm by:
# + I Exec exec ~/.fvwm/fvwm.sh init

CMD=$1

do_init() {
    xbacklight -set 20 &
    #Top right 1920-70-115
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

    #Pop message when on battery.
    (while [ 1 ]; do
        if [ `upower -d |grep on-battery |awk '{print $2}'` = yes ]; then
            (xterm -geometry 100x6-0+0 -fa *courier* -fs 12 -bg darkgray -fg black -e ~/bin/shellscripts/timer.sh 0 "No power!!!!!")&
        fi;
        sleep 60
    done)&

    #Allow right margin of 111
    #Width 115 pos=1920-115-70=1735 - 111 = 1624
#    xclock -digital  -norender -padding -5 -geometry 115x14+1624+0 -strftime  " %a %b %d %Y" &
    #Width 70 pos=1920-70=1850 - 111 = 1739
#    xclock -digital -update 1 -norender -padding -5 -geometry 70x14+1739+0 -strftime " %H:%M:%S" &
#    xload -geometry 100x28+1500+0 -nolabel &
#    stalonetray -i 16 --geometry 1x1+1450+0 --grow-gravity NE &
#    xterm +sb -g 100x58+1314+15 -fn 6x13 &
#    xterm +sb -g 100x22+1314+780 -fn 6x13 &
#    jitsi
}

case $CMD in
    init)
        do_init
    ;;
    restart)
        do_restart
    ;;
esac
