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

PATH=$HOME/bin/shellscripts:/sbin:~/bin:$PATH:/usr/sbin:/opt/dev/apache-maven/bin
JDK_NO=8
. jdkenv
export PATH

EDITOR=vi
export EDITOR
WINEPREFIX=/opt/game/WINE
export WINEPREFIX
NETBEANS_TMP=/store/tmp
export NETBEANS_TMP

. "$HOME/.cargo/env"

