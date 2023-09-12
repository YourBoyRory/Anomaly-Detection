#!/bin/bash

# Shows log window
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
            <title>$1</title>
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
} # end drawWindow()

# Send Email
# (Subject, Message) 
sendEmail () {
    emailList=zaynebyard@gmail.com;yourboyrory@gmail.com  # email list
    echo "$2" | mailx -s "$1" $emailList                  # sends the captured log as an email with the event type as the subject  
} # end sendEmail()

# Send Notification
# (Type, Log) 
sendDENotify () {
    # Show the currently logged on user (if this script was run on a workstation) that an event has occurred
    selection=$(notify-send -A "View Captured Log" "[Warning] $1 Just happened!" "$2")
    if [ "$selection" == "0" ] ; then
        drawWindow "Captured $1" "$result" # opened the window to view the log if the user clicks the notification
    fi
} # end sendEmail()

# monitor SSH Login
monitorSSH () {
    result=$(journalctl -u sshd -S "1 second ago" --no-pager)  # detects all SHH events
    if [ "$result" != "-- No entries --" ]; then
        echo "$result"                                         # Displays the captured log on the console  
        sendEmail "Captured SSH Event" "$result"               # Send the admins an email
        sendDENotify "SSH Event" "$result" &                   # Send the notification on a new thread to the user (if this script was run on a workstation)
    fi
} # end monitorSSH()

# monitor FireWall Events
monitorUFW () {
    result=$(journalctl -g "ufw" -S "1 second ago" --no-pager)  # detects all Firewall events
    if [ "$result" != "-- No entries --" ]; then
        echo "$result"                                          # Displays the captured log on the console  
        sendEmail "Captured Firewall Event" "$result"           # Send the admins an email
        sendDENotify "Firewall Event" "$result" &               # Send the notification on a new thread to the user (if this script was run on a workstation)
    fi
} # end monitorUFW()

# Sudo Usage Monitor
monitorSudo () {
    result=$(journalctl -g "for user root" -S "1 second ago" --no-pager) # detects root login or log out (or sudo usage)
    if [ "$result" != "-- No entries --" ]; then
        fullResults=$(journalctl -g "root" -S "1 second ago" --no-pager) # pulls full log of for root login, not just "session opened for user root" (Shows what command run with sudo)
        echo "$fullResults"                                              # Displays the captured log on the console
        sendEmail "Captured Root Event" "$result"                        # Send the admins an email
        sendDENotify "Root Event" "$result" &                            # Send the notification on a new thread to the user (if this script was run on a workstation)
    fi
} # end monitorSudo()

timeSize=1
startDate=$(date --date='2 seconds ago' +"%s")
while true; do      # never ends works in the background
    startDate=$((startDate+$timeSize))
    monitorSSH $startDate    # monitor SSH Login
    monitorUFW $startDate    # monitor Firewall Events
    monitorSudo $startDate   # Sudo Usage Monitor
    sleep $timeSize
done 
