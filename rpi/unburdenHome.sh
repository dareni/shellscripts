#!/usr/bin/env sh
# Maintained at: git@github.com:dareni/shellscripts.git
#
# Configure rpi for minimal disk write.
# Call this file from .profile eg:
# . ~/bin/shellscripts/unburdenHome.sh

if [ ! -e "$HOME"/.unburden-home-dir ]; then
  cat  <<confEOF  >> "$HOME"/.unburden-home-dir
UNBURDEN_HOME=yes
TARGETDIR=$XDG_RUNTIME_DIR
FILELAYOUT='unburden/%s'
confEOF

  cat  <<confEOF  >> "$HOME"/.unburden-home-dir.list
d f .bash_history bash_history
d d .cache cache
m f .local/share/luakit/command-history lua.command-history
d d .local/share/luakit/local_storage lua.local_storage
d d .local/share/luakit/indexeddb lua.indexeddb
confEOF
fi

unburden-home-dir

trap unburden EXIT SIGTERM SIGHUP SIGKILL SIGABRT
function unburden () {
  rm $HOME/.bash_history
  rm -rf $XDG_RUNTIME_DIR/unburden/cache/*
  unburden-home-dir -u
}

