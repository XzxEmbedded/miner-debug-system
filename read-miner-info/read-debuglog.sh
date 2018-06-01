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
avg_int=0
avg_float2=0.00
avg_float3=0.000

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

# Calculate integer average
calc_int_avg() {
    avg_int=0
    s_int=0
    c_int=0

    for l in `cat $1`
    do
        let s_int=s_int+$l
        let c_int=c_int+1
    done

    let avg_int=${s_int}/${c_int}
}

calc_float2_avg() {
    avg_float2=0.00
    s_float2=0.00
    c_float2=0

    for m in `cat $1`
    do
	s_float2=$(echo "scale=2; ${s_float2} / $m" | bc)
        let c_float2=c_float2+1
    done

    avg_float2=$(echo "scale=2; ${s_float2} / ${c_float2}" | bc)
}

calc_float3_avg() {
    avg_float3=0.000
    s_float3=0.000
    c_float3=0

    for n in `cat $1`
    do
	s_float3=$(echo "scale=3; ${s_float3} / $n" | bc)
        let c_float3=c_float3+1
    done

    avg_float3=$(echo "scale=3; ${s_float3} / ${c_float3}" | bc)
}

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

    # GHSmm average
    calc_float2_avg $i.GHSmm
    echo "${avg_float2}" > ghsmm-avg.log

    # Temp average
    calc_int_avg $i.Temp
    echo "${avg_int}" > temp-avg.log

    # TMax average
    calc_int_avg $i.TMax
    echo "${avg_int}" > tmax-avg.log

    # WU average
    calc_float2_avg $i.WU
    echo "${avg_float2}" > wu-avg.log

    # GHSav average
    calc_float2_avg $i.GHSav
    echo "${avg_float2}" > ghsav-avg.log

    # Power average
    calc_int_avg $Power
    echo "${avg_int}" > power-avg.log

    # Power/GHSav average
    calc_float3_avg ph.log
    echo "${avg_float3}" > ph-avg.log

    # DH average
    calc_float2_avg $i.DH
    echo "${avg_float2}" > dh-avg.log

    paste -d, freq.log voltage.log vcore.log $i.GHSmm $i.Temp $i.TMax $i.WU $i.GHSav $Power ph.log $i.DH $i.DNA >> ${Result#.log}.csv
    paste -d, freq.log voltage.log vcore.log ghsmm-avg.log temp-avg.log tmax-avg.log wu-avg.log ghsav-avg.log power-avg.log ph-avg.log dh-avg.log >> ${Result#.log}.csv
    echo "" >> ${Result#.log}.csv
    cat *.csv >> ../miner-result.csv

    rm -rf $i.GHSmm $i.Temp $i.TMax $i.WU $i.GHSav $i.DH $i.DNA ph.log freq.log voltage.log vcore.log
    rm -f ghsmm-avg.log temp-avg.log tmax-avg.log wu-avg.log ghsav-avg.log power-avg.log ph-avg.log dh-avg.log

    cd ..
    mv ./$dirname ./result*
done
