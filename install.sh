#!/bin/bash
#############################################################
# Xray-core for Alwaysdata.com (Updated 2026)
# Optimized with VLESS+Vision, Trojan, and Routing Rules
#############################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
XRAY_VERSION="1.8.23"
# !!!! CHANGE THIS LINE WITH YOUR GITHUB USERNAME AND REPO NAME !!!!
CONFIG_URL="https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/config.json"
TMP_DIR=$(mktemp -d)

echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Xray for Alwaysdata - Optimized    ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"

# Get UUID from Apache config or generate new one
if [ -f "$HOME/admin/config/apache/sites.conf" ]; then
    UUID=$(grep -o 'UUID=[^ ]*' $HOME/admin/config/apache/sites.conf | sed 's/UUID=//')
    VMESS_WSPATH=$(grep -o 'VMESS_WSPATH=[^ ]*' $HOME/admin/config/apache/sites.conf | sed 's/VMESS_WSPATH=//')
    VLESS_WSPATH=$(grep -o 'VLESS_WSPATH=[^ ]*' $HOME/admin/config/apache/sites.conf | sed 's/VLESS_WSPATH=//')
    TROJAN_WSPATH=$(grep -o 'TROJAN_WSPATH=[^ ]*' $HOME/admin/config/apache/sites.conf | sed 's/TROJAN_WSPATH=//')
fi

# Set defaults with random paths for security
UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}
VMESS_WSPATH=${VMESS_WSPATH:-"/$(openssl rand -hex 8)"}
VLESS_WSPATH=${VLESS_WSPATH:-"/$(openssl rand -hex 8)"}
TROJAN_WSPATH=${TROJAN_WSPATH:-"/$(openssl rand -hex 8)"}
DOMAIN="${USER}.alwaysdata.net"

echo -e "${GREEN}✓ Using Domain: ${DOMAIN}${NC}"
echo -e "${GREEN}✓ Generated secure paths${NC}"

# Download Xray-core
echo -e "${YELLOW}📥 Downloading Xray-core v${XRAY_VERSION}...${NC}"
wget -q --show-progress -O ${TMP_DIR}/xray.zip \
    "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-64.zip"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Download failed! Check your internet connection.${NC}"
    exit 1
fi

# Extract files
unzip -oq -d ${TMP_DIR} ${TMP_DIR}/xray.zip xray geoip.dat geosite.dat

# Backup existing installation
if [ -f "$HOME/xray" ]; then
    echo -e "${YELLOW}📦 Backing up existing installation...${NC}"
    mkdir -p $HOME/backup
    cp $HOME/xray $HOME/backup/xray.bak 2>/dev/null || true
    cp $HOME/config.json $HOME/backup/config.json.bak 2>/dev/null || true
fi

# Install Xray
cp ${TMP_DIR}/xray $HOME/xray
cp ${TMP_DIR}/geoip.dat $HOME/geoip.dat
cp ${TMP_DIR}/geosite.dat $HOME/geosite.dat
chmod +x $HOME/xray

# Download and configure config.json
echo -e "${YELLOW}⚙️  Configuring Xray...${NC}"
wget -q -O $HOME/config.json "$CONFIG_URL"

# Replace placeholders
sed -i "s#UUID#$UUID#g" $HOME/config.json
sed -i "s#VMESS_WSPATH#$VMESS_WSPATH#g" $HOME/config.json
sed -i "s#VLESS_WSPATH#$VLESS_WSPATH#g" $HOME/config.json
sed -i "s#TROJAN_WSPATH#$TROJAN_WSPATH#g" $HOME/config.json
sed -i "s#YOUR_DOMAIN#$DOMAIN#g" $HOME/config.json
sed -i "s#10000#8300#g" $HOME/config.json
sed -i "s#20000#8400#g" $HOME/config.json
sed -i "s#30000#8500#g" $HOME/config.json
sed -i "s#127.0.0.1#0.0.0.0#g" $HOME/config.json

# Cleanup temp
rm -rf $HOME/admin/tmp/*.*
rm -rf ${TMP_DIR}

# Apache Configuration
Advanced_Settings=$(cat <<-EOF
# Xray Configuration - $(date +%Y-%m-%d)
# UUID: ${UUID}
# VMESS: ${VMESS_WSPATH}
# VLESS: ${VLESS_WSPATH}
# TROJAN: ${TROJAN_WSPATH}

ProxyRequests off
ProxyPreserveHost On

# VMESS WebSocket
ProxyPass "${VMESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8300${VMESS_WSPATH}"
ProxyPassReverse "${VMESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8300${VMESS_WSPATH}"

# VLESS WebSocket
ProxyPass "${VLESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8400${VLESS_WSPATH}"
ProxyPassReverse "${VLESS_WSPATH}" "ws://services-${USER}.alwaysdata.net:8400${VLESS_WSPATH}"

# Trojan WebSocket
ProxyPass "${TROJAN_WSPATH}" "ws://services-${USER}.alwaysdata.net:8500${TROJAN_WSPATH}"
ProxyPassReverse "${TROJAN_WSPATH}" "ws://services-${USER}.alwaysdata.net:8500${TROJAN_WSPATH}"
EOF
)

# Generate connection links
VMESS_LINK="vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"Alwaysdata-Xray\",\"add\":\"$DOMAIN\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$DOMAIN\",\"path\":\"$VMESS_WSPATH\",\"tls\":\"tls\",\"sni\":\"$DOMAIN\"}" | base64 -w 0)"

VLESS_LINK="vless://${UUID}@${DOMAIN}:443?encryption=none&security=tls&sni=${DOMAIN}&type=ws&host=${DOMAIN}&path=${VLESS_WSPATH}#Alwaysdata-Xray-VLESS"

TROJAN_LINK="trojan://${UUID}@${DOMAIN}:443?security=tls&sni=${DOMAIN}&type=ws&host=${DOMAIN}&path=${TROJAN_WSPATH}#Alwaysdata-Xray-Trojan"

# Generate QR codes (if qrencode available)
if command -v qrencode &> /dev/null; then
    qrencode -o $HOME/www/qr-vmess.png "$VMESS_LINK"
    qrencode -o $HOME/www/qr-vless.png "$VLESS_LINK"
    qrencode -o $HOME/www/qr-trojan.png "$TROJAN_LINK"
fi

# Create info page
cat > $HOME/www/info.html <<-EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Xray Connection Info</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 30px;
            font-size: 2.5em;
        }
        .protocol {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            border-left: 4px solid #667eea;
        }
        .protocol h2 {
            color: #667eea;
            margin-bottom: 15px;
        }
        .link {
            background: #1a1a1a;
            color: #00ff00;
            padding: 15px;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            word-break: break-all;
            font-size: 12px;
            line-height: 1.6;
            max-height: 200px;
            overflow-y: auto;
            user-select: all;
        }
        .qr-section {
            display: flex;
            justify-content: space-around;
            flex-wrap: wrap;
            margin-top: 30px;
            gap: 20px;
        }
        .qr-card {
            text-align: center;
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        .qr-card img {
            max-width: 200px;
            height: auto;
        }
        .warning {
            background: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 8px;
            padding: 15px;
            margin-top: 20px;
            color: #856404;
        }
        .copy-btn {
            background: #667eea;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 5px;
            cursor: pointer;
            margin-top: 10px;
            transition: background 0.3s;
        }
        .copy-btn:hover {
            background: #5a67d8;
        }
        .footer {
            text-align: center;
            margin-top: 20px;
            color: #666;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔐 Xray Connection Information</h1>
        
        <div class="protocol">
            <h2>📡 VMess Protocol</h2>
            <div class="link" id="vmess">${VMESS_LINK}</div>
            <button class="copy-btn" onclick="copyToClipboard('vmess')">📋 Copy VMess Link</button>
        </div>
        
        <div class="protocol">
            <h2>📡 VLESS Protocol</h2>
            <div class="link" id="vless">${VLESS_LINK}</div>
            <button class="copy-btn" onclick="copyToClipboard('vless')">📋 Copy VLESS Link</button>
        </div>
        
        <div class="protocol">
            <h2>📡 Trojan Protocol</h2>
            <div class="link" id="trojan">${TROJAN_LINK}</div>
            <button class="copy-btn" onclick="copyToClipboard('trojan')">📋 Copy Trojan Link</button>
        </div>
        
        <div class="warning">
            ⚠️ <strong>Security Notice:</strong> Keep these credentials private. 
            Anyone with these links can use your proxy connection.
            <br>Generated on: $(date)
        </div>
        <div class="footer">
            Powered by Xray-core on Alwaysdata
        </div>
    </div>
    
    <script>
        function copyToClipboard(elementId) {
            const text = document.getElementById(elementId).innerText;
            navigator.clipboard.writeText(text).then(() => {
                alert('✅ Link copied to clipboard!');
            }).catch(() => {
                alert('❌ Failed to copy. Please select and copy manually.');
            });
        }
    </script>
</body>
</html>
EOF

# Create restore script
cat > $HOME/restore.sh <<-'EOF'
#!/bin/bash
if [ -f "$HOME/backup/xray.bak" ]; then
    cp $HOME/backup/xray.bak $HOME/xray
    cp $HOME/backup/config.json.bak $HOME/config.json
    chmod +x $HOME/xray
    echo "✅ Backup restored successfully!"
else
    echo "❌ No backup found!"
fi
EOF
chmod +x $HOME/restore.sh

# Final output
clear
echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║      Installation Complete! 🎉       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📋 Copy this command to SERVICE Command:${NC}"
echo -e "${GREEN}./xray -config config.json${NC}"
echo ""
echo -e "${YELLOW}📋 Copy to Advanced Settings:${NC}"
echo -e "${GREEN}${Advanced_Settings}${NC}"
echo ""
echo -e "${YELLOW}🔗 Connection Info:${NC}"
echo -e "${GREEN}https://${DOMAIN}/info.html${NC}"
echo ""
echo -e "${BLUE}📊 Supported Protocols:${NC}"
echo -e "  • VMess  + WebSocket + TLS"
echo -e "  • VLESS  + WebSocket + TLS"
echo -e "  • Trojan + WebSocket + TLS"
echo ""
echo -e "${YELLOW}⚠️  Don't forget to restart Apache after applying settings!${NC}"
