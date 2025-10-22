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
if [ `xlsfonts |grep -c -- \
  "-misc-fixed-medium-r-normal--10-70-100-100-c-60-iso8859-1"` -eq 0 ]; then
  echo "Font: -misc-fixed-medium-r-normal--10-70-100-100-c-60-iso8859-1"
  echo "      required for the date of the fvwm status bar."
fi
if [ `fc-list |grep -c -- \
  "JetBrainsMono"` -eq 0 ]; then
  #https://github.com/adobe-fonts/source-code-pro/releases/download/2.042R-u%2F1.062R-i%2F1.026R-vf/OTF-source-code-pro-2.042R-u_1.062R-i.zip
  echo "Installing Font: JetBrainsMono required for lazyvim."
  sudo mkdir -p /usr/local/share/fonts/JetBrains
  sudo curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.tar.xz |\
  sudo tar -xvJ -C /usr/local/share/fonts/JetBrains
  fc-cache -fv
fi

if [ 0 -eq `dpkg -l |grep -c swh-plugins` ]; then
  echo The swh-plugins package \(Steve Harris LADSPA plugins\)
  echo  for sound equalization is not installed.
  echo Used in .xsessionrc configuration.
fi
if [ 0 -eq `dpkg -l |grep -c findutils` ]; then
  echo findutils not installed for xargs.
fi

if [ -z "`which stalonetray`" ]; then
  echo stalonetray not installed.
  echo wpagui, cbatticon and steam tray icons will not be visible.
fi
if [ 0 -eq `xmem -help 2>&1 |grep -c usage:` ]; then
  echo ~/bin/shellscripts/xmem may require recompilation.
  echo see https://git.sdf.org/bch/xmem
fi

sudo chown root:root $HOME/bin/shellscripts/krunker.sh
sudo chmod 655  $HOME/bin/shellscripts/krunker.sh
sudo chown root:root $HOME/bin/shellscripts/pw
sudo chmod 755  $HOME/bin/shellscripts/pw
sudo chmod 755  $HOME/bin/shellscripts/config/fvwmQuit.sh

if [ ! -f $HOME/.fvwm/cfg/main_menu_button.cfg ]; then
  read -p "Configure FVWM MainMenuButton(for touch screens) (y/N) : " CONF_TOUCH
  if [ y = "$CONF_TOUCH" ]; then
    mkdir -p $HOME/.fvwm/cfg
    echo creating: $HOME/.fvwm/cfg/main_menu_button.cfg
    cat <<HEREDOC > $HOME/.fvwm/cfg/main_menu_button.cfg
*MainMenuButton: Geometry 24x24-370-0
*MainMenuButton: (Id mainMenu, Icon 24/next.png, ActionOnPress, Action Menu QuickMenu)
HEREDOC
  fi
fi

if [ ! -f $HOME/.fvwm/cfg/status_panel.cfg ]; then
  read -p "Configure FVWM StatuspPanel (for touch screens) (y/N) : " CONF_TOUCH
  if [ y = "$CONF_TOUCH" ]; then
    mkdir -p $HOME/.fvwm/cfg
    echo creating: $HOME/.fvwm/cfg/status_panel.cfg
    cat <<HEREDOC > $HOME/.fvwm/cfg/status_panel.cfg
*StatusPanel: Geometry 370x25-0-0
HEREDOC
  fi
fi

if [ ! -f $HOME/.fvwm/cfg/xvkbd.cfg ]; then
  read -p "Configure FVWM xv keyboard (for touch screens) (y/N) : " CONF_TOUCH
  if [ y = "$CONF_TOUCH" ]; then
    mkdir -p $HOME/.fvwm/cfg
    echo creating: $HOME/.fvwm/cfg/xvkbd.cfg
    cat <<HEREDOC > $HOME/.fvwm/cfg/xvkbd.cfg
Exec exec xvkbd -minimizable -compact -geometry 1000x300+0-0
HEREDOC
  fi
fi

mkdir -p $HOME/.fvwm/screenshot

if [ -d $HOME/bin/shellscripts ]; then
  ln -s $HOME/bin/shellscripts/config/vim/_vimrc $HOME/_vimrc
  mkdir -p $HOME/.vim/colors $HOME/.vim/ftplugin
  mkdir -p  $HOME/.vim/pack/git-plugins/start
  if [ -n "`which alacritty`" ]; then
    mkdir -p $HOME/.config/alacritty
    if [ ! -e $HOME/.config/alacritty/alacritty.toml ]; then
      ln -s $HOME/bin/shellscripts/config/alacritty.toml $HOME/.config/alacritty
    fi
  fi
  if [ ! -d $HOME/.vim/pack/git-plugins/start/ale ]; then
    git clone --depth 1 https://github.com/dense-analysis/ale.git \
      $HOME/.vim/pack/git-plugins/start/ale
  fi
  if [ ! -d $HOME/.vim/pack/git-plugins/start/vim-airline ]; then
    git clone --depth 1 https://github.com/vim-airline/vim-airline \
      $HOME/.vim/pack/git-plugins/start/vim-airline
  fi

  ln -s $HOME/bin/shellscripts/config/vim/colors/rusty.vim $HOME/.vim/colors
  ln -s $HOME/bin/shellscripts/config/vim/ftplugin/asm.vim $HOME/.vim/ftplugin
  ln -s $HOME/bin/shellscripts/config/vim/ftplugin/rust.vim $HOME/.vim/ftplugin
  ln -s $HOME/bin/shellscripts/config/vim/ftplugin/text.vim $HOME/.vim/ftplugin
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
  if [ ! -e $HOME/.fvwm/layout.fvwm ]; then
    cp $HOME/bin/shellscripts/config/layout.fvwm $HOME/.fvwm/layout.fvwm
  fi

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
