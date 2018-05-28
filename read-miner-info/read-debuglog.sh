#!/bin/bash

IP=`cat ip-freq-voltlevel-devid.config | sed -n '2p' | awk '{ print $1 }'`
DATE=`date +%Y%m%d%H%M`
dirname=$IP"-"$DATE"-"$2"-"$4"-"$6"-"$8
mkdir $dirname

cat estats.log  | grep "\[MM ID" > ./$dirname/CGMiner_Debug.log
cat edevs.log | grep -v Reply  > ./$dirname/CGMiner_Edevs.log
cat summary.log | grep -v Reply  > ./$dirname/CGMiner_Summary.log

rm estats.log edevs.log summary.log
mv CGMiner_Power.log ./$dirname
cd ./$dirname

sum=0

for i in `cat CGMiner_Debug.log | sed 's/] /\]\n/g' | grep "PVT_V" | awk '{ print $3 }'`
do
    if [ "$i" != "0" ]; then
         let sum=sum+$i
         let cnt=cnt+1
   fi
done
let avg=$sum/$cnt
echo $avg > vcore.log

echo "$2" > freq.log
echo "$4" > voltage.log

for i in CGMiner_Debug.log
do
    cat $i | sed 's/] /\]\n/g' | grep "GHSmm\[" | sed 's/GHSmm\[//g' | sed 's/\]//g' > $i.GHSmm
    cat $i | sed 's/] /\]\n/g' | grep Temp  | sed 's/Temp\[//g'  | sed 's/\]//g' > $i.Temp
    cat $i | sed 's/] /\]\n/g' | grep TMax  | sed 's/TMax\[//g'  | sed 's/\]//g' > $i.TMax
    cat $i | sed 's/] /\]\n/g' | grep WU    | sed 's/WU\[//g'    | sed 's/\]//g' > $i.WU
    cat $i | sed 's/] /\]\n/g' | grep DH    | sed 's/DH\[//g'    | sed 's/\]//g' > $i.DH
    cat $i | sed 's/] /\]\n/g' | grep DNA   | sed 's/DNA\[//g'   | sed 's/\]//g' > $i.DNA

    # According to WU value, calculate GHSav.
    # Formula: ghsav = WU / 60 * 2^32 / 10^9
    # Formula: WU = ghsav * 10^9 * 60 / 2^32 * 100
    cat $i.WU | awk '{printf ("%.2f\n", ($1/60*2^32/10^9))}' > $i.GHSav

    Power=CGMiner_Power.log
    Result=Results_$dirname

    # Power ratio
    paste $i.GHSav $Power | awk '{printf ("%.3f\n", ($2/$1))}' > ph.log

    paste -d, freq.log voltage.log vcore.log $i.GHSmm $i.Temp $i.TMax $i.WU $i.GHSav $Power ph.log $i.DH $i.DNA >> ${Result#.log}.csv
    cat *.csv >> ../miner-result.csv

    rm -rf $i.GHSmm $i.Temp $i.TMax $i.WU $i.GHSav $i.DH $i.DNA ph.log freq.log voltage.log vcore.log

    cd ..
    mv ./$dirname ./result*
done
