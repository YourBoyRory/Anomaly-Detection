#!/bin/bash
storeFile="./ipAddrLoc.csv"
storeAddr="./ipAddr.csv"
sedTmp="/tmp/sed.tmp"
whoisTmp="/tmp/whois.tmp"

filterIP() {
    isLocal=1
    if ( echo "$1" | grep "$(echo $2 | awk -F '.' '{print $1"."$2"."}')" >> /dev/null ) ;then 
        isLocal=0
    elif [[ "$1" == "127.0.0.1" ]] ; then
        isLocal=0
    elif [[ "$2" == "224.0.0.1" ]] ; then
        isLocal=0
    elif [[ "$1" == "0.0.0.0" || "$1" ==  "0000:0000:0000:0000:0000:0000:0000:0000" ]] ; then
        isLocal=0
    fi
}

traceIP() {
    filterIP "$1" "$2"
    if [[ $isLocal -eq 0 ]] ;then
        echo -e "LOCAL" 
    else
        whois $1 > $whoisTmp
        country=$(cat $whoisTmp | grep -oP '^Country:        \K.*' | tail -1 )
        if [[ "$country" == "" ]] ; then
            echo -e "UNKNOWN"
        else
            echo -e "$country"
        fi 
    fi 
}

storeIP() {
    filterIP "$1" "$2"
    if [[ $isLocal -eq 0 ]] ;then
        echo -e "\"$1\",\"1\",\"LOCAL\",\"LOCAL\",\"LOCAL\",\"LOCAL\"" >> $storeAddr
    else
        country=$(cat $whoisTmp | grep -oP '^Country:        \K.*' | tail -1 )
        state=$(cat $whoisTmp | grep -oP '^StateProv:      \K.*' | tail -1 )
        city=$(cat $whoisTmp | grep -oP '^City:           \K.*' | tail -1 )
        org=$(cat $whoisTmp | grep -oP '^OrgName:        \K.*' | tail -1 )
        if [[ "$country" == "" ]] ; then
            echo -e "\"$1\",\"1\",\"UNKNOWN\",\"UNKNOWN\",\"UNKNOWN\",\"UNKNOWN\"" >> $storeAddr
        else
            echo -e "\"$1\",\"1\",\"$org\",\"$city\",\"$state\",\"$country\"" >> $storeAddr
        fi 
    fi 
}

dispTraceIP() {
    country=$(cat $storeAddr | grep -w "$1" | awk -F  '","' '{print $6}' | rev | cut -c 2- | rev)
    state=$(cat $storeAddr | grep -w "$1" | awk -F  '","' '{print $5}')
    city=$(cat $storeAddr | grep -w "$1" | awk -F  '","' '{print $4}')
    org=$(cat $storeAddr | grep -w "$1" | awk -F  '","' '{print $3}')
    even=$(cat $storeAddr | grep -w "$1" | awk -F  '","' '{print $2}')
    if [[ "$country" == "LOCAL" ]] ;then
        echo -e "\e[1A\e[K$2 \033[0m$1:\033[1m $even $org\033[0m"
    elif [[ "$country" == "UNKNOWN" ]] ; then
        echo -e "\e[1A\e[K$2 \033[0;31m$1:\033[1;31m $even $org\033[0m"
    else
        echo -e "\e[1A\e[K$2 \033[0;33m$1:\033[1;33m $even $org - $city, $state, $country\033[0m"
    fi 
}

getIP() {
    echo "Starting..."
    echo "Loc,Events" > $storeFile
    echo "LOCAL,0" >> $storeFile
    echo "UNKNOWN,0" >> $storeFile
    echo "Addr,Events,Org,City,State,Country" > $storeAddr
    lineCount=$(wc -l $1 | awk '{print $1}')
    i=2
    while [[ $i -ne $lineCount ]] ; do
        currIP=$(echo $(head -n$i $1 | tail -n1) | grep -oP 'SRC=\K.*' | cut -d, -f1)
        currDST=$(echo $(head -n$i $1 | tail -n1) | grep -oP 'DST=\K.*' | cut -d, -f1)
        newIP=$(cat $storeAddr | grep -w "$currIP")
        if [[ "$newIP" == "" ]] ; then
            currLoc=$(traceIP "$currIP" "$currDST")
            storeIP "$currIP" "$currDST"
        else
            currLoc=$(cat $storeAddr | grep -w "$currIP" | awk -F  '","' '{print $6}' | rev | cut -c 2- | rev)
            addrNum=$(cat $storeAddr | grep -w "$currIP" | awk -F  '","' '{print $2}')
            findString="\"$currIP\",\"$addrNum\","
            replaceString="\"$currIP\",\"$(($addrNum+1))\","
            sed "s/$findString/$replaceString/g" "$storeAddr" > $sedTmp
            cat $sedTmp > $storeAddr
        fi
        locNum=$(cat $storeFile | grep -w "$currLoc" | awk -F  ',' '{print $2}')
        if [[ $locNum != "" ]] ; then 
            findString="$currLoc,$locNum"
            replaceString="$currLoc,$(($locNum+1))"
            sed "s/$findString/$replaceString/g" "$storeFile" > $sedTmp
            cat $sedTmp > $storeFile
        else
            echo "$currLoc,1" >> $storeFile
        fi
        dispTraceIP "$currIP" "[$(($i-1))/$lineCount]"
        i=$(($i+1))
    done
    echo -e "\e[1A\e[KDone!"
}

getIP "./Events*.csv" 
