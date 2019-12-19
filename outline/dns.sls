set_dns:
  cmd.run:
    - names:
      - uci set network.lan.dns='208.67.222.222 208.67.220.220'
      - uci set network.wan.peerdns='0'
      - uci set network.wan6.peerdns='0'
      - uci commit network
      - /etc/init.d/network reload
