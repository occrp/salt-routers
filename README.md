# Salt routers

Manage fleet of routers across the world using OpenWRT, WireGuard, Salt. Optionally protect your traffic with OpenVPN.

## Table of contents:

1. [Setup WireGuard and Salt on OpenWRT Router](#setup-wireguar-and-salt-on-openwrt-router)
2. [Create pillar config](#create-pillar-config)
3. [Fix Cannot locate OpenSSL libcrypto error](#fix-cannot-locate-openssl-libcrypto-error)
4. [Set-up NordVPN on router](#set-up-nordvpn-on-router)
5. [Disable NordVPN](#disable-nordvpn)
6. [Enable NordVPN](#enable-nordvpn)
7. [Upgrade firmware](#upgrade-firmware)
8. [Salt state files description](#salt-state-files-description)
    1. [top.sls](#topsls)
    2. [channel2ghz.sls and channel5ghz.sls](#channel2ghzsls-and-channel5ghzsls)
    3. [dhcp.sls](#dhcpsls)
    4. [disable5ghz.sls](#disable5ghzsls)
    5. [hostname.sls](#hostnamesls)
    6. [power2ghz.sls and power5ghz.sls](#power2ghzsls-and-power5ghzsls)
    7. [wifi.sls](#wifisls)
    8. [zabbix.sls](#zabbixsls)
    9. [nordvpn/nordvpn_basic.sls](#nordvpnnordvpn_basicsls)
    10. [nordvpn/add_nordvpn.sls](#nordvpnadd_nordvpnsls)
    11. [nordvpn/disable_vpn.sls](#nordvpndisable_vpnsls)
    12. [nordvpn/enable_vpn.sls](#nordvpnenable_vpnsls)
    13. [upgrade.sls](#upgradesls)
9. [Contact and contributing](#contact-and-contributing)
10. [Authors](#authors)

## Setup WireGuard and Salt on OpenWRT Router

Clone [salt-routers](https://git.occrp.org/libre/salt-routers) repository on your laptop:

```
git clone https://git.occrp.org/libre/salt-routers.git
```

To setup **[WireGuard](https://www.wireguard.com/install/)** and **[Salt](https://docs.saltstack.com/en/latest/)** on **[OpenWRT](https://openwrt.org/)** router run the script `setup.sh` contained in this repository. Prerequisites:

* Wired connection to OpenWRT router ([Table of Hardware: Firmware Downloads](https://openwrt.org/toh/views/toh_fwdownload))
* WireGuard [installed](https://www.wireguard.com/install/) on your laptop
* WireGuard connection to the Salt Master server
* USB flash drive plugged in router

Before running the script:

* Check the router's IP address (`$ROUTER`) (default is: **192.168.1.1**)
* Choose router's name (`$SALT_NAME`) (standarization is a good thing, perhaps consider something like: `router-` + last 6 chars of MAC address)
* Choose WireGuard address for router (`$WG_ADDRESS`) (check your WireGuard config on your Salt Master server)
* Fill out the `wireguard-config.conf` file
* Fill out the pillar files ([Create pillar config](#create-pillar-config))

Then run from your laptop:

`./setup.sh`

You will need to enter:

* Router address (default is 192.168.1.1): `$ROUTER`
* WireGuard address (without /24): `$WG_ADDRESS`
* Salt name (without spaces): `$SALT_NAME`

Rest of configuration will be done by script:

* WireGuard installed on router and configured to connect with salt-routers
* Router configured to use USB flash drive as primary drive
* Router's WireGuard link added as peer on salt-routers VM
* Router's name added in salt roster on salt-routers VM
* salt-router's ssh key added to router's dropbear key manager
* `Cannot locate OpenSSL libcrypto` error solved (after every reboot this needs to be done [manually](#fix-cannot-locate-openssl-libcrypto-error))
* Router configured with default settings (wifi ssid, password, hostname, zabbix, nordvpn installed and configured, not enabled)

## Create pillar config

It's a good idea to have a `general.sls` pillar file which would define default values for your routers. `general.sls` file should have defined:

```yaml
zabbix_server: <ZABBIX_SERVER_IP>
ssid: <WIFI_SSID>
wifi_key: <WIFI_PASSWORD>
channel2ghz: <CHANNEL_2GHz>
channel5ghz: <CHANNEL_5GHz>
lan_ip: <STATIC_LAN_IP>
```

To create specific configuration for router, create `settings-<last-6-MAC-chars>.sls` file in `/srv/pillar/` on the Salt Master server. Currently available settings:

```yaml
channel2ghz: <CHANNEL_2GHz>
channel5ghz: <CHANNEL_5GHz>
lan_ip: <STATIC_LAN_IP>
nordvpn_config: <NORDVPN_CONFIG_FILE>
nordvpn_username: <NORDVPN_USERNAME>
nordvpn_password: <NORDVPN_PASSWORD>
ssid: <WIFI_SSID>
wifi_key: <WIFI_PASSWORD>
```

If you omit some of these, the default ones defined in `general.sls` will be used.

In `top.sls` append:

```yaml
base:
  '*':
    - general
  '$SALT_NAME':
    - settings-<last-6-MAC-chars>
```

Then apply appropriate state `.sls` files from `/srv/salt/` or apply top state:

`salt-ssh $SALT_NAME state.apply`

## Fix Cannot locate OpenSSL libcrypto error

For some reason, **python's** `ctypes.util.find_library('crypto')` is not finding **libcrypto.so.1.0.0** (symlink doesn't help) so we are defining it manually using **fix_oserror.sh** script. `rsax931.py` is in `/tmp/` directory so this needs to be fixed every time router reboots. On salt-routers master, run:

`/srv/salt/fix_oserror.sh $SALT_NAME`

**UPDATE**: This problem is fixed in **OpenWRT 18.06** so this is not required anymore.

## Set-up NordVPN on router

If you have NordVPN account and you want to set it up on on router so that every device that connects is tunneled through VPN, run:

```bash
salt-ssh <minion-name> state.sls nordvpn/nordvpn_basic
```

or to target **nodegroup** (`office-wifi`, for example)

```bash
salt-ssh -N office-wifi state.sls nordvpn/nordvpn_basic
```

This will set-up basic **NordVPN** settings:

* ensure `openvpn-openssl`, `ip-full`, `luci-app-openvpn` are installed
* NordVPN interface is added
* Firewall is configured
* DNS servers are configured using NordVPN DNS
* Leak is prevented etc.

To use **NordVPN** _br-lan_ needs to be set as DHCP Server. If it's not already set (by default it is), run:

```bash
salt-ssh $SALT_NAME state.sls nordvpn/dhcp_static
```

To start using **NordVPN** config files need to be added. `/srv/salt/nordvpn/NordVPN/` contains all `.ovpn` config files which can be downloaded as zip folder from [https://nordvpn.com/api/files/zip](https://nordvpn.com/api/files/zip).

* create **pillar** file in `/srv/pillar/` and name it `settings-<last-6-MAC-chars>.sls`
* set 2 & 5 channels, static lan ip, nordvpn config file name (use the same name as in folder), username & password

```yaml
channel2ghz: 6
channel5ghz: 116
lan_ip: 172.16.24.1
nordvpn_config: de70.nordvpn.com.udp.ovpn
nordvpn_username: <nordvpn_email_account>
nordvpn_password: <nordvpn_password>
ssid: SaltRouter Private 
```

* add pillar in pillars `top.sls` file

```yaml
base:
  '*':
    - general
  'router-a7616d':
    - settings-a7616d
```

Run:

```bash
salt-ssh router-a7616d state.sls nordvpn/add_nordvpn
```

This will:

* create config folder with config name in `/etc/openvpn/`
* copy the `.ovpn` file from `/srv/salt/nordvpn/NordVPN/` to routers root folder
* create `secret` file in `/etc/openvpn/<folder>/` with **username** and **password**
* extract **ca.crt**, **ta.key** and rest of **.ovpn** config in separate files in `/etc/openvpn/<folder>/`
* append "**secret**" to **auth-user-pass** in `.ovpn` file
* set-up openvpn config with these config

## Disable NordVPN

To disable **NordVPN** (not removing it) run:

```bash
salt-ssh <minion-name> state.sls nordvpn/disable_nordvpn
```

This will:

* comment **firewall** rules in `/etc/firewall.user`
* stop **openvpn** with `/etc/init.d/openvpn stop`
* restart **firewall** 3 seconds after stopping **openvpn** with `sleep 3 && /etc/init.d/firewall restart`

## Enable NordVPN

After disabling **NordVPN**, to enable it again run:

```bash
salt-ssh <minion-name> state.sls nordvpn/enable_vpn
```

This will:

* uncomment rules in `/etc/firewall.user`
* start **openvpn** using: `/etc/init.d/openvpn start`
* restart **firewall** 3 seconds after **openvpn** starts with `sleep 3 && /etc/init.d/firewall restart`

## Upgrade firmware

Firmware update keeps configuration files but manually installed packages are lost. Exroot configuration is also lost. New firmware is saved on router's internal memory. This means that remote connection using WireGuard is also lost. Having configuration files kept, all we need to do is ensure WireGuard is installed during/after firmware upgrade.

This can be solved using [Image Builder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder). Image Builder allows us to add/delete preinstalled packages in openwrt firmware. This means we can add necessary WireGuard packages to ensure we have it installed during upgrade.

Image Builder can be downloaded for appropriate version of firmware from [this link](https://downloads.openwrt.org/releases/). In the **Supplementary Files** section of image files list, download the `openwrt-imagebuilder-OPENWRT-VERSION.Linux-x86_64.tar.gz` file. 

Extract and navigate to directory then run:

```bash
make image PACKAGES="kmod-wireguard luci-proto-wireguard wireguard wireguard-tools"
```

This will generate factory and sysupgrade files in `<path-to-image-builder-dir>/build_dir/target-*/linux-*/tmp/`.

Now we have firmware files which has WireGuard pkgs installed. Copy sysupgrade file to Salt Master in /srv/salt/firmware/ directory and run `upgrade.sls` state on desired router. 

```bash
salt-ssh <minion-name> state.sls upgrade
```

To upgrade many devices at the same time, create a nodegroup with targeted devices:

```bash
salt-ssh -N <upgrade-nodegroup> state.sls upgrade
```

## Salt state files description

Salt states (`.sls` files) are configuration files for hosts. They need to be placed in `srv/salt/`. Variables in states are defined in **pillar** files located in `/srv/pillar/<pillar-file.sls>`. State files can be applied with (e.g. apply `wifi.sls` state):

```bash
salt-ssh <host-name> state.sls wifi
```

**NOTE:** When applied, state file name is called without `.sls` extension. If state file is in folder, add the flder path (`state.sls nordvpn/enable_vpn`)

### top.sls

[Top file](https://docs.saltstack.com/en/latest/ref/states/top.html) is used for defining default states that should be applied to hosts. Current default states:

* hostname
* wifi
* zabbix
* nordvpn/nordvpn_basic

### channel2ghz.sls and channel5ghz.sls

These state files are used for setting 2ghz and 5 ghz channels and their power. Channels are set in hosts **pillar** file.

### dhcp.sls

Configures **lan** interface to bridge **eth0** (**eth0.1** on OpenWRT) and **WLAN** interfaces. No variables included.

### disable5ghz.sls

Due to problems with wireless 5ghz channel, this was used to disable it. No variables included.

### hostname.sls

Changes hostname matching [grains id](https://docs.saltstack.com/en/latest/topics/grains/) essentially becoming the same as `$SALT_NAME`.

### power2ghz.sls and power5ghz.sls

Used for setting power on 2ghz and 5ghz channels. Now part of `channel2ghz.sls` and `channel5ghz.sls`.

### wifi.sls

Sets wifi ssid, enables wifi if disabled, sets wifi password and reloads wifi. Variables **pillar['ssid']** and **pillar['wifi_key']** define wifi name and password respectively. They need to be defined in **pillar** file. If not, default value will be used (ssid defined in pillar and it's password)

### zabbix.sls

Installs OpenWRT packages:

* zabbix-agentd
* zabbix-extra-mac80211
* zabbix-extra-network
* zabbix-extra-wifi

Sends zabbix configuration file (`zabbix_agend.conf`) to host, creates `zabbix_agentd.conf.d` directory and sets Zabbix server address (defined in `/srv/pillar/general.sls`)

### nordvpn/nordvpn_basic.sls

Installs packages on OpenWRT host:

* openvpn-openssl
* ip-full
* luci-app-openvpn

Adds `nordvpntun` interface, `vpnfirewall` zone, adds DNS servers to wan interface, appends `firewall.user` config and sends `99-prevent-leak` and `reconnect.sh` to host and includes it in `rc.local` file.

### nordvpn/add_nordvpn.sls

This state will add nordvpn configuration to host file and enable it. It:

* creates directory on host for openvpn config file and sends it to host (defined in pillar file as `nordvpn_config`)
* sets `lan` interface to have static address (defined in pillar as `lan_ip`), bridges eth0 (eth0.1 in OpenWRT) and wlan interfaces
* sets NordVPN username and password (defined in pillar file as `nordvpn_username` and `nordvpn_password`) in `secret` file
* extracts certificate and tls-auth in separate `ca.crt` and `ta.key` files.
* creates `openvpn.log` file and enables logging to that file
* sets openvpn to use config file and enables autostart
* restarts openvpn to load config

### nordvpn/disable_vpn.sls

Disables nordvpn interface:

* comments rule in `/etc/firewall.user`
* stops openvpn and disables autostart
* restarts firewall 3 seconds after openvpn stop command

### nordvpn/enable_vpn.sls

Asuming nordvpn config is present, but disabled on host, reenables nordvpn interface:

* uncomments rules in `/etc/firewall.user`
* starts and enables autostart of openvpn
* restarts firewall 3 seconds after starting openvpn

### upgrade.sls

**Before runing this state, make sure you read instructions for [Upgrading Firmware] with WireGuard package added to sysupgrade file. Otherwise, you will LOSE remote access to router** 

Asuming you have firmware upgrade file, it will:

* copy firmware file to routers `/tmp/` directory
* run `sysupgrade -F /tmp/{{ firmware }}'

## Contact and contributing

Please contact `tech@occrp.org` with any questions, patches, suggestions, and complaints.

## Authors

Kenan Ibrović `<kenan@occrp.org>`

