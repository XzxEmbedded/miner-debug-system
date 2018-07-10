#!/bin/bash

for i in `cat $2/$3`
do
    str=$i','
    echo $str | awk '{ printf $1 }' >> $2/temp.txt
done

cat $2/temp.txt | sed 's/.$/\n/' >> $2/power.csv
rm -rf $2/temp.txt
