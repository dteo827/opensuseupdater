#!/bin/bash
# A Linux Shell Scriptables with common rules for iptablesABLES Firewall.
# By default this scriptables only open port 80, 22, 53 (input)
# All outgoing traffic is allowed (default - output)
# -------------------------------------------------------------------------
# Copyright (c) 2004 nixCraft project <http://cyberciti.biz/fb/>
# This scriptables is licensed under GNU GPL version 2.0 or above
# -------------------------------------------------------------------------
# This scriptables is part of nixCraft shell scriptables collection (NSSC)
# Visit http://bash.cyberciti.biz/ for more information.
# -------------------------------------------------------------------------
localIP=$(ip route show | awk '(NR == 2) {print $9}')
echo $serverIP
serverIP = sed 's/.$//' localIP
echo $serverIP

iptables="/sbin/iptablesables"
SPAMLIST="blockedip"
SPAMDROPMSG="BLOCKED IP DROP"
 
echo "Starting IPv4 Wall..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
modprobe ip_conntrack
 
[ -f /root/scriptabless/blocked.ips.txt ] && BADIPS=$(egrep -v -E "^#|^$" /root/scriptabless/blocked.ips.txt)
 
PUB_IF="eth0"
 
#unlimited 
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
 
# DROP all incomming traffic
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
 
if [ -f /root/scriptabless/blocked.ips.txt ];
then
# create a new iptablesables list
iptables -N $SPAMLIST
 
for ipblock in $BADIPS
do
   iptables -A $SPAMLIST -s $ipblock -j LOG --log-prefix "$SPAMDROPMSG"
   iptables -A $SPAMLIST -s $ipblock -j DROP
done
 
iptables -I INPUT -j $SPAMLIST
iptables -I OUTPUT -j $SPAMLIST
iptables -I FORWARD -j $SPAMLIST
fi
 
# Block sync
iptables -A INPUT -i ${PUB_IF} -p tcp ! --syn -m state --state NEW  -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Drop Sync"
iptables -A INPUT -i ${PUB_IF} -p tcp ! --syn -m state --state NEW -j DROP
 
# Block Fragments
iptables -A INPUT -i ${PUB_IF} -f  -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Fragments Packets"
iptables -A INPUT -i ${PUB_IF} -f -j DROP
 
# Block bad stuff
iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL ALL -j DROP
 
iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL NONE -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "NULL Packets"
iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL NONE -j DROP # NULL packets
 
iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
 
iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,FIN SYN,FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "XMAS Packets"
iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP #XMAS
 
iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags FIN,ACK FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Fin Packets Scan"
iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags FIN,ACK FIN -j DROP # FIN packet scans
 
iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
 
# Allow full outgoing connection but no incomming stuff
iptables -A INPUT -i eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -o eth0 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
 
# Allow ssh 
iptables -A INPUT -p tcp --destination-port 22 -j ACCEPT
 
# allow incomming ICMP ping pong stuff
iptables -A INPUT -p icmp --icmp-type 8 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type 0 -m state --state ESTABLISHED,RELATED -j ACCEPT
 
# Allow port 53 tcp/udp (DNS Server)
#iptables -A INPUT -p udp --dport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
#iptables -A OUTPUT -p udp --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT
 
#iptables -A INPUT -p tcp --destination-port 53 -m state --state NEW,ESTABLISHED,RELATED  -j ACCEPT
#iptables -A OUTPUT -p tcp --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT
 
# Open port 80
iptables -A INPUT -p tcp --destination-port 80 -j ACCEPT
##### Add your rules below ######
 
##### END your rules ############
 
# Do not log smb/windows sharing packets - too much logging
iptables -A INPUT -p tcp -i eth0 --dport 137:139 -j REJECT
iptables -A INPUT -p udp -i eth0 --dport 137:139 -j REJECT
 
# log everything else and drop
iptables -A INPUT -j LOG
iptables -A FORWARD -j LOG
iptables -A INPUT -j DROP
