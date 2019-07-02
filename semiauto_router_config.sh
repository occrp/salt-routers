#!/bin/ash
# This script is run remotely by setup.sh script

# wireguard server config
source ./wireguard-config.conf

# 
# Give router address and name
# 
read -p "Wireguard address (without /24): " WG_ADDRESS
read -p "Salt name (without spaces): " SALT_NAME


#
# changing the password
#
PASSWORD="$( dd if=/dev/urandom bs=1 count=1024 | sha256sum - | cut -d ' ' -f 1 )"
echo -e "$PASSWORD\n$PASSWORD" | passwd

#
# Add wireguard interface to router
#

# install packages
opkg update
opkg install wireguard luci-proto-wireguard

# generate keys
WG_KEY="$( wg genkey )"
WG_PUBKEY="$( echo "$WG_KEY" | wg pubkey )"

# generate config
WG_CONFIG="
config interface 'wg0'
        option proto 'wireguard'
        option private_key '$WG_KEY'
        option listen_port '12000'
        list addresses '$WG_ADDRESS/24'

config wireguard_wg0
        option public_key '$WG_SERVER_PUBKEY'
        list allowed_ips '10.100.1.0/24'
        option persistent_keepalive '25'
        option endpoint_host '$WG_SERVER_ENDPOINT_HOST'
        option endpoint_port '$WG_SERVER_ENDPOINT_PORT'
"

echo "$WG_CONFIG" >> /etc/config/network


WG_PEER_CONFIG="# $SALT_NAME\n[Peer]\nPublicKey = $WG_PUBKEY\nAllowedIPs = $WG_ADDRESS/32\nPersistentKeepalive = 25\n"
SALT_CONFIG="$SALT_NAME:\n  host: $WG_ADDRESS\n  user: root\n  sudo: True\n"

#
# Allow 'wan' input
#
sed -i "s/option input\t\tREJECT/option input\t\tACCEPT/" /etc/config/firewall

#
# Exroot configuration for router
#

# install apps
opkg update && opkg install block-mount kmod-fs-ext4 kmod-usb-storage e2fsprogs kmod-usb-ohci kmod-usb-uhci fdisk

# format usb drive
mkfs.ext4 -q /dev/sda1

# mount drive
mount /dev/sda1 /mnt ; tar -C /overlay -cvf - . | tar -C /mnt -xf - ; umount /mnt

# Generate fstab
block detect > /etc/config/fstab
sed -i s/option$'\t'enabled$'\t'\'0\'/option$'\t'enabled$'\t'\'1\'/ /etc/config/fstab
sed -i s#/mnt/sda1#/overlay# /etc/config/fstab
cat /etc/config/fstab;

#
# Echo config
#
echo "=========================================================="
echo -e "\n\n* * * New password for root:\n$PASSWORD\n\n"
echo "=========================================================="
echo -e "\n\nWireguard conf: $WG_PEER_CONFIG\n\nSalt config: $SALT_CONFIG\n"
echo -e "RUN ON salt-routers:\n\necho \"$WG_PEER_CONFIG\" >> /etc/wireguard/wg0.conf\necho \"$SALT_CONFIG\" >> /etc/salt/roster\n\nifdown wg0\n\nifup wg0"
echo "Save the config and send to OCCRP team in encrypted email"
echo "Press any key to continue..."
echo "=========================================================="
read

# reboot to apply changes
reboot


