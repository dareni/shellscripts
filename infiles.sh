#!/bin/bash
for f in `find . -name "$1"`; 
do  
    count=`grep -c $2 $f;`
    if [[ $count -gt 0 ]]; then
        echo  $f
    fi
done;
