#!/bin/bash

fileName=$(hostname)_ufwlogs_$(date +"%Y-%m-%d_%T")          # File name will be "hostname_ufwlogs_date_time.csv" 
extractDayCount=7                                           # the amount of days to extract from the system log

formatCSV () {
    echo "Separating Dates from data into 1st column"
    perl -i -pe 's/^(.{15}).{1}/\1;/g' $1                           # Separates date
    echo "Separating Dates app and machine names into 2nd column"
    perl -i -pe 's/([^:]*:[^:]*:[^:]*):/\1;/g' $1                   # Separates apps and machine name
    echo "Pruning rouge delimiters"
    sed -i 's/;/:/3g' $1                                            # Plucks out any remaining delimiters and replaces them with a ':'
    echo "Formatting UFW Data"
    sed -i 's/ /;/7g' $1                                           # puts data in its own columns
} # end formatCSV()

echo "Delimiter is ';'"                                   # Notifies about Hard Coded Delimiter

extractLogs () {
    i=0
    exitCode=1
    # find the first boot that happend on that day
    while [[ $i -gt -29 ]] && [[ $exitCode -ne 0 ]] ; do
        i=$(($i-1))
        output="$(journalctl -k -b $i -o short --no-pager | grep "$(date --date="$1 days ago" "+%b %d")")"
        exitCode=$?
    done
    # find the last boot that happend on that day
    while [[ $i -gt -29 ]] && [[ $exitCode -ne 1 ]] ; do
        i=$(($i-1))
        output=$(journalctl -k -b $i -o short --no-pager | grep "$(date --date="$1 days ago" "+%b %d")")
        exitCode=$?
    done
    echo "Date;Kernel Time;Event Type;In NIC; Out NIC;Offending NIC MAC;Source;Destination" > $2
    while [[ $i -ne 1 ]] ; do
        journalctl -k -b $i -o short-precise -g "ufw" --no-pager >> $2
        i=$(($i+1))
    done
    
}

#journalctl -k -b -13 -o short-precise --no-pager | grep "$(date --date="7 days ago" "+%b %d")"


echo "Extracting $extractDayCount Days of logs"
#journalctl -k -g "ufw" -S "$extractDayCount days ago" --no-pager > ./$fileName.csv   # detects all Firewall events
extractLogs $extractDayCount ./$fileName.csv
formatCSV ./$fileName.csv
echo "File saved as $fileName.csv"
