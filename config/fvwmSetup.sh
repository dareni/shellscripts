mkdir -p $HOME/.fvwm/screenshot

if [ -d $HOME/bin/shellscripts ]; then

  ln -s $HOME/bin/shellscripts/config/alias.env $HOME/.bash_aliases
  ln -s $HOME/bin/shellscripts/config/.profile $HOME/.profile
  ln -s $HOME/bin/shellscripts/config/.bashrc $HOME/.bashrc
  ln -s $HOME/bin/shellscripts/config/.xinitrc $HOME/.xinitrc
  ln -s $HOME/bin/shellscripts/config/.dircolors $HOME/.dircolors
  ln -s $HOME/bin/shellscripts/config/.Xresources $HOME/.Xresources
  ln -s $HOME/bin/shellscripts/config/.Xresources $HOME/.Xdefaults


  if [ -e $HOME/.fvwm/config ]; then
    mv $HOME/.fvwm/config $HOME/.fvwm/config_o
  fi
  ln -s $HOME/bin/shellscripts/config/config $HOME/.fvwm/config
  ln -s $HOME/bin/shellscripts/config/override.fvwm $HOME/.fvwm/override.fvwm
  ln -s $HOME/bin/shellscripts/config/raw/funstuffPiMenu.fvwm $HOME/.fvwm/funstuffPiMenu.fvwm
  ln -s $HOME/bin/shellscripts/config/gameMenu.fvwm $HOME/.fvwm/gameMenu.fvwm
  ln -s $HOME/bin/shellscripts/config/fvwm.sh $HOME/.fvwm/fvwm.sh
  ln -s $HOME/bin/shellscripts/config/focusWindow.sh $HOME/.fvwm/focusWindow.sh
  ln -s $HOME/bin/shellscripts/config/progMenu.fvwm $HOME/.fvwm/progMenu.fvwm
  ln -s $HOME/bin/shellscripts/config/icons $HOME/.fvwm
  ln -s $HOME/bin/shellscripts/config/images $HOME/.fvwm

  PAVUCONTROL=`which pavucontrol`
  if [ -n "$PAVUCONTROL" ]; then
    ln -s $HOME/bin/shellscripts/pa-vol.py $HOME/.fvwm/mixer
  else
    ln -s $HOME/bin/shellscripts/fvwmMixer.sh $HOME/.fvwm/mixer
  fi

else
  echo shellscripts must reside in $HOME/bin/shellscripts.
fi
