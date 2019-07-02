create_config_folder:
  cmd.run:
    - name: mkdir /etc/openvpn/{{ pillar['nordvpn_config'] }}

copy_config_file:
  file.managed:
    - name: /root/{{ pillar['nordvpn_config'] }}
    - source: salt://nordvpn/NordVPN/{{ pillar['nordvpn_config'] }}

set lan to static dhcp:
  file.blockreplace:
    - name: /etc/config/network
    - marker_start: "config interface 'lan'"
    - marker_end: "config interface"
    {% if grains['os'] == 'OpenWrt' %}
    - content: "\toption type 'bridge'\n\toption ifname 'eth0.1'\n\toption proto 'static'\n\toption ipaddr '{{ pillar['lan_ip'] }}'\n\toption netmask '255.255.255.0'\n\toption ip6assign '60'\n\n"
    {% else %}
    - content: "\toption type 'bridge'\n\toption ifname 'eth0'\n\toption _orig_ifname 'eth0 radio0.network1 radio1.network1'\n\toption _orig_bridge 'true'\n\toption proto 'static'\n\toption ipaddr '{{ pillar['lan_ip'] }}'\n\toption netmask '255.255.255.0'\n\n"
    {% endif %}
    - show_changes: True

setup_nordvpn_config:
  cmd.run:
    - names: 
      - echo {{ pillar['nordvpn_username'] }} > /etc/openvpn/{{ pillar['nordvpn_config'] }}/secret  
      - echo {{ pillar['nordvpn_password'] }} >> /etc/openvpn/{{ pillar['nordvpn_config'] }}/secret 
      - awk '/<ca>/{flag=1; next} /<\/ca>/{flag=0} flag' /root/{{ pillar['nordvpn_config'] }} > /etc/openvpn/{{ pillar['nordvpn_config'] }}/ca.crt
      - awk '/<tls-auth>/{flag=1; next} /<\/tls-auth>/{flag=0} flag' /root/{{ pillar['nordvpn_config'] }} > /etc/openvpn/{{ pillar['nordvpn_config'] }}/ta.key
      - awk '/client/{flag=1} /<ca>/{flag=0} flag' {{ pillar['nordvpn_config'] }} > /etc/openvpn/{{ pillar['nordvpn_config'] }}/{{ pillar['nordvpn_config'] }}
      - echo 'ca ca.crt' >> /etc/openvpn/{{ pillar['nordvpn_config'] }}/{{ pillar['nordvpn_config'] }}
      - echo 'tls-auth ta.key 1' >> /etc/openvpn/{{ pillar['nordvpn_config'] }}/{{ pillar['nordvpn_config'] }}
      - echo 'log openvpn.log' >> /etc/openvpn/{{ pillar['nordvpn_config'] }}/{{ pillar['nordvpn_config'] }}
      - sed -i 's/auth-user-pass/auth-user-pass secret/' /etc/openvpn/{{ pillar['nordvpn_config'] }}/{{ pillar['nordvpn_config'] }}
      - sed -i 's/verb.*/verb 4/' /etc/openvpn/{{ pillar['nordvpn_config'] }}/{{ pillar['nordvpn_config'] }}
      - uci set openvpn.nordvpn=openvpn
      - uci set openvpn.nordvpn.enabled='1'
      - uci set openvpn.nordvpn.config='/etc/openvpn/{{ pillar['nordvpn_config'] }}/{{ pillar['nordvpn_config'] }}'
      - uci commit openvpn
      - /etc/init.d/openvpn enable
      - /etc/init.d/openvpn restart

