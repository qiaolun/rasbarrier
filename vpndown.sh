#!/bin/sh


OLDGW='192.168.1.1'
VPNSRV=$(grep '^remote' /etc/openvpn/client.conf | awk '{print $2}')
OPENVPNDEV='tun0'
VPNUPCUSTOM='/etc/openvpn/vpnup_custom'

######################

set -x
export PATH="/bin:/sbin:/usr/sbin:/usr/bin"


LOG='/tmp/autovpn.log'
LOCK='/tmp/autovpn.lock'
PID=$$
INFO="[INFO#${PID}]"
DEBUG="[DEBUG#${PID}]"
ERROR="[ERROR#${PID}]"

echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") vpndown.sh started" >> $LOG
for i in 1 2 3 4 5 6
do
   if [ -f $LOCK ]; then
      echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") got $LOCK , sleep 10 secs. #$i/6" >> $LOG
      sleep 10
   else
      break
   fi
done

if [ -f $LOCK ]; then
	echo "$ERROR $(date "+%d/%b/%Y:%H:%M:%S") still got $LOCK , I'm aborted. Fix me." >> $LOG
	exit 0
#else
#	echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") $LOCK was released, let's continue." >> $LOG
fi
	
# create the lock
echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") vpnup" >> $LOCK





VPNGW=$(ifconfig $OPENVPNDEV | grep -Eo "P-t-P:([0-9.]+)" | cut -d: -f2)
						


echo "[INFO] removing the static routes"

##### begin batch route #####
#route -n | awk '$2 ~ /192.168.172.254/{print $1,$3}'  | while read x y
route -n | awk '$NF ~ /tun0/{print $1,$3}' | while read x y
do
	echo "deleting $x $y"
	route del -net $x netmask $y
done
##### end batch route #####

#route del -host $PPTPSRV 
route del default gw $VPNGW
echo "$INFO add $OLDGW back as the default gw"
route add default gw $OLDGW
echo "$INFO $(date "+%d/%b/%Y:%H:%M:%S") vpndown.sh ended" >> $LOG

# release the lock                                                                                
rm -f $LOCK

