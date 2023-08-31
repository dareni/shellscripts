#!/usr/bin/env sh
RESOURCE_ID=$1
NAME=$2
WINDOW_ID=$3
#echo Echo $1 $2 $3
#NoResource Java 0x22000f3
# sun-awt-X11-XFramePeer Jitsi 0x2400007
if [ "${RESOURCE_ID}" = "FvwmPager" ]; then
  echo "SetEnv fvwmpagerid $WINDOW_ID"
elif [ "${RESOURCE_ID}" = "NoResource" ]; then
  #Attempt to hide the Jitsi startup window.
  #Note: the Iconify here has no effect :(.
  echo WindowId $WINDOW_ID Iconify true
elif [ "${RESOURCE_ID}" = "sun-awt-X11-XFramePeer" -a "${RESOURCE_ID}" = "Jitsi" ]; then
  #Iconify the Jitsi application after it has started.
  echo WindowId $WINDOW_ID Iconify true
#else No longer use the new window event for warptowindow. Use Style InitialMapCommand.
  #Jump to all other windows when the open.
#  echo FlipFocus
#  echo WarpToWindow 50 50

fi;
