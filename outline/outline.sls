outline_pkgs:
  pkg.installed:
    - pkgs:
      - shadowsocks-client
      - shadowsocks-libev-config
      - shadowsocks-libev-ss-redir
      - shadowsocks-libev-ss-rules
      - luci-app-shadowsocks-libev
      - iptables-mod-tproxy

shadowsocks_config_file:
  file.managed:
    - source: salt://managed/etc/config/shadowsocks-libev
    - name: /etc/config/shadowsocks-libev
    - template: jinja

start_shadowsocks:
  cmd.run:
    - names:
      - /etc/init.d/shadowsocks-libev enable
      - /etc/init.d/firewall restart
