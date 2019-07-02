#!/bin/bash
# Install python and other required apps
# Register ssh id

SALT_NAME=$1
ROUTER="$( grep -A 1 "$SALT_NAME" /etc/salt/roster | tail -n 1 | sed -r -e "s/\s+host: ([0-9\.]+)$/\1/" )"

ssh-keygen -f "/root/.ssh/known_hosts" -R $ROUTER
ssh-keyscan -H $ROUTER >> ~/.ssh/known_hosts

sleep 5s

echo
echo "COPY KEYS TO ROUTER"
echo

sudo salt-ssh root@$ROUTER -i test.ping
ssh-copy-id -i root@$ROUTER
ssh-copy-id -i /etc/salt/pki/master/ssh/salt-ssh.rsa.pub root@$ROUTER

echo
echo " COPYING KEYS TO DROPBEAR"
echo
ssh root@$ROUTER 'cp /root/.ssh/authorized_keys /etc/dropbear/ && chmod 700 /etc/dropbear && chmod 600 /etc/dropbear/authorized_keys'

#
# Exroot configuration for router
#

# install apps
ssh root@$ROUTER "opkg update && opkg install block-mount kmod-fs-ext4 kmod-usb-storage e2fsprogs kmod-usb-ohci kmod-usb-uhci fdisk"

# format usb drive
ssh root@$ROUTER "mkfs.ext4 /dev/sda1"

# mount drive
ssh root@$ROUTER "mount /dev/sda1 /mnt ; tar -C /overlay -cvf - . | tar -C /mnt -xf - ; umount /mnt"

# Generate fstab
ssh root@$ROUTER "block detect > /etc/config/fstab; \
	   sed -i s/option$'\t'enabled$'\t'\'0\'/option$'\t'enabled$'\t'\'1\'/ /etc/config/fstab; \
	   sed -i s#/mnt/sda1#/overlay# /etc/config/fstab; \
	   cat /etc/config/fstab;"

#
# reboot to apply changes
ssh root@$ROUTER "reboot"

#
# Wait for reboot to finish
#

c=0
RESPONSE=1
sleep 5s
while [[ $RESPONSE -ne 0  &&  $c -lt 10000 ]]
do
	ping -c 1 -t 1 $ROUTER
	RESPONSE=$?
	echo "RESPONSE = $?"
	((c++))
	echo -e "C = $c" \\r
	if [ $RESPONSE -eq 0 ]; then
		echo "$ROUTER is up"
    		sleep 15s
    		break
	else
		echo "$ROUTER is down"
	fi
done

#
# Setup salt with default settings
# 


# install salt-requirements
ssh root@$ROUTER 'opkg update && opkg install python python-pip sudo bash'

echo
echo "CREATE TEMP FILES IF THEY DON'T EXIST"
echo
salt-ssh -i $SALT_NAME test.ping

# TEMPORARY SOLUTION!!! Remove the code from rsax931.py to avoid OSError: Cannot locate OpenSSL libcrypto
echo
echo "SOLVING OSError: Cannot locate OpenSSL libcrypto"
echo
salt-ssh $SALT_NAME -r "cd /var/tmp/.root*/py2/salt/utils/ && sed -i \"s/lib = find_library('crypto')/lib = 'libcrypto.so.1.0.0'/\" rsax931.py"

# Apply config from top.sls
echo
echo "APPLYING BASIC ROUTER CONFIG"
echo
salt-ssh $SALT_NAME state.apply
