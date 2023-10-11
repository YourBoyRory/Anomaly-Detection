#!/bin/bash

traceIP() {
    echo "Trace: $1"
    whois $1 | grep -oP '^Country:        \K.*'
}

getIP() {
    echo $1 | grep -oP 'SRC=\K.*' | cut -d, -f1
}

traceIP $(getIP "$(head -n400 ./Events.csv | tail -n1)")
