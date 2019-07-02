
edit 2ghz channel & set txpower:
  file.blockreplace:
    - name: /etc/config/wireless
    - marker_start: "config wifi-device 'radio1'"
    - marker_end: "config"
    {% if grains['os'] == 'OpenWrt' %}
    - content: "\toption type 'mac80211'\n\toption channel '{{ pillar['channel2ghz'] }}'\n\toption hwmode '11g'\n\toption path 'soc/soc:pcie/pci0000:00/0000:00:02.0/0000:02:00.0'\n\toption htmode 'HT20'\n\toption country 'DE'\n\toption txpower '20'\n\n"
    {% else %}
    - content: "\toption type 'mac80211'\n\toption channel '{{ pillar['channel2ghz'] }}'\n\toption hwmode '11g'\n\toption path 'soc/soc:pcie-controller/pci0000:00/0000:00:02.0/0000:02:00.0'\n\toption htmode 'HT20'\n\toption country 'DE'\n\toption txpower '20'\n\n"
    {% endif %}
    - show_changes: True

edit 5ghz channel and set txpower:
  file.blockreplace:
    - name: /etc/config/wireless
    - marker_start: "config wifi-device 'radio0'"
    - marker_end: "config"
    {% if grains['os'] == 'OpenWrt' %}
    - content: "\toption type 'mac80211'\n\toption channel '{{ pillar['channel5ghz'] }}'\n\toption hwmode '11a'\n\toption path 'soc/soc:pcie/pci0000:00/0000:00:01.0/0000:01:00.0'\n\toption htmode 'VHT80'\n\toption country 'DE'\n\toption txpower '27'\n\n"
    {% else %}
    - content: "\toption type 'mac80211'\n\toption channel '{{ pillar['channel5ghz'] }}'\n\toption hwmode '11a'\n\toption path 'soc/soc:pcie-controller/pci0000:00/0000:00:01.0/0000:01:00.0'\n\toption htmode 'VHT80'\n\toption country 'DE'\n\toption txpower '27'\n\n"
    {% endif %}
    - show_changes: True

reload wifi:
  cmd.run:
    - name: wifi
