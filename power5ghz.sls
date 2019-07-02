set 5ghz power:
  file.replace:
    - name: /etc/config/wireless
    - pattern: ((config wifi-device 'radio0')\n.+)\n(.+option txpower.+\n)
    - repl: \1\n\toption txpower '27'\n
