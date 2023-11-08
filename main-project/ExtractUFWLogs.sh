#!/bin/bash

#fileName="$(hostname)_ufwlogs_$(date +"%Y-%m-%d_%T").csv"          # File name will be "hostname_ufwlogs_date_time.csv" 
fileName=Events.csv
tempFile=Events.tmp
extractDayCount=7                                           # the amount of days to extract from the system log

formatCSV () {
    echo "Separating Dates from data into 1st column"
    perl -i -pe 's/^(.{27}).{1}/\1,/g' $1                           # Separates date
    echo "Separating app and machine names into 2nd column"
    perl -i -pe 's/([^:]*:[^:]*:[^:]*):/\1,/g' $1                   # Separates apps and machine name
    echo "Separating event type into 3nd column"
    sed -i 's/]/],/' $1
    echo "Pruning rouge delimiters"
    sed -i 's/,/:/4g' $1                                            # Plucks out any remaining delimiters and replaces them with a ':'
    echo "Pruning Irrelevant Information"
    perl -ni -e 'print unless /^-- No entries --$/;' $1
    echo "Setting column titles"
    echo "Time Created, Kernel, Event Type, In, Out, Mac, Source, Destination, Length, TOS, PREC, TTL, ID, Source Port, Destination Port " > $2
    echo "Formatting UFW Data"
    makeCSV $1 $2
} # end formatCSV()

makeCSV () {
    lineCount=$(wc -l $1 | awk '{print $1}')
    i=1
    while [[ $i -ne $lineCount ]] ; do
        HEAD=$(echo $(head -n3 $1 | tail -n1) | awk -F  ',' '{print $1"\",\""$2"\",\""$3}')
        IN=$(echo $(head -n3 $1 | tail -n1) | grep -oP 'IN=.*' | cut -d' ' -f1)
        OUT=$(echo $(head -n3 $1 | tail -n1) | grep -oP 'OUT=.*' | cut -d' ' -f1)
        MAC=$(echo $(head -n3 $1 | tail -n1) | grep -oP 'MAC=.*' | cut -d' ' -f1)
        SRC=$(echo $(head -n3 $1 | tail -n1) | grep -oP 'SRC=.*' | cut -d' ' -f1)
        DST=$(echo $(head -n3 $1 | tail -n1) | grep -oP 'DST=.*' | cut -d' ' -f1)
        LEN=$(echo $(head -n3 $1 | tail -n1) | grep -oP 'LEN=.*' | cut -d' ' -f1)
        TOS=$(echo $(head -n3 $1 | tail -n1) | grep -oP 'TOS=.*' | cut -d' ' -f1)
        PREC=$(echo $(head -n3 $1 | tail -n1) | grep -oP 'PREC=.*' | cut -d' ' -f1)
        TTL=$(echo $(head -n3 $1 | tail -n1) | grep -oP 'TTL=.*' | cut -d' ' -f1)
        ID=$(echo $(head -n3 $1 | tail -n1) | grep -oP 'ID=.*' | cut -d' ' -f1)
        SPT=$(echo $(head -n3 $1 | tail -n1) | grep -oP 'SPT=.*' | cut -d' ' -f1)
        DPT=$(echo $(head -n3 $1 | tail -n1) | grep -oP 'DPT=.*' | cut -d' ' -f1)
        echo $(echo "\"$HEAD\",\"$IN\",\"$OUT\",\"$MAC\",\"$SRC\",\"$DST\",\"$LEN\",\"$TOS\",\"$PREC\",\"$TTL\",\"$ID\",\"$SPT\",\"$DPT\"") >> $2
        i=$(($i+1))
    done
}

extractLogs () {
    echo -n "["
    i=1
    output="something"
    exitCode=1
    # find the first boot that happened on that day
    # keeps looping back until it runs out of logs or it finds a log from the desired date
    while [ "$output" != "" ] && [[ $exitCode -ne 0 ]] ; do
        echo -n "#"
        i=$(($i-1))
        output=$(journalctl -k -b $i -o short-full --no-pager)
        echo $output | grep "$(date --date="$1 days ago" "+%Y-%m-%d")" >> /dev/null
        exitCode=$?
        echo -n "#"
    done
    # find the last boot that happened on that day
    # continues looping back until it fails to find a log from the desired date or we run out of logs
    while [ "$output" != "" ] && [[ $exitCode -ne 1 ]] ; do
        echo -n "#"
        i=$(($i-1))
        output=$(journalctl -k -b $i -o short-full --no-pager)
        echo $output | grep "$(date --date="$1 days ago" "+%b %d")" >> /dev/null
        exitCode=$?
        echo -n "#"
    done
    # Loops back through boot logs I found above to store them in a file
    echo "OwO" > $2 # used to clear/make the file and to make sure its not empty for formatting, this line gets removed from the file
    while [[ i -le 1 ]] ; do
        echo -n "#"
        journalctl -k -b $i -o short-full -g "ufw" --no-pager >> $2
        i=$(($i+1))
        echo -n "#"
    done
    echo -n "]"
    echo
} # end extrctLogs()

echo "Delimiter is ','" 
echo "Extracting $extractDayCount Days of logs"
extractLogs $extractDayCount ./$tempFile
formatCSV ./$tempFile ./$fileName
echo "File saved as $fileName"
