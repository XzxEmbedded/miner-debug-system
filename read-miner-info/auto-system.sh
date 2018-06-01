#!/bin/bash
#
# Author March 2018 xuzhenxing <xuzhenxing@canaan-creative.com>
#
# Input paramter is rpi's IP address
#

# Create result directory
[ -z $1 ] && exit
IP=$1
dirip="result-"$IP
mkdir $dirip

ssh-keygen -f "/home/pi/.ssh/known_hosts" -R $IP
./scp-login.exp $IP $dirip 0
sleep 3

# Create result.csv
echo "Freq,Volt-level,Vcore,GHSmm,Temp,TMax,WU,GHSav,Power,Power/GHSav,DH,DNA" > ./$dirip/miner-result.csv

# Config /etc/config/cgminer and restart cgminer, Get Miner debug logs
cat ip-freq-voltlevel-devid.config | grep avalon |  while read tmp
do
    more_options=`cat ./$dirip/cgminer | grep more_options`
    if [ "$more_options" == "" ]; then
        echo "option more_options" >> ./$dirip/cgminer
    fi

    more_options=`cat ./$dirip/cgminer | grep more_options`
    sed -i "s/$more_options/	option more_options '$tmp'/g" "./$dirip/cgminer"

    # Cp cgminer to /etc/config
    ./scp-login.exp $IP $dirip 1
    sleep 3

    # CGMiner restart
    ./ssh-login.exp $IP /etc/init.d/cgminer restart
    sleep 30

    # Read AvalonMiner Power
    ./read-power.py $IP

    # SSH no password
    ./ssh-login.exp $IP cgminer-api "debug\|D" > /dev/null
    sleep 1
    ./ssh-login.exp $IP cgminer-api estats ./$dirip/estats.log > /dev/null
    ./ssh-login.exp $IP cgminer-api edevs  ./$dirip/edevs.log > /dev/null
    ./ssh-login.exp $IP cgminer-api summary ./$dirip/summary.log > /dev/null

    # Read CGMiner Log
    ./read-debuglog.sh $IP $tmp
done

# Remove cgminer file
rm ./$dirip/cgminer
