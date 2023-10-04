#!/bin/bash

fileName=$(hostname)_logs_$(date +"%Y-%m-%d_%T")          # File name will be "hostname_logs_date_time.csv" 
extractDayCount=7                                         # the amount of days to extract from the system log

echo "Delimiter is ';'"                                   # Notifies about Hard Coded Delimiter

echo "Extracting $extractDayCount Days of logs"
journalctl -S "$extractDayCount days ago" --no-pager > ./$fileName.csv  # Pulls 7 days of logs
echo "Separating Dates from data into 1st column"
perl -i -pe 's/^(.{15}).{1}/\1;/g' ./$fileName.csv                      # Separates date
echo "Separating Dates app and machine names into 2nd column"
perl -i -pe 's/([^:]*:[^:]*:[^:]*):/\1;/g' ./$fileName.csv              # Separates apps and machine name
echo "Pruning rouge delimiters"
sed -i 's/;/:/3g' ./$fileName.csv                                       # Plucks out any remaining delimiters and replaces them with a ':'
echo "File saved as $fileName.csv"
