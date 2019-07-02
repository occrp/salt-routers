#!/bin/bash
# run to add exroot config on router
# use /srv/salt/setup.sh

source ./wireguard-config.conf

read -p "Router address [default: 192.168.1.1]: " ROUTER
ROUTER=${ROUTER:-192.168.1.1}
read -p "Wireguard address (without /24): " WG_ADDRESS
read -p "Salt name (without spaces): " SALT_NAME


#
# Add router fingerprint to local server
#
ssh-keyscan -H $ROUTER >> ~/.ssh/known_hosts

# generate keys for router
WG_KEY="$( wg genkey )"
WG_PUBKEY="$( echo "$WG_KEY" | wg pubkey )"

# replace last number WG_SERVER_IP with 0
WG_SERVER_PEER_IP="${WG_SERVER_IP%.*}.0"

#
# Move and execute configuration script to router
#
scp router_config.sh root@$ROUTER:/root/
ssh root@$ROUTER "/bin/ash /root/router_config.sh $WG_ADDRESS $WG_KEY $WG_SERVER_PUBKEY $WG_SERVER_PEER_IP $WG_SERVER_ENDPOINT_HOST $WG_SERVER_ENDPOINT_PORT "

#
# Wait for WG config to update
#
sleep 2s

#
# Pass config to salt-routers VM
#
WG_PEER_CONFIG="# $SALT_NAME
[Peer]
PublicKey = $WG_PUBKEY
AllowedIPs = $WG_ADDRESS/32
PersistentKeepalive = 25
"
SALT_CONFIG="
$SALT_NAME:
  host: $WG_ADDRESS
  user: root
  sudo: True
"

ssh -t root@$WG_SERVER_IP "echo \"$WG_PEER_CONFIG\" >> /etc/wireguard/wg0.conf && echo \"$SALT_CONFIG\" >> /etc/salt/roster && wg set wg0 peer $WG_PUBKEY allowed-ips $WG_ADDRESS/32 persistent-keepalive 25"


#
# Install requirements for salt on router
# Copy salt-routers keys to the router
#
ssh -t root@$WG_SERVER_IP "/srv/salt/install_requirements.sh $SALT_NAME"
