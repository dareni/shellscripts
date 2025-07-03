#!/usr/bin/env sh
# Maintained at: git@github.com:dareni/shellscripts.git
#### sweetpea ####
# Link to .fvwm/fvwm.sh executed from init.fvwm by:
# + I Exec exec ~/.fvwm/fvwm.sh init

CMD=$1

do_init() {

    if [ -f "`which wpa_gui`" ]; then
      sudo wpa_gui -t &
    fi

    if [ -f "`which cbatticon`" ]; then
      cbatticon &
    fi

    #Pop message when on battery.
    UPOWER=`which upower`
    if [ -n "$UPOWER" ]; then
      ~/bin/shellscripts/config/funcPower.sh &
    fi

    #Configure Touch pad on HP EliteBook
    #TOUCH_ID=`xinput list --id-only "ALP0017:00 044E:121C Touchpad"`
    #The wifi key is not mapped. Find it using sudo `journalct -f` shows as e078, so map it
    # to the XF86WLAN code 246(subtract 8 to get 238):
    # `sudo setkeycodes e078 238`
    # Map the keycode to X `xmodmap -e "keycode 238 = XF86WLAN"`
    # Use `saowkey -k`  to print the mapping code.
    # Use getkeycodes to print a table of mappings from scan code to keycodes.
    # Use `xmodmap -pke`: to print a list of keycodes to identifiers.
    if [ -n "${TOUCH_ID:=`xinput list --id-only "ALP0017:00 044E:121C Touchpad"`}" ]; then
      xinput set-prop $TOUCH_ID 345 1 #Tapping Enabled
      xinput set-prop $TOUCH_ID 358 1 #Middle button emulation enabled
      sudo setkeycodes e078 238
      xmodmap -e "keycode 238 = XF86WLAN"
    #Configure Touch pad on Dell Latitude 5290
    elif [ -n "${TOUCH_ID:=`xinput list --id-only "Wacom HID 484D Finger touch"`}" ]; then
      xinput set-prop $TOUCH_ID 324 1 #Enable 2 finger scroll.
    #Configure Touch pad on Dell Latitude E5440
    #TOUCH_ID=`xinput list --id-only "AlpsPS/2 ALPS GlidePoint"`
    elif [ -n "${TOUCH_ID:=`xinput list --id-only "AlpsPS/2 ALPS GlidePoint"`}" ]; then
      xinput set-prop $TOUCH_ID 312 1 #Tapping Enabled
      xinput set-prop $TOUCH_ID 327 1 #Middle button emulation enabled
    #Configure Touch pad on Asus
    #SYNCLIENT=`which synclient`
    elif [ -n "`which synclient`" ]; then
      synclient TapButton1=1
      synclient TapButton2=2
      synclient TapButton3=3
      synclient PalmDetect=1
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
