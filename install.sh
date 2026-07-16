#!/bin/bash
#############################################################
# Xray VLESS for Alwaysdata.com
#############################################################

TMP_DIRECTORY=$(mktemp -d)

VLESS_WSPATH=$(grep -o 'VLESS_WSPATH=[^ ]*' $HOME/admin/config/apache/sites.conf 2>/dev/null | sed 's/VLESS_WSPATH=//')
UUID=$(grep -o 'UUID=[^ ]*' $HOME/admin/config/apache/sites.conf 2>/dev/null | sed 's/UUID=//')

UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}
VLESS_WSPATH=${VLESS_WSPATH:-'/vless'}
URL=${USER}.alwaysdata.net

echo "=============================================="
echo "Installing VLESS for Alwaysdata"
echo "Domain: $URL"
echo "UUID: $UUID"
echo "Path: $VLESS_WSPATH"
echo "=============================================="

wget -q -O $TMP_DIRECTORY/config.json https://raw.githubusercontent.com/mrsoul00/v2/refs/heads/main/config.json
wget -q -O $TMP_DIRECTORY/xray.zip https://github.com/XTLS/Xray-core/releases/download/v1.8.23/Xray-linux-64.zip
unzip -oq -d $HOME $TMP_DIRECTORY/xray.zip xray geoip.dat geosite.dat

sed -i "s#UUID#$UUID#g" $TMP_DIRECTORY/config.json
sed -i "s#VLESS_WSPATH#$VLESS_WSPATH#g" $TMP_DIRECTORY/config.json
sed -i "s#20000#8400#g" $TMP_DIRECTORY/config.json
sed -i "s#127.0.0.1#0.0.0.0#g" $TMP_DIRECTORY/config.json

cp $TMP_DIRECTORY/config.json $HOME/config.json
chmod +x $HOME/xray
rm -rf $HOME/admin/tmp/*.*
rm -rf $TMP_DIRECTORY

Advanced_Settings=$(cat <<-EOF
#UUID=${UUID}
#VLESS_WSPATH=${VLESS_WSPATH}

ProxyRequests off
ProxyPreserveHost On
ProxyPass "${VLESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8400${VLESS_WSPATH}"
ProxyPassReverse "${VLESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8400${VLESS_WSPATH}"
EOF
)

vllink="vless://"$UUID"@"$URL":443?encryption=none&security=tls&type=ws&host="$URL"&path="$VLESS_WSPATH"#Alwaysdata-VLESS"

cat > $HOME/www/index.html <<-EOF
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>VLESS Connection</title>
<style>
body { font-family: Geneva, Arial, Helvetica, san-serif; background: #1a1a2e; color: #eee; }
div { margin: 20px auto; text-align: left; white-space: pre-wrap; word-break: break-all; max-width: 80%; padding: 15px; background: #16213e; border-radius: 10px; margin-bottom: 15px; }
.link { background: #0f3460; color: #00ff88; padding: 15px; border-radius: 8px; font-family: monospace; font-size: 13px; }
</style>
</head>
<body>
<div align="center"><h2>⚡ VLESS Connection</h2></div>
<div><b>🔗 VLESS Link:</b><br><span class="link">$vllink</span></div>
<div><b>📋 Config Info:</b><br>
Address: $URL<br>
Port: 443<br>
Protocol: VLESS<br>
UUID: $UUID<br>
Encryption: none<br>
Network: ws<br>
Path: $VLESS_WSPATH<br>
TLS: tls</div>
</body>
</html>
EOF

clear

echo ""
echo "=============================================="
echo "     VLESS Installation Complete! ⚡"
echo "=============================================="
echo ""
echo "1. Copy this to SERVICE Command:"
echo "   ./xray -config config.json"
echo ""
echo "2. Copy this to Apache Advanced Settings:"
echo "$Advanced_Settings"
echo ""
echo "3. Your VLESS Link:"
echo "$vllink"
echo ""
echo "4. Visit:"
echo "   https://$URL/index.html"
echo ""
echo "=============================================="
