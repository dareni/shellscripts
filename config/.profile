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
JDK_NO=8
. jdkenv

function zones() {
  egrep 'Paris|Istanbul|London|Athens|New_York|Los_Angeles|Chicago|Denmark|Brisbane' < /usr/share/zoneinfo/zone.tab |\
  while read TZONE; do
    TZ=`echo $TZONE| cut -d" " -f3`
    export TZ
    CDATE=`date`
    printf "%-19s %s\n" $TZ "$CDATE"
  done;

  export TZ=Australia/Brisbane
}

alias music='ls -1 |sort -R |while read song; do mpv "$song"; done;'
alias scan='nmap -v -sn 192.168.1.0/24'
