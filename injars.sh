#!/bin/bash
for f in `find . -name "*.jar"`; 
do  
    #echo $f
    count=`jar -tvf $f | grep -c $1 ;`
    if [[ $count -gt 0 ]]; then
        echo  $f
    fi
done;
