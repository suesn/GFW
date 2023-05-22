#!/bin/bash

echo run black shell!

iptables -F

iptables -P FORWARD ACCEPT

cat <(curl -Ls https://raw.githubusercontent.com/suesn/GFW/main/b.txt) | while read line
do                        
        echo iptables -I OUTPUT -p tcp -m string --string ""$line"" --algo bm -j DROP
iptables -I OUTPUT -p tcp -m string --string ""$line"" --algo bm -j DROP
        echo iptables -I INPUT -p tcp -m string --string ""$line"" --algo bm -j DROP
iptables -I INPUT -p tcp -m string --string ""$line"" --algo bm -j DROP

done
