# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

#[ "$(tty)" = "/dev/tty1" ] && exec startx

PATH=$HOME/bin/shellscripts:/sbin:~/bin:$PATH
JDK_NO=11
. jdkenv
export PATH

EDITOR=vi
export EDITOR
WINEPREFIX=/opt/game/WINE
export WINEPREFIX

_JAVA_OPTIONS=-Djava.io.tmpdir=/store/tmp
export _JAVA_OPTIONS

if [ -d "/opt/dev/apache-maven/bin" ]; then
  export PATH="$PATH:/opt/dev/apache-maven/bin"
fi

if [ -d "/opt/dev/apache-ant/bin" ]; then
  export ANT_HOME=/opt/dev/apache-ant
  export PATH="$PATH:$ANT_HOME/bin"
fi


if [ -d "$HOME/.cargo" ]; then
  #Rust config
  . "$HOME/.cargo/env"
  alias ra='rustup run nightly rust-analyzer'
  #alias grep='~/.cargo/bin/rg'
fi

