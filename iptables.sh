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
#make temp file for local ip
read -p "what is the t in 10.10.10t.1 ? " t
echo -n "10.10.10" >> localIP
echo -n $t >> localIP
echo -n ".1" >> localIP
localIPaddr=$(<localIP)
rm localIP
echo $localIPaddr

#make temp file for server ip
echo -n "10.10.10" >> serverIP
echo -n $t >> serverIP
echo -n ".15" >> serverIP
echo "before cat"
serverIPaddr=$(<serverIP)
echo $serverIPaddr


SPAMLIST="blockedip"
SPAMDROPMSG="BLOCKED IP DROP"
 
echo "Starting IPv4 Wall..."
/usr/sbin/iptables -F
/usr/sbin/iptables -X
/usr/sbin/iptables -t nat -F
/usr/sbin/iptables -t nat -X
/usr/sbin/iptables -t mangle -F
/usr/sbin/iptables -t mangle -X
modprobe ip_conntrack
 
[ -f /root/scriptabless/blocked.ips.txt ] && BADIPS=$(egrep -v -E "^#|^$" /root/scriptabless/blocked.ips.txt)
 
PUB_IF="eth0"
 
#unlimited 
/usr/sbin/iptables -A INPUT -i lo -j ACCEPT
/usr/sbin/iptables -A OUTPUT -o lo -j ACCEPT
 
# DROP all incomming traffic
/usr/sbin/iptables -P INPUT DROP
/usr/sbin/iptables -P OUTPUT DROP
/usr/sbin/iptables -P FORWARD DROP
 
if [ -f /root/scriptabless/blocked.ips.txt ];
then
# create a new iptablesables list
/usr/sbin/iptables -N $SPAMLIST
 
for ipblock in $BADIPS
do
   iptables -A $SPAMLIST -s $ipblock -j LOG --log-prefix "$SPAMDROPMSG"
   iptables -A $SPAMLIST -s $ipblock -j DROP
done
 
/usr/sbin/iptables -I INPUT -j $SPAMLIST
/usr/sbin/iptables -I OUTPUT -j $SPAMLIST
/usr/sbin/iptables -I FORWARD -j $SPAMLIST
fi
 
# Block sync
/usr/sbin/iptables -A INPUT -i ${PUB_IF} -p tcp ! --syn -m state --state NEW  -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Drop Sync"
/usr/sbin/iptables -A INPUT -i ${PUB_IF} -p tcp ! --syn -m state --state NEW -j DROP
 
# Block Fragments
/usr/sbin/iptables -A INPUT -i ${PUB_IF} -f  -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Fragments Packets"
/usr/sbin/iptables -A INPUT -i ${PUB_IF} -f -j DROP
 
# Block bad stuff
/usr/sbin/iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
/usr/sbin/iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL ALL -j DROP
 
/usr/sbin/iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL NONE -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "NULL Packets"
/usr/sbin/iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL NONE -j DROP # NULL packets
 
/usr/sbin/iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
 
/usr/sbin/iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,FIN SYN,FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "XMAS Packets"
/usr/sbin/iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP #XMAS
 
/usr/sbin/iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags FIN,ACK FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Fin Packets Scan"
/usr/sbin/iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags FIN,ACK FIN -j DROP # FIN packet scans
 
/usr/sbin/iptables  -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
 
# Allow full outgoing connection but no incomming stuff
/usr/sbin/iptables -A INPUT -i eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
/usr/sbin/iptables -A OUTPUT -o eth0 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
 
# Allow ssh 
/usr/sbin/iptables -A INPUT -p tcp --destination-port 22 -j ACCEPT
 
# allow incomming ICMP ping pong stuff
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 8 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 0 -m state --state ESTABLISHED,RELATED -j ACCEPT
 
# Allow port 53 tcp/udp (DNS Server)
#iptables -A INPUT -p udp --dport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
#iptables -A OUTPUT -p udp --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT
 
#iptables -A INPUT -p tcp --destination-port 53 -m state --state NEW,ESTABLISHED,RELATED  -j ACCEPT
#iptables -A OUTPUT -p tcp --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT
 
# Open port 80
/usr/sbin/iptables -A INPUT -p tcp --destination-port 80 -j ACCEPT
##### Add your rules below ######
 
##### END your rules ############
 
# Do not log smb/windows sharing packets - too much logging
/usr/sbin/iptables -A INPUT -p tcp -i eth0 --dport 137:139 -j REJECT
/usr/sbin/iptables -A INPUT -p udp -i eth0 --dport 137:139 -j REJECT
 
# log everything else and drop
/usr/sbin/iptables -A INPUT -j LOG
/usr/sbin/iptables -A FORWARD -j LOG
/usr/sbin/iptables -A INPUT -j DROP
