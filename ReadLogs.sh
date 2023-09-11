#!/bin/bash

monitorSSH () {
    result=$(journalctl -u sshd -S "1 second ago" --no-pager) # monitor SSH Login
    if [ "$result" != "-- No entries --" ]; then
        echo "$result"
        notify-send "Systen Monitor" "test 1"
    fi
}

monitorRoot () {
    result=$(journalctl -g root -S "1 second ago" --no-pager) # Root Usage Monitor
    if [ "$result" != "-- No entries --" ]; then
        echo "$result"
        notify-send "Warning Root Event Just happened!" "$result"
    fi
}

while true; do
    monitorSSH
    monitorRoot
    sleep 1
done 
