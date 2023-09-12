#!/bin/bash

fileName=$(hostname)_logs_$(date +"%Y-%m-%d_%T")          # File name will be "hostname_logs_date_time.csv" 

echo "Delimiter is ';'"                                   # Notifies about Hard Coded Delimiter

echo "Extracting 7 Days of logs"
journalctl -S "7 days ago" --no-pager > ./$fileName.csv   # Pulls 7 days of logs
echo "Separating Dates from data into 1st column"
sed -i 's/^\(.\{15\}\).\{1\}/\1;/g' ./$fileName.csv       # Separates date
echo "Separating Dates app and machine names into 2nd column"
sed -i 's/\([^:]*:[^:]*:[^:]*\):/\1;/g' ./$fileName.csv   # Separates apps and machine name
echo "Pruning rouge delimiters"
sed -i 's/;/:/3g' ./$fileName.csv                         # Plucks out any remaining delimiters and replaces them with a ':'
echo "File saved as $fileName.csv"
