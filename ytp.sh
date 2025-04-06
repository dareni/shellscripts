URL=`xclip -selection c -o`
echo $URL
#yt-dlp $URL -f "bv.1+ba.1" --exec after_move:mpv -o $XDG_RUNTIME_DIR/"%(title)s [%(id)s].%(ext)s"
#No better than 720 res.
#yt-dlp $URL -f "bv*[filesize<1G]+ba/b"  --exec after_move:mpv -N 2 -o $XDG_RUNTIME_DIR/"%(title)s [%(id)s].%(ext)s"
AUDIO_FILE=$XDG_RUNTIME_DIR/ytp.audio
VIDEO_FILE=$XDG_RUNTIME_DIR/ytp.video

rm $AUDIO_FILE $VIDEO_FILE

yt-dlp $URL -f  "ba/b"  -N 2 --force-overwrites --no-part -o $AUDIO_FILE&
yt-dlp $URL -f  "bv*[filesize<1G]" -N 2 --force-overwrites --no-part -o $VIDEO_FILE&
COUNT=0
while [ ! -s $VIDEO_FILE  -a $COUNT -lt 10 ];
do
  COUNT=$((COUNT+1));
  sleep 1;
done;

mpv $VIDEO_FILE --audio-file=$AUDIO_FILE --save-position-on-quit
