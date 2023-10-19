#!/bin/bash

#fileName=$(hostname)_ufwlogs_$(date +"%Y-%m-%d_%T")          # File name will be "hostname_ufwlogs_date_time.csv" 
fileName=Events.csv
extractDayCount=7                                           # the amount of days to extract from the system log

formatCSV () {
    echo "Separating Dates from data into 1st column"
    perl -i -pe 's/^(.{27}).{1}/\1,/g' $1                           # Separates date
    echo "Separating Dates app and machine names into 2nd column"
    perl -i -pe 's/([^:]*:[^:]*:[^:]*):/\1,/g' $1                   # Separates apps and machine name
    echo "Pruning rouge delimiters"
    sed -i 's/,/:/3g' $1                                            # Plucks out any remaining delimiters and replaces them with a ':'
    echo "Formatting UFW Data"
    sed -i 's/ /,/7g' $1                                           # puts data in its own columns
    echo "Setting column titles"
    perl -i -pe 'if ($. == 1) { print "Time Created, Kernel, Event Type, In, Out, Mac, Source, Destination\n"; $_ = <> }' $1
    echo "Pruning Irrelevant Information"
    perl -ni -e 'print unless /^-- No entries --$/;' $1
    sed -i 's/\(\([^,]*,\)\{7\}[^,]*\).*/\1/' $1
} # end formatCSV()

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
extractLogs $extractDayCount ./$fileName            
formatCSV ./$fileName
echo "File saved as $fileName"
