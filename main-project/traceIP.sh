#!/bin/bash
storeFile="./ipAddr.csv"
tmpFile="./ipAddr.tmp"

traceIP() {
    echo "$1" | grep "192.168.1" >> /dev/null
    isLocal=$?
    if [[ $isLocal -eq 0 ]] ;then
        echo -e "LOCAL" 
    else
        country=$(whois $1 | grep -oP '^Country:        \K.*' | tail -1 )
        if [[ "$country" == "" ]] ; then
            echo -e "UNKNOWN"
        else
            echo -e "$country"
        fi 
    fi 
}

dispTraceIP() {
    whoisTmp="/tmp/whois.tmp"
    echo "$1" | grep "192.168.1" >> /dev/null
    isLocal=$?
    if [[ $isLocal -eq 0 ]] ;then
        echo -e "\033[0m$1:\033[1m LOCAL\033[0m"
    else
        whois $1 > $whoisTmp
        country=$(cat $whoisTmp | grep -oP '^Country:        \K.*' | tail -1 )
        state=$(cat $whoisTmp | grep -oP '^StateProv:      \K.*' | tail -1 )
        city=$(cat $whoisTmp | grep -oP '^City:           \K.*' | tail -1 )
        org=$(cat $whoisTmp | grep -oP '^OrgName:        \K.*' | tail -1 )
        if [[ "$country" == "" ]] ; then
            echo -e "\033[0;31m$1:\033[1;31m UNKNOWN\033[0m"
        else
            echo -e "\033[0;33m$1:\033[1;33m $org - $city, $state, $country\033[0m"
        fi 
    fi 
}

getIP() {
    echo "LOCAL,0" > $storeFile
    echo "UNKNOWN,0" >> $storeFile
    rm $tmpFile 2> /dev/null
    lineCount=$(wc -l $1 | awk '{print $1}')
    currIP=$(echo $(head -n1 $1 | tail -n1) | grep -oP 'SRC=\K.*' | cut -d, -f1)
    echo $currIP >> $tmpFile
    i=2
    while [[ $i -ne $lineCount ]] ; do
        currIP=$(echo $(head -n$i $1 | tail -n1) | grep -oP 'SRC=\K.*' | cut -d, -f1)
        newIP=$(cat $tmpFile | grep -w "$currIP")
        
        if [[ "$newIP" == "" ]] ; then
            currLoc=$(traceIP "$currIP")
            echo "$currIP $currLoc 1" >> $tmpFile
            dispTraceIP "$currIP"
        else
            currLoc=$(echo $newIP | awk '{print $2}')
            currNum=$(echo $newIP | awk '{print $3}')
            
            replaceString="$currIP $currLoc $(($currNum+1))"
            sed -i "s/$newIP/$replaceString/g" "$tmpFile"
        fi
        locNum=$(cat $storeFile | grep -w "$currLoc" | awk -F  ',' '{print $2}')
        if [[ $locNum != "" ]] ; then 
            findString="$currLoc,$locNum"
            replaceString="$currLoc,$(($locNum+1))"
            sed -i "s/$findString/$replaceString/g" "$storeFile"
        else
            echo "$currLoc,1" >> $storeFile
        fi
        i=$(($i+1))
    done
    rm $tmpFile
}

getIP "./Events.csv" 
