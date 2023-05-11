#!/bin/bash

echo run black shell!

iptables -F

iptables -P FORWARD ACCEPT

cat <(curl -Ls https://raw.githubusercontent.com/suesn/GFW/main/b.txt) | while read line
do                        
        echo iptables -A OUTPUT -m string --string "$line" --algo bm --to 65535 -j DROP
iptables -A OUTPUT -m string --string "$line" --algo bm --to 65535 -j DROP

done
