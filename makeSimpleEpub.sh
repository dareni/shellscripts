makeEpubCss() {
cat <<HEREDOC > $EPUB_CSS
/* This defines styles and classes used in the book */
body { margin: 5%; text-align: justify; font-size: medium; }
code { font-family: monospace; }
h1 { text-align: left; }
h2 { text-align: left; }
h3 { text-align: left; }
h4 { text-align: left; }
h5 { text-align: left; }
h6 { text-align: left; }
h1.title { }
h2.author { }
h3.date { }
ol.toc { padding: 0; margin-left: 1em; }
ol.toc li { list-style-type: none; margin: 0; padding: 0; }
a.footnote-ref { vertical-align: super; }
em, em em em, em em em em em { font-style: italic;}
em em, em em em em { font-style: normal; }
.aligncenter { text-align:center; }
.small { font-size: small; };
HEREDOC
}

FRONT_COVER=front.png
EPUB_CSS="epub.css"
METADATA="metadata.txt"

if [ ! -e "$METADATA" ]; then
  read -p "What is the title? " B_TITLE
  read -p "What is the author? " B_AUTHOR
echo -e "---\ntitle: $B_TITLE\nauthor: $B_AUTHOR\nlang: en-US\ncover-image: $FRONT_COVER\n---" > $METADATA
#echo -e "---\ntitle:\n- type: main\n  text: $B_TITLE\ncreator:\n- role: author:\n  text: $B_AUTHOR\nlanguage: en-US\n..." > $METADATA
#echo -e "<title>$B_TITLE</title>\n<dc:creator>$B_AUTHOR</dc:creator>\n<dc:language>en-US</dc:language>" > $METADATA

fi

if [ ! -e ./$EPUB_CSS ]; then
  makeEpubCss
fi

#pandoc -f html -t epub2 --css=./$EPUB_CSS   -o book.epub  --epub-cover-image=$FRONT_COVER --metadata-file=$METADATA book.html
#echo pandoc -f html -t epub3 --css=./$EPUB_CSS   -o book.epub  --epub-cover-image=$FRONT_COVER $METADATA book.html
#pandoc -f html -t epub3 --css=./$EPUB_CSS   -o book.epub  --epub-cover-image=$FRONT_COVER $METADATA book.html

echo pandoc -o book.epub -f html -t epub --metadata-file=$METADATA book.html
pandoc -o book.epub -f html -t epub --metadata-file=$METADATA book.html

