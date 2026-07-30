#!/bin/bash
#############################################################
# V2ray & Shadowsocks for Alwaysdata.com
# Repo: mrsoul00/v2
#############################################################

TMP_DIRECTORY=$(mktemp -d)

# استخراج یا مقداردهی متغیرها
UUID=$(grep -o 'UUID=[^ ]*' $HOME/admin/config/apache/sites.conf | sed 's/UUID=//')
VMESS_WSPATH=$(grep -o 'VMESS_WSPATH=[^ ]*' $HOME/admin/config/apache/sites.conf | sed 's/VMESS_WSPATH=//')
VLESS_WSPATH=$(grep -o 'VLESS_WSPATH=[^ ]*' $HOME/admin/config/apache/sites.conf | sed 's/VLESS_WSPATH=//')
SS_WSPATH=$(grep -o 'SS_WSPATH=[^ ]*' $HOME/admin/config/apache/sites.conf | sed 's/SS_WSPATH=//')

UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
VMESS_WSPATH=${VMESS_WSPATH:-'/vmess'}
VLESS_WSPATH=${VLESS_WSPATH:-'/vless'}
SS_WSPATH=${SS_WSPATH:-'/ss'}
URL=${USER}.alwaysdata.net

# دانلود config.json مستقیم از ریپازیتوری شما
wget -q -O $TMP_DIRECTORY/config.json https://raw.githubusercontent.com/mrsoul00/v2/refs/heads/main/config.json

# دانلود هسته v2ray
wget -q -O $TMP_DIRECTORY/v2ray-linux-64.zip https://github.com/v2fly/v2ray-core/releases/download/v4.45.2/v2ray-linux-64.zip
unzip -oq -d $HOME $TMP_DIRECTORY/v2ray-linux-64.zip v2ray v2ctl geoip.dat geosite.dat

# جایگزینی متغیرها در config.json بدون تغییر پورت‌ها
sed -i "s#UUID#$UUID#g;s#VMESS_WSPATH#$VMESS_WSPATH#g;s#VLESS_WSPATH#$VLESS_WSPATH#g;s#SS_WSPATH#$SS_WSPATH#g;s#127.0.0.1#0.0.0.0#g" $TMP_DIRECTORY/config.json
cp $TMP_DIRECTORY/config.json $HOME
rm -rf $HOME/admin/tmp/*.*

# تنظیمات پیشرفته Apache بر اساس پورت‌های شما
Advanced_Settings=$(cat <<-EOF
#UUID=${UUID}
#VMESS_WSPATH=${VMESS_WSPATH}
#VLESS_WSPATH=${VLESS_WSPATH}
#SS_WSPATH=${SS_WSPATH}

ProxyRequests off
ProxyPreserveHost On

ProxyPass "${VMESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:10000${VMESS_WSPATH}"
ProxyPassReverse "${VMESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:10000${VMESS_WSPATH}"

ProxyPass "${VLESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:20000${VLESS_WSPATH}"
ProxyPassReverse "${VLESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:20000${VLESS_WSPATH}"

ProxyPass "${SS_WSPATH}" "ws://services-${USER}.alwaysdata.net:30000${SS_WSPATH}"
ProxyPassReverse "${SS_WSPATH}" "ws://services-${USER}.alwaysdata.net:30000${SS_WSPATH}"
EOF
)

# ساخت لینک‌های کانفیگ
vmlink=vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"AlwaysData-VMess\",\"add\":\"$URL\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$URL\",\"path\":\"$VMESS_WSPATH\",\"tls\":\"tls\"}" | base64 -w 0)
vllink="vless://"$UUID"@"$URL":443?encryption=none&security=tls&type=ws&host="$URL"&path="$VLESS_WSPATH"#AlwaysData-VLess"

ss_raw="aes-128-gcm:${UUID}@${URL}:443"
ss_base64=$(echo -n "$ss_raw" | base64 -w 0)
sslink="ss://${ss_base64}?plugin=v2ray-plugin%3Bmode%3Dwebsocket%3Bpath%3D${SS_WSPATH}%3Bhost%3D${URL}%3Btls#AlwaysData-SS"

# تولید QR کدها
qrencode -o $HOME/www/M$UUID.png $vmlink
qrencode -o $HOME/www/L$UUID.png $vllink
qrencode -o $HOME/www/S$UUID.png $sslink

cat > $HOME/www/index.html<<-EOF
<html>
<head><title>Welcome</title></head>
<body><div align="center"><b>Server Running...</b></div></body>
</html>
EOF

# ساخت صفحه دریافت کانفیگ‌ها
cat > $HOME/www/$UUID.html<<-EOF
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Node Configs</title>
<style>
body { font-family: sans-serif; padding: 20px; }
div { margin-bottom: 15px; word-break: break-all; max-width: 90%; }
</style>
</head>
<body>
<div><font color="#009900"><b>VMESS Link:</b></font></div>
<div>$vmlink</div>
<div><img src="/M$UUID.png"></div>

<div><font color="#009900"><b>VLESS Link:</b></font></div>
<div>$vllink</div>
<div><img src="/L$UUID.png"></div>

<div><font color="#009900"><b>Shadowsocks Link:</b></font></div>
<div>$sslink</div>
<div><img src="/S$UUID.png"></div>
</body>
</html>
EOF

clear

echo -e "\n\e[33mکد زیر را در بخش SERVICE Command وارد کنید:\n\e[0m"
echo -e "\e[32m./v2ray -config config.json\e[0m"

echo -e "\n\e[33mکد زیر را در بخش Advanced Settings وارد کنید:\n\e[0m"
echo -e "\e[32m$Advanced_Settings\e[0m"

echo -e "\n\e[33mجهت دریافت لینک‌ها و QR کدها به این آدرس مراجعه کنید:\n\e[0m"
echo -e "\e[32mhttps://$URL/$UUID.html\n\e[0m"
