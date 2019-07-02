#!/bin/bash
# This script is run remotely by setup.sh script

#
# changing the password
#
PASSWORD="$( dd if=/dev/urandom bs=1 count=1024 | sha256sum - | cut -d ' ' -f 1 )"
echo -e "$PASSWORD\n$PASSWORD" | passwd
echo -e "\n\n* * * New password for root:\n$PASSWORD\n\n"
echo "Save the password and press any key to continue..."
read

#
# Add wireguard interface to router
#

# install packages
opkg update
opkg install wireguard luci-proto-wireguard

# Assign local WG values
WG_ADDRESS=$1
WG_KEY=$2

# Assign server WG values
WG_SERVER_PUBKEY=$3
WG_SERVER_PEER_IP=$4
WG_SERVER_ENDPOINT_HOST=$5
WG_SERVER_ENDPOINT_PORT=$6

# generate config
WG_CONFIG="
config interface 'wg0'
        option proto 'wireguard'
        option private_key '$WG_KEY'
        option listen_port '12000'
        list addresses '$WG_ADDRESS/24'

config wireguard_wg0
        option public_key '$WG_SERVER_PUBKEY'
        list allowed_ips '$WG_SERVER_PEER_IP/24'
        option persistent_keepalive '25'
        option endpoint_host '$WG_SERVER_ENDPOINT_HOST'
        option endpoint_port '$WG_SERVER_ENDPOINT_PORT'
"

echo "$WG_CONFIG"
echo "$WG_CONFIG" >> /etc/config/network


#
# Allow 'wan' input
# We have two different firewall formats, hence two commands
#
sed -i "s/option input\t\tREJECT/option input\t\tACCEPT/" /etc/config/firewall
sed -i "s/option input 'REJECT'/option input 'ACCEPT'/" /etc/config/firewall

# reload network to apply
/etc/init.d/network restart

