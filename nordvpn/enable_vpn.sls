enable prevent traffic leakage rule 1st line:
  file.uncomment:
    - name: /etc/firewall.user
    - regex: ^if.+

enable prevent traffice leakage rule 2nd line:
  file.uncomment:
    - name: /etc/firewall.user
    - regex: ^\t.+

enable prevent traffice leakage rule 3rd line:
  file.uncomment:
    - name: /etc/firewall.user
    - regex: ^fi
  
start openvpn and enable autostart:
  cmd.run:
    - names:
      - /etc/init.d/openvpn start 
      - /etc/init.d/openvpn enable    

# wait 3 seconds after openvpn starts to restart firewall
restart firewall:
  cmd.run:
    - name: sleep 3 && /etc/init.d/firewall restart
    - onchanges:
      - cmd: /etc/init.d/openvpn start

