#!/bin/bash

set -ex

# find script's path
pushd `dirname $0`
DIR=`pwd`
popd

source $DIR/init.sh

function on_exit {
  set +e
  source $DIR/cleanup.sh
}

trap on_exit EXIT

if [ $# -lt 3 ]; then
echo -e "${ERR} syntax: mir-perf <XenServer address> <XenServer root password> <library> <Run time>"
exit
fi

XS=$1
PASSWORD=$2
LIBRARY=$3
TRAFTIME=$4

XENSERVER="sshpass -p $PASSWORD ssh -oStrictHostKeyChecking=no -l root $XS"

pushd $DIR/../$LIBRARY

eval `opam config env`
env DHCP=true NET=direct mirage config --xen

make

popd

# bug: XenServer returns: Ssl.Write_error(5)
#$TMP/xe-unikernel-upload/xe-unikernel-upload \
#    --username=root --password=$PASSWORD --uri=https://$XENSERVER/ \
#    --path=$TMP/mirage-skeleton/iperf_lite/mir-stackv4.xen

$XENSERVER 'if [[ ! -d /boot/guest ]]; then mkdir /boot/guest; fi'

IMAGE=$(find $DIR/../$LIBRARY -name "*.xen" | tail -1)
KERNEL=$(echo $IMAGE | sed -e 's/.*mir-/mir-/')
VM=$(echo $IMAGE | sed -e 's/.*mir-//' -e 's/.xen$//')

sshpass -p $PASSWORD scp $IMAGE root@$XS:/boot/guest/

# hard code VM command interface - TODO: find a way of automatic detection

$XENSERVER "echo \$(xe vm-create name-label=$VM) > VM"
$XENSERVER "xe vm-param-set PV-kernel=/boot/guest/$KERNEL uuid=\$(cat ./VM)"
$XENSERVER "echo \$(xe network-list bridge=xenbr0 params=uuid --minimal) > NET"
$XENSERVER "xe vif-create vm-uuid=\$(cat ./VM) network-uuid=\$(cat ./NET) device=0" #> /dev/null 2>&1
$XENSERVER "xe vif-create vm-uuid=\$(cat ./VM) network-uuid=\$(cat ./NET) device=1" #> /dev/null 2>&1 # second interface
$XENSERVER "xe vm-start vm=\$(cat ./VM)"
set +e
timeout 5s $XENSERVER "unbuffer xe console vm=\$(cat ./VM) > CONSOLE" #note: xe console continue running, stop it?
set -e
$XENSERVER "[[ \$(cat ./CONSOLE) =~ ^.*@(.*)@.* ]] && echo \${BASH_REMATCH[1]} | tail -1 > VM_IP"
VMADDRESS=$($XENSERVER "cat VM_IP")

# add reset counters and start traffic generation

# read stats
exec 3<>/dev/tcp/$VMADDRESS/8080

echo -e "start " >&3

sleep $TRAFTIME

echo -e "stats " >&3

while read -u 3 LINE
do
    if [[ $LINE == *"rx_bytes"* ]]
    then
      STATS=$LINE" - "
      read -u 3 LINE
      STATS=$STATS$LINE" - "
      read -u 3 LINE
      STATS=$STATS$LINE" - "
      read -u 3 LINE
      STATS=$STATS$LINE
      break
    fi
done

echo $STATS

exec 3<&-    # close file




