#!/usr/bin/env sh
if [ -z `which yad` ]; then
  echo "Please install yad"
fi
if [ -z `which python` ]; then
  if [ -z `which python3` ]; then
    echo "Please install python"
  else
    ln -s `which python3` $HOME/bin/python
  fi
fi

sudo chown root:root $HOME/bin/shellscripts/krunker.sh
sudo chmod 655  $HOME/bin/shellscripts/krunker.sh
sudo chown root:root $HOME/bin/shellscripts/pw
sudo chmod 755  $HOME/bin/shellscripts/pw
sudo chmod 755  $HOME/bin/shellscripts/config/fvwmQuit.sh

mkdir -p $HOME/.fvwm/screenshot

if [ -d $HOME/bin/shellscripts ]; then
  ln -s $HOME/bin/shellscripts/config/vim/_vimrc $HOME/_vimrc
  mkdir -p $HOME/.vim/{colors,ftplugin,pack/git-plugins}
  ln -s $HOME/bin/shellscripts/config/vim/colors/rusty.vim $HOME/.vim/colors
  ln -s $HOME/bin/shellscripts/config/vim/ftplugin/{asm.vim,rust.vim,text.vim} $HOME/.vim/ftplugin
  ln -s $HOME/bin/shellscripts/config/alias.env $HOME/.bash_aliases
  if [ -f $HOME/.bash_profile ]; then
    echo WARNING: $HOME/.bash_profile exists so .profile inactive!
  fi
  if [ -f $HOME/.bash_login ]; then
    echo WARNING: $HOME/.bash_login exists so .profile inactive !
  fi
  if [ ! -L $HOME/.profile ]; then
    mv $HOME/.profile $HOME/.profile_orig
  fi
  ln -s $HOME/bin/shellscripts/config/.profile $HOME/.profile
  if [ ! -L $HOME/.bashrc ]; then
    mv $HOME/.bashrc $HOME/.bashrc_orig
  fi

  ln -s $HOME/bin/shellscripts/config/.bashrc $HOME/.bashrc
  ln -s $HOME/bin/shellscripts/config/.xsessionrc $HOME/.xsessionrc
  ln -s $HOME/bin/shellscripts/config/.dircolors $HOME/.dircolors
  ln -s $HOME/bin/shellscripts/config/.Xresources $HOME/.Xresources
  ln -s $HOME/bin/shellscripts/config/.Xresources $HOME/.Xdefaults

  if [ -e $HOME/.fvwm/config ]; then
    mv $HOME/.fvwm/config $HOME/.fvwm/config_o
  fi
  ln -s $HOME/bin/shellscripts/config/config $HOME/.fvwm/config
  ln -s $HOME/bin/shellscripts/config/override.fvwm $HOME/.fvwm/override.fvwm
  ln -s $HOME/bin/shellscripts/config/init.fvwm $HOME/.fvwm/init.fvwm
  ln -s $HOME/bin/shellscripts/config/raw/funstuffPiMenu.fvwm $HOME/.fvwm/funstuffPiMenu.fvwm
  ln -s $HOME/bin/shellscripts/config/gameMenu.fvwm $HOME/.fvwm/gameMenu.fvwm
  ln -s $HOME/bin/shellscripts/config/fvwm.sh $HOME/.fvwm/fvwm.sh
  ln -s $HOME/bin/shellscripts/config/fvwmQuit.sh $HOME/.fvwm/fvwmQuit.sh
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
  if [ ! -f /usr/local/etc/jdktab ]; then
    echo "#Configuration for jdktab. \n\
#See git@github.com:dareni/shellscripts.git" \
    | sudo tee /usr/local/etc/jdktab > /dev/null
    echo "Configure /usr/local/etc/jdktab if required for java."
  fi
else
  echo shellscripts must reside in $HOME/bin/shellscripts.
fi
