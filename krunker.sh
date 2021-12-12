#!/usr/bin/env sh
# need fusermount in fuse package.
#https://client2.krunker.io/setup.AppImage
KRUNKER_HOME=/opt/game/krunker
EXE_NAME=setup.AppImage
KRUNKER_URL="https://client2.krunker.io"
LOG=/tmp/krunker.log


fail() {
  xterm  -fa *courier* -fs 10 -bg black -fg white -T "Krunker Error" -hold -e echo -e "$1" &
}

download() {
  echo Downloading new version ....
  sudo wget $KRUNKER_URL/$EXE_NAME -O $KRUNKER_HOME/$EXE_NAME
  sudo chown root:root $KRUNKER_HOME/$EXE_NAME
  sudo chmod 755 $KRUNKER_HOME/$EXE_NAME
}

if [ -z "`which fusermount`" ]; then
  fail "\n\nPlease install fusermount."
  exit
fi

if [ -z "`which yad`" ]; then
  fail "\n\nPlease install yad."
  exit
fi

export SUDO_ASKPASS=$HOME/bin/shellscripts/pw
sudo -A pwd > /dev/null

if [ ! -d "$KRUNKER_HOME" ]; then
  mkdir -p /opt/game/krunker
  download
fi

if [ ! -x "$KRUNKER_HOME/$EXE_NAME" ]; then
  download
fi

sudo sysctl kernel.unprivileged_userns_clone=1
rm -f $LOG
touch $LOG
#Startup can fail because of ~/.config/io.krunker.desktop/
#strace /opt/game/krunker/setup.AppImage 2>~/strace.out
eval $KRUNKER_HOME/$EXE_NAME 2>>$LOG >>$LOG
if [ "$?" != 0 ]; then
  fail "`cat $LOG`"" \n New version required ? \n Or corrupt ~/.config/io.krunker.desktop ? \n Run strace to debug."
fi
sudo sysctl kernel.unprivileged_userns_clone=0
