set hostname:
  file.line:
    - name: /etc/config/system
    - content: "option hostname '{{ grains['id'] }}'"
    - match: "option hostname"
    - mode: replace
