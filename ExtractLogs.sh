#!/bin/bash

fileName=$(hostname)_logs_$(date +"%Y-%m-%d_%T")

echo "Delimiter is ';'"

echo "Extracting 7 Days of logs"
journalctl -S "7 days ago" --no-pager > ./$fileName.csv      # Extract 7 days of logs
echo "Seperating Dates from data into 1st column"
sed -i 's/^\(.\{15\}\).\{1\}/\1;/g' ./$fileName.csv          # Seperates Date
echo "Seperating Dates app and machine names into 2nd column"
sed -i 's/\([^:]*:[^:]*:[^:]*\):/\1;/g' ./$fileName.csv      # Seperates App
echo "Pruning rouge delimiters"
sed -i 's/;/:/3g' ./$fileName.csv                            # Removes any remaining delimiters 
echo "File saved as $fileName.csv"
