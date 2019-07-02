nordvpn_packages:
  pkg.installed:
    - pkgs:
      - openvpn-openssl
      - ip-full
      - luci-app-openvpn

network_config:
  file.replace:
    - name: /etc/config/network
    - pattern: config interface 'nordvpntun'\n.+option proto 'none'\n.+option ifname 'tun0'
    - repl: "config interface 'nordvpntun'\n\toption proto 'none'\n\toption ifname 'tun0'\n"
    - append_if_not_found: True

firewall_zone_config:
  file.replace:
    - name: /etc/config/firewall
    - pattern: (((config zone\n.+option name 'vpnfirewall')\n.+)\n.+)\n(.+\n)+
    - repl: "config zone\n\toption name 'vpnfirewall'\n\toption input 'REJECT'\n\toption output 'ACCEPT'\n\toption forward 'REJECT'\n\toption masq '1'\n\toption mtu_fix '1'\n\tlist network 'nordvpntun'\n"
    - append_if_not_found: True

firewall_forwarding_config:
  file.replace:
    - name: /etc/config/firewall
    - pattern: config forwarding\n.+option src 'lan'\n.+option dest 'vpnfirewall'\n
    - repl: "config forwarding\n\toption src 'lan'\n\toption dest 'vpnfirewall'\n"
    - append_if_not_found: True


DNS_servers_config:
  cmd.run:
    - names:
      - uci set network.wan.peerdns='0'
      - uci del network.wan.dns
      - uci add_list network.wan.dns='103.86.96.100'
      - uci add_list network.wan.dns='103.86.99.100'
      - uci commit

firewall_user_config:
  file.replace:
    - name: /etc/firewall.user
    - pattern: if \(! ip a s tun0 up.+\n.+\n.+
    - repl: "#if (! ip a s tun0 up) && (! iptables -C forwarding_rule -j REJECT); then\n#\tiptables -I forwarding_rule -j REJECT\n#fi"
    - append_if_not_found: True


prevent_leak:
  file.managed:
    - name: /etc/hotplug.d/iface/99-prevent-leak
    - source: salt://nordvpn/99-prevent-leak 

solve_couldnt_resolve_host_error:
  file.replace:
    - name: /etc/rc.local
    - pattern: "/etc/openvpn/reconnect.sh &\n"
    - repl: "/etc/openvpn/reconnect.sh &\n"
    - prepend_if_not_found: True

reconnect_script:
  file.managed:
    - name: /etc/openvpn/reconnect.sh
    - source: salt://nordvpn/reconnect.sh
    - makedirs: True

