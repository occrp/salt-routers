{% if grains['os'] == 'LEDE' %}
  {% set firmware = 'openwrt-18.06.2-mvebu-cortexa9-linksys-wrt1200ac-squashfs-sysupgrade.bin' %}
{% elif grains['os'] == 'OpenWrt' %}
  {% set firmware = 'lede-17.01.6-mvebu-linksys-wrt1200ac-squashfs-factory.img' %}
{% endif %}


ensure wireguard is installed:
  file.replace:
    - name: /etc/rc.local
    - pattern: "sleep 5\nopkg update\nopkg install wireguard kmod-wireguard\n/etc/init.d/network restart\n/etc/init.d/firewall restart\n"
    - repl: "sleep 5\nopkg update\nopkg install wireguard kmod-wireguard\n/etc/init.d/network restart\n/etc/init.d/firewall restart\n"
    - prepend_if_not_found: True

move firmware to router:
  file.managed:
    - name: /tmp/{{ firmware }} 
    - source: salt://firmware/{{ firmware }}

upgrade firmware:
  cmd.run:
    - name: sysupgrade -F /tmp/{{ firmware }}

