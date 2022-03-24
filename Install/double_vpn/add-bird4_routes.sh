#!/bin/sh

 #USER VARIABLE
ISP=ISPINPUT
VPN1=VPN1INPUT
VPN2=VPN2INPUT
HOMEPATH=/opt/root/Bird4Static
URL0=https://antifilter.download/list/allyouneed.lst

 #SCRIPT VARIABE
BLACKLIST=$HOMEPATH/lists/antifilter.list
ROUTE_FORCE_ISP=/opt/etc/bird4-force-isp.list
ROUTE_FORCE_VPN1=/opt/etc/bird4-force-vpn1.list
ROUTE_FORCE_VPN2=/opt/etc/bird4-force-vpn2.list
ROUTE_BASE_VPN1=/opt/etc/bird4-base-vpn1.list
ROUTE_USER_VPN1=/opt/etc/bird4-user-vpn1.list
ROUTE_BASE_VPN2=/opt/etc/bird4-base-vpn2.list
ROUTE_USER_VPN2=/opt/etc/bird4-user-vpn2.list
VPNTXT=$HOMEPATH/lists/user-vpn.list
VPN1TXT=$HOMEPATH/lists/user-vpn1.list
VPN2TXT=$HOMEPATH/lists/user-vpn2.list
ISPTXT=$HOMEPATH/lists/user-isp.list
MD5_SUM=$HOMEPATH/scripts/sum.md5

 #INIT FILES
WORK_FILES="$BLACKLIST \
            $ROUTE_FORCE_ISP $ROUTE_FORCE_VPN1 $ROUTE_FORCE_VPN2 \
            $ROUTE_BASE_VPN1 $ROUTE_USER_VPN1 \
            $ROUTE_BASE_VPN2 $ROUTE_USER_VPN2 $MD5_SUM"
touch $WORK_FILES
for var in $WORK_FILES; do
  [ -s $var ] || echo 1 > $var
done

 #INIT COMMAND
CMD_FORCE_ISP="$HOMEPATH/scripts/addip.sh $ISPTXT $ISP"
CMD_FORCE_VPN1="$HOMEPATH/scripts/addip.sh $VPN1TXT $VPN1"
CMD_FORCE_VPN2="$HOMEPATH/scripts/addip.sh $VPN2TXT $VPN2"
CMD_VPN1="$HOMEPATH/scripts/addip.sh $VPNTXT $VPN1"
CMD_VPN2="$HOMEPATH/scripts/addip.sh $VPNTXT $VPN2"

 #WAIT DNS
until ADDRS=$(dig +short google.com @localhost -p 53) && [ -n "$ADDRS" ] > /dev/null 2>&1; do sleep 5; done

 #BASE_LIST
curl -sk $URL0 | sort | diff -u $BLACKLIST - | patch $BLACKLIST -
cat $BLACKLIST | sed 's/^/route /' | sed 's/$/ via "'$VPN1'";/' | diff -u $ROUTE_BASE_VPN1 - | patch $ROUTE_BASE_VPN1 -
cat $BLACKLIST | sed 's/^/route /' | sed 's/$/ via "'$VPN2'";/' | diff -u $ROUTE_BASE_VPN2 - | patch $ROUTE_BASE_VPN2 -

 #BASE_USER_LIST
$CMD_VPN1 | sort | diff -u $ROUTE_USER_VPN1 - | patch $ROUTE_USER_VPN1 -
$CMD_VPN2 | sort | diff -u $ROUTE_USER_VPN2 - | patch $ROUTE_USER_VPN2 -

 #FORCE_LIST
$CMD_FORCE_ISP | sort | diff -u $ROUTE_FORCE_ISP - | patch $ROUTE_FORCE_ISP -
$CMD_FORCE_VPN1 | sort | diff -u $ROUTE_FORCE_VPN1 - | patch $ROUTE_FORCE_VPN1 -
$CMD_FORCE_VPN2 | sort | diff -u $ROUTE_FORCE_VPN2 - | patch $ROUTE_FORCE_VPN2 -

 #RESTART BIRD
if [ "$(cat $MD5_SUM)" != "$(md5sum /opt/etc/bird4*)" ]; then
  md5sum /opt/etc/bird4* > $MD5_SUM
  echo "Restarting bird"
  killall -s SIGHUP bird4
fi
