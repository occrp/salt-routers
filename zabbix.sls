install zabbix-agent:
    pkg.installed:
        - refresh: True
        - pkgs:
            - zabbix-agentd
            - zabbix-extra-mac80211
            - zabbix-extra-network
            - zabbix-extra-wifi

zabbix config file:
    file.managed:
        - name: /etc/zabbix_agentd.conf
        - source: salt://managed/etc/zabbix_agentd.conf

zabbix config directory:
    file.directory:
        - name: /etc/zabbix_agentd.conf.d
        
zabbix server config:
    file.append:
        - name: /etc/zabbix_agentd.conf.d/local.serveractive.conf
        - text: ServerActive={{ pillar['zabbix_server'] }}
