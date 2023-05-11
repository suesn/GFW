#!/bin/bash

echo run black shell!

iptables -P FORWARD ACCEPT

cat <(curl -Ls https://raw.githubusercontent.com/suesn/GFW/main/b.txt) | while read line
do                        
        echo iptables -A OUTPUT -p tcp -d $line --dport 65535 -j DROP
iptables -A OUTPUT -p tcp -d $line --dport 65535 -j DROP

done
