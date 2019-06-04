#!/bin/sh

DIR=~/tmp
mkdir -p $DIR
COUNTER=$DIR/count
touch $COUNTER
COUNT=`cat $COUNTER`
COUNT=$(($COUNT+1))
#import -window root -quality 100 -crop 850x719+389+122 $DIR/$COUNT.jpg
#import -window root -quality 100 -crop 850x719+395+122 $DIR/$COUNT.jpg
#import -window root -quality 100 -crop 850x719+400+122 $DIR/$COUNT.jpg
#import -window root -quality 100 -crop 850x719+405+122 $DIR/$COUNT.jpg
#import -window root -quality 100 -crop 850x719+410+122 $DIR/$COUNT.jpg
#import -window root -quality 100 -crop 850x719+415+122 $DIR/$COUNT.jpg
import -window root -quality 100 -crop 850x719+420+122 $DIR/$COUNT.jpg

echo $COUNT > $COUNTER
