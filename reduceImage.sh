# Maintained at: git@github.com:dareni/shellscripts.git
EXT=${1##*.}
FILENAME=${1%%.*}
#quality is compression level and has different meaning across image types.
#jpg 1=low quality high compression, 100=high quality no compression.
# jpg is always lossy. png is lossless.
#convert -geometry 682x511 -quality 50 $1 ${FILENAME}_r.${EXT} 
convert -resize 50% $1 ${FILENAME}_r.${EXT} 


#To convert an image to pdf the -density sets the dpi relative to other pages 
#in the document.
# eg convert orig.jpg  -units PixelsPerInch -density 120 book.pdf
