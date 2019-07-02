disable prevent traffic leakage rule 1st line:
  file.comment:
    - name: /etc/firewall.user
    - regex: ^if.+

disable prevent traffice leakage rule 2nd line:
  file.comment:
    - name: /etc/firewall.user
    - regex: ^\t.+

disable prevent traffice leakage rule 3rd line:
  file.comment:
    - name: /etc/firewall.user
    - regex: ^fi
  
stop openvpn and disable autostart:
  cmd.run:
    - names:
      - /etc/init.d/openvpn stop
      - /etc/init.d/openvpn disable

# wait 3 seconds after /etc/init.d/openvpn stop command to restart firewall
restart firewall:
  cmd.run:
    - name: sleep 3 && /etc/init.d/firewall restart
    - onchanges:
      - cmd: /etc/init.d/openvpn stop
