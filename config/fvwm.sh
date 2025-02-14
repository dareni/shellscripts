#!/usr/bin/env sh
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

    #SCR_RES=`xrandr |grep "^Screen 0:" |awk '{print $8" "$10}'`
    SCR_RES=`xrandr |grep "*" |head -1 |awk '{print $1}'`
    X=${SCR_RES%%x*}
    Y=${SCR_RES##*x}
    #Y=${Y%%,}

    TIME_POS=$(($X-$TIME_POS))
    DATE_POS=$(($X-$DATE_POS))
    XLOAD_POS=$(($X-$XLOAD_POS))
    #TRAY_POS=$(($X-$TRAY_POS))
    PADDING=-5
    HOST_NAME=`hostname`
    if [ "${HOST_NAME}" = "sweetpea" \
        -o "${HOST_NAME}" = "noah" \
        -o "${HOST_NAME}" = "acdc" \
        -o "${HOST_NAME}" = "ewan" \
        -o "${HOST_NAME}" = "linda" \
    ]; then
        PADDING=-5
    fi

    #stalonetray -i 16 -bg black --geometry 1x1+$TRAY_POS+0 --grow-gravity E &
    trayer --edge top --distance $TRAY_POS --distancefrom right --widthtype request \
        --align right --transparent true --alpha 255 &
    xclock -update 1 -digital -norender -padding $PADDING -geometry 70x14+$TIME_POS+0  -strftime " %H:%M:%S" &
    xclock           -digital -norender -padding $PADDING -geometry 115x14+$DATE_POS+0 -strftime " %a %b %d %Y" &
    xload -geometry 100x28+$XLOAD_POS+0 -nolabel &

    if [ -f `which wpa_gui` ]; then
      (
        #make sure trayer is up before starting wpa_gui
        sleep 2
        sudo wpa_gui -t
      )&
    fi

    #Pop message when on battery.
    UPOWER=`which upower`
    if [ -n "$UPOWER" ]; then
      ~/bin/shellscripts/config/funcPower.sh &
    fi

    #Configure Touch pad on HP EliteBook
    TOUCH_ID=`xinput list --id-only "ALP0017:00 044E:121C Touchpad"`
    if [ -n "$TOUCH_ID" ]; then
      xinput set-prop $TOUCH_ID 345 1 #Tapping Enabled
      xinput set-prop $TOUCH_ID 358 1 #Middle button emulation enabled
    fi

    #Configure Touch pad on Dell Latitude E5440
    TOUCH_ID=`xinput list --id-only "AlpsPS/2 ALPS GlidePoint"`
    if [ -n "$TOUCH_ID" ]; then
      xinput set-prop $TOUCH_ID 312 1 #Tapping Enabled
      xinput set-prop $TOUCH_ID 327 1 #Middle button emulation enabled
    fi
}

case $CMD in
    init)
        do_init
    ;;
    restart)
        do_restart
    ;;
esac
