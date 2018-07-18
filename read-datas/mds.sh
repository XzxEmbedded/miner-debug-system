#!/bin/bash
#
# Author June 2018 Zhenxing Xu <xuzhenxing@canaan-creative.com>
#

# Get delay times
time=`cat miner-options.conf | grep TIME | awk '{ print $2 }'`

# Get RPI's IP
cat miner-options.conf | awk 'NR > 3' | while read tmp
do
    if [[ -z $tmp ]]; then
	break;
    fi
    ./mdssub.sh $time $tmp &
    sleep 5
done

while true
do
    cnt=`ps -ef | grep './mdssub.sh' | wc -l`
    if [ $cnt -le '1' ]; then
	echo -e "\033[1;32m++++++++++++++++++++++++++++++  Done   ++++++++++++++++++++++++++++++\033[0m"
	break
    fi

    sleep 5
    echo "++++++++++++++++++++++++++++++ Running ++++++++++++++++++++++++++++++"
done
