
#!/bin/bash
#############################################################
# V2ray & Shadowsocks for Alwaysdata.com
# Repo: mrsoul00/v2
#############################################################

TMP_DIRECTORY=$(mktemp -d)

# Cleanup Windows carriage returns and fetch existing settings if present
SITES_CONF="$HOME/admin/config/apache/sites.conf"
if [ -f "$SITES_CONF" ]; then
    UUID_VAL=$(grep -o 'UUID=[^ ]*' "$SITES_CONF" | head -n 1 | cut -d'=' -f2 | tr -d '\r')
    VMESS_VAL=$(grep -o 'VMESS_WSPATH=[^ ]*' "$SITES_CONF" | head -n 1 | cut -d'=' -f2 | tr -d '\r')
    VLESS_VAL=$(grep -o 'VLESS_WSPATH=[^ ]*' "$SITES_CONF" | head -n 1 | cut -d'=' -f2 | tr -d '\r')
    SS_VAL=$(grep -o 'SS_WSPATH=[^ ]*' "$SITES_CONF" | head -n 1 | cut -d'=' -f2 | tr -d '\r')
fi

UUID=${UUID_VAL:-'de04add9-5c68-8bab-950c-08cd5320df18'}
VMESS_WSPATH=${VMESS_VAL:-'/vmess'}
VLESS_WSPATH=${VLESS_VAL:-'/vless'}
SS_WSPATH=${SS_VAL:-'/ss'}
URL="${USER}.alwaysdata.net"

# Download config.json directly from your GitHub repo
wget -q -O "$TMP_DIRECTORY/config.json" "https://raw.githubusercontent.com/mrsoul00/v2/refs/heads/main/config.json"

# Download v2ray core release
wget -q -O "$TMP_DIRECTORY/v2ray-linux-64.zip" "https://github.com/v2fly/v2ray-core/releases/download/v4.45.2/v2ray-linux-64.zip"
unzip -oq -d "$HOME" "$TMP_DIRECTORY/v2ray-linux-64.zip" v2ray v2ctl geoip.dat geosite.dat

# Replace variables in config.json
sed -i "s#UUID#$UUID#g" "$TMP_DIRECTORY/config.json"
sed -i "s#VMESS_WSPATH#$VMESS_WSPATH#g" "$TMP_DIRECTORY/config.json"
sed -i "s#VLESS_WSPATH#$VLESS_WSPATH#g" "$TMP_DIRECTORY/config.json"
sed -i "s#SS_WSPATH#$SS_WSPATH#g" "$TMP_DIRECTORY/config.json"
sed -i "s#127.0.0.1#0.0.0.0#g" "$TMP_DIRECTORY/config.json"

cp "$TMP_DIRECTORY/config.json" "$HOME/"
rm -rf "$HOME/admin/tmp/"*.*

# Prepare Apache Advanced Settings block
Advanced_Settings="#UUID=${UUID}
#VMESS_WSPATH=${VMESS_WSPATH}
#VLESS_WSPATH=${VLESS_WSPATH}
#SS_WSPATH=${SS_WSPATH}

ProxyRequests off
ProxyPreserveHost On

ProxyPass ${VMESS_WSPATH} ws://services-${USER}.alwaysdata.net:10000${VMESS_WSPATH}
ProxyPassReverse ${VMESS_WSPATH} ws://services-${USER}.alwaysdata.net:10000${VMESS_WSPATH}

ProxyPass ${VLESS_WSPATH} ws://services-${USER}.alwaysdata.net:20000${VLESS_WSPATH}
ProxyPassReverse ${VLESS_WSPATH} ws://services-${USER}.alwaysdata.net:20000${VLESS_WSPATH}

ProxyPass ${SS_WSPATH} ws://services-${USER}.alwaysdata.net:30000${SS_WSPATH}
ProxyPassReverse ${SS_WSPATH} ws://services-${USER}.alwaysdata.net:30000${SS_WSPATH}"

# Generate node URI links
vmlink="vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"AlwaysData-VMess\",\"add\":\"$URL\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$URL\",\"path\":\"$VMESS_WSPATH\",\"tls\":\"tls\"}" | base64 -w 0)"
vllink="vless://${UUID}@${URL}:443?encryption=none&security=tls&type=ws&host=${URL}&path=${VLESS_WSPATH}#AlwaysData-VLess"

ss_raw="aes-128-gcm:${UUID}@${URL}:443"
ss_base64=$(echo -n "$ss_raw" | base64 -w 0)
sslink="ss://${ss_base64}?plugin=v2ray-plugin%3Bmode%3Dwebsocket%3Bpath%3D${SS_WSPATH}%3Bhost%3D${URL}%3Btls#AlwaysData-SS"

# Generate QR code images
mkdir -p "$HOME/www"
qrencode -o "$HOME/www/M${UUID}.png" "$vmlink"
qrencode -o "$HOME/www/L${UUID}.png" "$vllink"
qrencode -o "$HOME/www/S${UUID}.png" "$sslink"

cat > "$HOME/www/index.html" <<EOF
<html>
<head><title>Welcome</title></head>
<body><div align="center"><b>Server Running...</b></div></body>
</html>
EOF

cat > "$HOME/www/${UUID}.html" <<EOF
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Node Configuration Links</title>
<style>
body { font-family: sans-serif; padding: 20px; }
div { margin-bottom: 15px; word-break: break-all; max-width: 90%; }
</style>
</head>
<body>
<div><font color="#009900"><b>VMESS Link:</b></font></div>
<div>$vmlink</div>
<div><img src="/M${UUID}.png"></div>

<div><font color="#009900"><b>VLESS Link:</b></font></div>
<div>$vllink</div>
<div><img src="/L${UUID}.png"></div>
