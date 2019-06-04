#!/usr/bin/env sh
# Maintained at: git@github.com:dareni/shellscripts.git
#
# Configure rpi for minimal disk write.
# Call this file from .profile eg:
# ~/bin/shellscripts/unburdenSimple.sh

if [ -z $XDG_RUNTIME_DIR ]; then
  USERID=`cat /etc/passwd |grep $USER | cut -d: -f 3`
  TARGETDIR=/run/user/$USERID/unburden
else
  TARGETDIR=$XDG_RUNTIME_DIR/unburden
fi


doTarget() {
  PTGT=$1
  PTYP=$2
  #Create the file in ram.
  if [ -e "$HOME/$PTGT" -o -h "$HOME/$PTGT" ]; then
    if [ "$PTYP" = "d" ]; then
      if [ ! -e $TARGETDIR/$PTGT ]; then
        mkdir -p $TARGETDIR/$PTGT
        chmod 700 $TARGETDIR/$PTGT
      fi
    else
      if [ ! -e $TARGETDIR/$PTGT ]; then
        mkdir -p $TARGETDIR/$PTGT
        rmdir $TARGETDIR/$PTGT
        touch $TARGETDIR/$PTGT
        chmod 600 $TARGETDIR/$PTGT
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
  fi
}

if [ ! -e $TARGETDIR ]; then
  mkdir -p $TARGETDIR
else
  exit
fi

doTarget .cache d
doTarget .bash_history f
doTarget .dbus d
doTarget .config/vice/vice.log f

#in /etc/X11/Xsession ERRFILE=~/.cache/xsession-errors
#in .bashrc export XAUTHORITY=~/.cache/Xauthority
#in .bashrc export LESSHISTFILE=~/.cache/lesshist
