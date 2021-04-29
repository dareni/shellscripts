# Example parse of html file.
#novel
#12
#com
rm book.html

for FILE in `ls -v *htm`; do
  FILENOPATH="${FILE##*/}"
  FILENOEXT="${FILENOPATH%.*}"
  xmllint  -html -recover $FILE | xmllint -html -xpath "//html/body/section/div [@class='container']/div [@class='row']/div/div/div [@class='content-center wl']/node()" -  | \
  sed -e 's^<p>\*\*\*.*<\/p>^^g' | \
  sed -e 's^^^g' | \
  sed -e 's^\s*<br>^<br>^g' | \
  sed -e 's^\^\s*^^g' | \
  sed -e 's^<p>^^g' | \
  sed -e 's^</p>^^g' | \
  sed -e 's^\(Chapter [0-9I]\{1,2\}\)^<h1>\1</h1>^Ig' | \
  tail +4 | \
  head -n -4 |\
  awk '
  BEGIN{
    br=0; IGNORECASE=1;
  }
  {
    if (length($0) <= 0) {
      nop
    }else{
      if($0 == "<br>") {
        nop
      } else {
        line = $0
        gsub(/<br>/, "", $line)
        test=line
        gsub(/\s/, "", test)
        if (length(test) > 1 ) {
          print "<p>"$line"</p>"
        }
      }
    }
  }' \
  >> book.html
done

