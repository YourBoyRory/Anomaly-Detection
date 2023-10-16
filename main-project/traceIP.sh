#!/bin/bash
storeFile="./ipAddr.csv"
tmpFile="./ipAddr.tmp"

traceIP() {
    whois=$(whois $1)
    echo $whois
    #country=$(
    echo $whois | grep -oP '^Country:        \K.*' | tail -1 #)
    #state=$(
    echo $whois | grep -oP '^StateProv:        \K.*' | tail -1 #)
    #city=$(
    echo $whois | grep -oP '^City:        \K.*' | tail -1 #)
    if [[ "$country" == "" ]] ; then
        echo "UNKNOWN,$state,$city,$1"
        #echo "$1,UNKNOWN" >> $storeFile
    else
        echo "$country,$state,$city,$1"
        echo "$country,$state,$city,$1" >> $storeFile
    fi 
}

getIP() {
    lineCount=$(wc -l $1 | awk '{print $1}')
    currIP=$(echo $(head -n1 $1 | tail -n1) | grep -oP 'SRC=\K.*' | cut -d, -f1)
    echo $currIP >> $tmpFile
    i=2
    while [[ $i -ne $lineCount ]] ; do
        currIP=$(echo $(head -n$i $1 | tail -n1) | grep -oP 'SRC=\K.*' | cut -d, -f1)
        cat $tmpFile | grep -w "$currIP" >> /dev/null
        doStore=$?
        if [[ $doStore -ne 0 ]] ; then 
            echo $currIP | grep "192.168.1" >> /dev/null
            isLocal=$?
            if [[ $isLocal -eq 0 ]] ;then
                echo "LOCAL,,,$currIP"
                #echo "$currIP,LOCAL" >> $storeFile
            else
                traceIP "$currIP"
            fi
            echo "$currIP" >> $tmpFile
        fi
        i=$(($i+1))
    done
}
rm $storeFile
rm $tmpFile
getIP "./Events.csv" 
rm $tmpFile
