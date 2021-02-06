# Maintained at: git@github.com:dareni/shellscripts.git

# copy tracks from an audio compact disk (cdda).

if [ ! -x "`which cdparanoia`" ]; then
  echo Please install cdparanoia.
  exit
fi

if [ -z "$1" ]; then
  echo Please enter track number.
  echo eg rip track 9:  ./ripCdda.sh 9
  cdparanoia -Q
  exit
fi
cdparanoia $@
stripAudio.sh *wav

