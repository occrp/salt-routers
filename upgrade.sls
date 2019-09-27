{% set firmware = 'openwrt-18.06.4-mvebu-cortexa9-linksys-wrt1200ac-squashfs-sysupgrade.bin' %}

move firmware to router:
  file.managed:
    - name: /tmp/{{ firmware }} 
    - source: salt://firmware/{{ firmware }}

upgrade firmware:
  cmd.run:
    - name: sysupgrade -F /tmp/{{ firmware }}

