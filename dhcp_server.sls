disable dhcp:
  file.blockreplace:
    - name: /etc/config/network
    - marker_start: "config interface 'lan'"
    - marker_end: "config interface"
    {% if grains['os'] == 'OpenWrt' %}
    - content: "\toption type 'bridge'\n\toption ifname 'eth0.1'\n\toption _orig_ifname 'eth0.1 radio0.network1 radio1.network1'\n\toption _orig_bridge 'true'\n\toption proto 'static'\n\toption ipaddr '{{ pillar['lan_ip'] }}'\n\toption netmask '255.255.255.0'\n\n"
    {% else %}
    - content: "\toption type 'bridge'\n\toption ifname 'eth0'\n\toption _orig_ifname 'eth0 radio0.network1 radio1.network1'\n\toption _orig_bridge 'true'\n\toption proto 'static'\n\toption ipaddr '{{ pillar['lan_ip'] }}'\n\toption netmask '255.255.255.0'\n\n"
    {% endif %}
    - show_changes: True

reboot:
  cmd.run:
    - name: reboot
