#!/bin/bash

echo "[" > test.json
journalctl -k -g "ufw" --no-pager --output=json >> test.json
echo "]" >> test.json
perl -p -i -e 's/}\s*$/},/' test.json 
perl -p -i -e 's/,\]/\]/' test.json 
