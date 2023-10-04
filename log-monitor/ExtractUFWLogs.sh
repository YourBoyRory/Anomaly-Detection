#!/bin/bash

#fileName=$(hostname)_ufwlogs_$(date +"%Y-%m-%d_%T")          # File name will be "hostname_ufwlogs_date_time.csv" 
fileName=Events
extractDayCount=7                                           # the amount of days to extract from the system log

formatCSV () {
    echo "Separating Dates from data into 1st column"
    perl -i -pe 's/^(.{15}).{1}/\1,/g' $1                           # Separates date
    echo "Separating Dates app and machine names into 2nd column"
    perl -i -pe 's/([^:]*:[^:]*:[^:]*):/\1,/g' $1                   # Separates apps and machine name
    echo "Pruning rouge delimiters"
    sed -i 's/,/:/3g' $1                                            # Plucks out any remaining delimiters and replaces them with a ':'
    echo "Formatting UFW Data"
    sed -i 's/ /,/7g' $1                                           # puts data in its own columns
    echo "Pruning Irrelevant Information"
    perl -ni -e 'print unless /^-- No entries -,$/;' $1 
} # end formatCSV()

extractLogs () {
    i=0
    output="something"
    exitCode=1
    # find the first boot that happened on that day
    # keeps looping back until it runs out of logs or it finds a log from the desired date
    while [ "$output" != "" ] && [[ $exitCode -ne 0 ]] ; do
        i=$(($i-1))
        output=$(journalctl -k -b $i -o short --no-pager)
        echo $output | grep "$(date --date="$1 days ago" "+%b %d")" >> /dev/null
        exitCode=$?
    done
    # find the last boot that happened on that day
    # continues looping back until it fails to find a log from the desired date or we run out of logs
    while [ "$output" != "" ] && [[ $exitCode -ne 1 ]] ; do
        i=$(($i-1))
        output=$(journalctl -k -b $i -o short --no-pager)
        echo $output | grep "$(date --date="$1 days ago" "+%b %d")" >> /dev/null
        exitCode=$?
    done
    # Loops back through boot logs I found above to store them in a file
    echo "-- No entries --" > $2 # used to clear/make the file and to make sure its not empty for formatting, this line gets removed from the file
    for i in {1..6} ; do
        journalctl -k -b $i -o short-iso-precise -g "ufw" --no-pager >> $2
    done
} # end extrctLogs()

echo "Delimiter is ','" 
echo "Extracting $extractDayCount Days of logs"
extractLogs $extractDayCount ./$fileName.csv            
formatCSV ./$fileName.csv
echo "File saved as $fileName.csv"
