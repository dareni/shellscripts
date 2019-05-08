#!/usr/bin/env sh
# Maintained at: git@github.com:dareni/shellscripts.git
#
# Configure rpi for minimal disk write.
# Call this file from .profile eg:
# ~/bin/shellscripts/unburdenSimple.sh

TARGETDIR=$XDG_RUNTIME_DIR/unburden

doTarget() {
  PTGT=$1
  PTYP=$2
  #Create the file in ram.
  if [ "$PTYP" = "d" ]; then
    mkdir -p $TARGETDIR/$PTGT
  else
    if [ ! -e $TARGETDIR/$PTGT ]; then
      mkdir -p $TARGETDIR/$PTGT
      rmdir $TARGETDIR/$PTGT
      touch $TARGETDIR/$PTGT
    fi
  fi

  #Create a link to ram if it does not exist.
  if [ ! -h $HOME/$PTGT ]; then
    if [ -d $HOME/$PTGT ]; then
      if [ -n $PTGT ]; then
        rm -rf $HOME/$PTGT
      fi
    fi
    ln -sf $TARGETDIR/$PTGT ~/$PTGT
  fi

}

if [ ! -e $TARGETDIR ]; then
  mkdir $TARGETDIR
fi

doTarget .cache d
doTarget .bash_history f
doTarget .xsession-errors f
doTarget .dbus d
doTarget dbus d
