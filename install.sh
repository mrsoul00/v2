#!/bin/bash
#############################################################
# Xray for Alwaysdata.com
#############################################################

TMP_DIRECTORY=$(mktemp -d)

UUID=$(grep -o 'UUID=[^ ]*' $HOME/admin/config/apache/sites.conf 2>/dev/null | sed 's/UUID=//')
VMESS_WSPATH=$(grep -o 'VMESS_WSPATH=[^ ]*' $HOME/admin/config/apache/sites.conf 2>/dev/null | sed 's/VMESS_WSPATH=//')
VLESS_WSPATH=$(grep -o 'VLESS_WSPATH=[^ ]*' $HOME/admin/config/apache/sites.conf 2>/dev/null | sed 's/VLESS_WSPATH=//')

UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}
VMESS_WSPATH=${VMESS_WSPATH:-'/vmess'}
VLESS_WSPATH=${VLESS_WSPATH:-'/vless'}
URL=${USER}.alwaysdata.net

echo "=============================================="
echo "Installing Xray for Alwaysdata"
echo "Domain: $URL"
echo "=============================================="

wget -q -O $TMP_DIRECTORY/config.json https://raw.githubusercontent.com/mrsoul00/v2/refs/heads/main/config.json
wget -q -O $TMP_DIRECTORY/xray.zip https://github.com/XTLS/Xray-core/releases/download/v1.8.23/Xray-linux-64.zip
unzip -oq -d $HOME $TMP_DIRECTORY/xray.zip xray geoip.dat geosite.dat

sed -i "s#UUID#$UUID#g" $TMP_DIRECTORY/config.json
sed -i "s#VMESS_WSPATH#$VMESS_WSPATH#g" $TMP_DIRECTORY/config.json
sed -i "s#VLESS_WSPATH#$VLESS_WSPATH#g" $TMP_DIRECTORY/config.json
sed -i "s#10000#8300#g" $TMP_DIRECTORY/config.json
sed -i "s#20000#8400#g" $TMP_DIRECTORY/config.json
sed -i "s#127.0.0.1#0.0.0.0#g" $TMP_DIRECTORY/config.json

cp $TMP_DIRECTORY/config.json $HOME/config.json
chmod +x $HOME/xray
rm -rf $HOME/admin/tmp/*.*

Advanced_Settings=$(cat <<-EOF
#UUID=${UUID}
#VMESS_WSPATH=${VMESS_WSPATH}
#VLESS_WSPATH=${VLESS_WSPATH}

ProxyRequests off
ProxyPreserveHost On
ProxyPass "${VMESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8300${VMESS_WSPATH}"
ProxyPassReverse "${VMESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8300${VMESS_WSPATH}"
ProxyPass "${VLESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8400${VLESS_WSPATH}"
ProxyPassReverse "${VLESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8400${VLESS_WSPATH}"
EOF
)

vmlink=vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"Alwaysdata\",\"add\":\"$URL\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$URL\",\"path\":\"$VMESS_WSPATH\",\"tls\":\"tls\"}" | base64 -w 0)
vllink="vless://"$UUID"@"$URL":443?encryption=none&security=tls&type=ws&host="$URL"&path="$VLESS_WSPATH"#Alwaysdata"

cat > $HOME/www/index.html <<-EOF
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Alwaysdata</title>
<style>
body { font-family: Geneva, Arial, Helvetica, san-serif; }
div { margin: 20px auto; text-align: left; white-space: pre-wrap; word-break: break-all; max-width: 80%; margin-bottom: 10px; }
</style>
</head>
<body bgcolor="#FFFFFF" text="#000000">
<div align="center"><b>Connection Info</b></div>
<div><font color="#009900"><b>VMESS:</b></font></div>
<div>$vmlink</div>
<div><font color="#009900"><b>VLESS:</b></font></div>
<div>$vllink</div>
</body>
</html>
EOF

clear

echo ""
echo "=============================================="
echo "     Installation Complete!"
echo "=============================================="
echo ""
echo "1. Copy this to SERVICE Command:"
echo "   ./xray -config config.json"
echo ""
echo "2. Copy this to Apache Advanced Settings:"
echo "$Advanced_Settings"
echo ""
echo "3. Visit:"
echo "   https://$URL/index.html"
echo ""
echo "=============================================="
