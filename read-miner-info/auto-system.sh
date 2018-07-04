#!/bin/bash
# Author March 2018 xuzhenxing <xuzhenxing@canaan-creative.com>

usr_name=`who | awk '{ print $1 }'`

# Create result.csv
echo "Freq,Volt-level,Vcore,GHSmm,Temp,TMax,WU,GHSav,Power,Power/GHSav,DH,DNA" > miner-result.csv

# Openwrt python IP address
P_IP=`cat ip-freq-voltlevel.config | grep 'Power-IP' | awk '{ print $2 }'`
[ -z ${P_IP} ] && exit
ssh-keygen -f "/home/${usr_name}/.ssh/known_hosts" -R ${P_IP} > /dev/null

# Openwrt cgmienr IP address
C_IP=`cat ip-freq-voltlevel.config | grep 'CGMiner-IP' | awk '{ print $2 }'`
[ -z ${C_IP} ] && exit
ssh-keygen -f "/home/${usr_name}/.ssh/known_hosts" -R ${C_IP} > /dev/null
./scp-login.exp ${C_IP} 0
sleep 3

# Create result directory
dirip="result-"${C_IP}
mkdir ${dirip}

# Config /etc/config/cgminer and restart cgminer, Get Miner debug logs
cat ip-freq-voltlevel.config | grep avalon |  while read tmp
do
    more_options=`cat cgminer | grep more_options`
    if [ "${more_options}" == "" ]; then
        echo "option more_options" >> cgminer
    fi

    more_options=`cat cgminer | grep more_options`
    sed -i "s/${more_options}/	option more_options '${tmp}'/g" cgminer

    # Cp cgminer to /etc/config
    ./scp-login.exp ${C_IP} 1
    sleep 3

    # CGMiner restart
    ./ssh-login.exp ${C_IP} /etc/init.d/cgminer restart
    sleep 30

    # Read AvalonMiner Power
    ./ssh-read-power.py ${P_IP}
    sleep 1

    # Copy remote power file
    ./scp-login.exp ${P_IP} 2 > /dev/null
    sleep 3

    # SSH no password
    ./ssh-login.exp ${C_IP} cgminer-api "debug\|D" > /dev/null
    sleep 1
    ./ssh-login.exp ${C_IP} cgminer-api estats estats.log > /dev/null
    ./ssh-login.exp ${C_IP} cgminer-api edevs edevs.log > /dev/null
    ./ssh-login.exp ${C_IP} cgminer-api summary summary.log > /dev/null

    # Read CGMiner Log
    ./read-debuglog.sh ${tmp}
done

more_options_flag=`cat ip-freq-voltlevel.config | grep avalon`
# more options is null
if [ -z "${more_options_flag}" ]; then
    more_options=`cat cgminer | grep more_options`
    tmp=`echo ${more_options#*more_options} | sed "s/'//g"`

    # Read AvalonMiner Power
    ./ssh-read-power.py ${P_IP}
    sleep 1

    # Copy remote power file
    ./scp-login.exp ${P_IP} 2 > /dev/null
    sleep 3

    # SSH no password
    ./ssh-login.exp ${C_IP} cgminer-api estats estats.log > /dev/null
    debug=`cat estats.log | grep PVT`
    if [ -z "${debug}" ]; then
        ./ssh-login.exp ${C_IP} cgminer-api "debug\|D" > /dev/null
        sleep 1
        rm estats.log
        ./ssh-login.exp ${C_IP} cgminer-api estats estats.log > /dev/null
    fi

    sleep 1
    ./ssh-login.exp ${C_IP} cgminer-api edevs edevs.log > /dev/null
    ./ssh-login.exp ${C_IP} cgminer-api summary summary.log > /dev/null

    # Read CGMiner Log
    ./read-debuglog.sh ${tmp}
fi

# Remove cgminer file
rm cgminer
