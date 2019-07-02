change wifi name:
  file.line:
    - name: /etc/config/wireless
    - content: "option ssid '{{ pillar['ssid'] }}'"
    - match: "ssid"
    - mode: replace

enable wifi:
  file.line:
    - name: /etc/config/wireless
    - content: 
    - match: "disabled"
    - mode: delete

remove password if exists:
  file.line:
    - name: /etc/config/wireless
    - content: 
    - match: "option key"
    - mode: delete

set encryption and password:
  file.line:
    - name: /etc/config/wireless
    - content: "option encryption 'psk2'\n\toption key '{{ pillar['wifi_key'] }}'"
    - match: 'option encryption'
    - mode: replace

reload_wifi:
  cmd.run:
    - name: wifi
