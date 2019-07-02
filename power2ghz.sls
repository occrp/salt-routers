set 2ghz power:
  file.replace:
    - name: /etc/config/wireless
    - pattern: ((config wifi-device 'radio1')\n.+)\n(.+option txpower.+\n)
    - repl: \1\n\toption txpower '20'\n
