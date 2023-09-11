#!/bin/bash

monitorSSH () {
    result=$(journalctl -u sshd -S "1 second ago" --no-pager) # monitor SSH Login
    if [ "$result" != "-- No entries --" ]; then
        echo "$result"
        selection=$(notify-send -A "View Captured Log" "Warning SSH Event Just happened!" "$result")
        if [ "$selection" == "0" ] ; then
             yad --no-buttons --form  --field="Captured SSH Event":TXT "$result"
        fi
    fi
}

monitorRoot () {
    result=$(journalctl -g root -S "1 second ago" --no-pager) # Root Usage Monitor
    if [ "$result" != "-- No entries --" ]; then
        echo "$result"
        selection=$(notify-send -A "View Captured Log" "Warning Root Event Just happened!" "$result")
        if [ "$selection" == "0" ] ; then
             yad --no-buttons --list --no-headers --column="test":TEXT "$result"
        fi
    fi
}

while true; do
    monitorSSH &
    monitorRoot &
    sleep 1
done 
