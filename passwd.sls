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
