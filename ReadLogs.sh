#!/bin/bash

while true; do
    journalctl -g sudo -S "1 second ago" -n 1
    sleep 1
done 
