#!/bin/bash

drawWindow () {
    #Var
    Xaxis=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f1) # finds screen width
    Yaxis=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f2) # finds screen height
    tempName=templog_$RANDOM.html
    
    # Replace all newlines with <br> for HTML rendering later
    logText=${2//
/"<br>"}
    
    #Log Design
    echo \
    "<!DOCTYPE html>
    <html>
      <head>
        <title>Title of the document</title>
      </head>
      <body style=\"background-color:#1C1C1C;\">
        <font color=\"#E0E1DE\">
        <p>$logText</p>
      </body>
    </html>" \
    >> /tmp/$tempName
    
    # Display GUI
    #
    # centers and divides the screen width and screen height by 2 to make sure
    # the window isn't too big regardless of screen size
    # uses YAD to render a custom html based window containing the log text
    # This way the user can copy the text and it looks better then YAD default options
    yad \
        --title="$1" \
        --center \
        --width=$(($Xaxis/2)) \
        --height=$(($Yaxis/2)) \
        --no-buttons \
        --html \
        --uri="file:///tmp/$tempName"
    
    rm /tmp/$tempName # Remove tmp File
}

# monitor SSH Login
monitorSSH () {
    result=$(journalctl -u sshd -S "1 second ago" --no-pager)
    if [ "$result" != "-- No entries --" ]; then
        echo "$result"
        selection=$(notify-send -A "View Captured Log" "[Warning] SSH Event Just happened!" "$result")
        if [ "$selection" == "0" ] ; then
             drawWindow "Captured SSH Event" "$result"
        fi
    fi
}

# monitor FireWall Events
monitorUFW () {
    result=$(journalctl -g "ufw" -S "1 second ago" --no-pager)
    if [ "$result" != "-- No entries --" ]; then
        echo "$result"
        selection=$(notify-send -A "View Captured Log" "[Warning] Firewall Event Just happened!" "$result")
        if [ "$selection" == "0" ] ; then
             drawWindow "Captured Firewall Event" "$result"
        fi
    fi
}

# Sudo Usage Monitor
monitorSudo () {
    result=$(journalctl -g "for user root" -S "1 second ago" --no-pager)
    if [ "$result" != "-- No entries --" ]; then
        fullResults=$(journalctl -g "root" -S "1 second ago" --no-pager)
        echo "$fullResults"
        selection=$(notify-send -A "View Captured Log" "[Warning] Root Event Just happened!" "$fullResults")
        if [ "$selection" == "0" ] ; then
             drawWindow "Captured Root Event" "$fullResults"
        fi
    fi
}

while true; do
    monitorSSH & # monitor SSH Login
    monitorUFW & # monitor FireWall Events
    monitorSudo & # Sudo Usage Monitor
    sleep 1
done 
