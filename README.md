## Setup WireGuard and Salt on OpenWRT Router

Clone [salt-routers](https://git.occrp.org/libre/salt-routers) repository on your laptop:

```
git clone https://git.occrp.org/rysiek/salt-routers.git
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

Then run from your laptop:

`./setup.sh`

You will need to enter:

* Router address: `$ROUTER`
* WireGuard address (without /24): `$WG_ADDRESS`
* Salt name (without spaces): `$SALT_NAME`

Rest of configuration will be done by script:

* WireGuard installed on router and configured to connect with salt-routers
* Router configured to use USB flash drive as primary drive
* Router's WireGuard link added as peer on salt-routers VM
* Router's name added in salt roster on salt-routers VM
* salt-router's ssh key added to router's dropbear key manager
* `Cannot locate OpenSSL libcrypto` error solved (after every reboot this needs to be done [manually](#fix-cannot-locate-openssl-libcrypto-error))
* Router configured with default settings (wifi ssid, password, hostname, zabbix, nordvpn installed and configured and disabled, 5ghz channel disabled)

## Create pillar config

To create specific configuration for router, create `settings-<last-6-MAC-chars>.sls` file in `/srv/pillar/` on the Salt Master server. Currently available settings:

```yaml
channel2ghz: <CHANNEL 2>
channel5ghz: <CHANNEL 5>
lan_ip: <STATIC LAN IP>
nordvpn_config: <NORDVPN CONFIG FILE>
nordvpn_username: <USERNAME>
nordvpn_password: <PASSWORD>
ssid: <WIFI SSID>
wifi_key: <WIFI PASS>
```

If you omit some of these, the default ones defined in `general.sls` will be used.

**NOTE:** default setting for channel2 is **1**, and for channel5: **112**.

In `top.sls` append:

```yaml
base:
  '*':
    - general
  '$SALT_NAME':
    - settings-<last-6-MAC-chars>
```

Then run appropriate state `.sls` files from `/srv/salt/` or apply top state:

`salt-ssh $SALT_NAME state.apply`

## Fix Cannot locate OpenSSL libcrypto error

For some reason, **python's** `ctypes.util.find_library('crypto')` is not finding **libcrypto.so.1.0.0** (symlink doesn't help) so we are defining it manually using **fix_oserror.sh** script. `rsax931.py` is in `/tmp/` directory so this needs to be fixed every time router reboots. On salt-routers VM, run:

`/srv/salt/fix_oserror.sh $SALT_NAME`

## Set-up NordVPN on salt-router

After having **salt** set-up on router, run:

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
ssid: RigaConference2018
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

## Salt state files

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
* channel2ghz
* channel5ghz
* nordvpn/nordvpn_basic
* disable5ghz

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

Sets wifi ssid, enables wifi if disabled, sets wifi password and reloads wifi. Variables **pillar['ssid']** and **pillar['wifi_key']** define wifi name and password respectively. They need to be defined in **pillar** file. If not, default value will be used (ssid: `Nije nama lako` and it's password)

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


## Contact and contributing

Please contact `tech@occrp.org` with any questions, patches, suggestions, and complaints.
