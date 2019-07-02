disable 5ghz channel:
  file.line:
    - name: /etc/config/wireless
    - content: "	option disabled '1'"
    - mode: ensure
    - after: config wifi-iface 'default_radio0'
