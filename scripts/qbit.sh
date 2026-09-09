#!/bin/bash
set -euo pipefail

echo "=========================================="
echo " [STEP 6] Configuring & Launching qBittorrent"
echo "=========================================="
mkdir -p /home/ubuntu/qbittorrent/config/qBittorrent
mkdir -p /home/ubuntu/downloads
cd /home/ubuntu/qbittorrent

# PBKDF2 Generator
cat << 'PY_EOF' > /tmp/hash_gen.py
import hashlib, os, base64, sys
salt = os.urandom(16)
password = sys.argv[1]
dk = hashlib.pbkdf2_hmac('sha512', password.encode(), salt, 100000)
s_b64 = base64.b64encode(salt).decode()
dk_b64 = base64.b64encode(dk).decode()
print(f"@ByteArray({s_b64}:{dk_b64})")
PY_EOF

PBKDF2_HASH=$(python3 /tmp/hash_gen.py '${qbittorrent_password}')
rm -f /tmp/hash_gen.py

# qBittorrent Configuration
cat << CONF_EOF > /home/ubuntu/qbittorrent/config/qBittorrent/qBittorrent.conf
[BitTorrent]
Session\\Interface=tun0
Session\\InterfaceName=tun0
Session\\DefaultSavePath=/downloads
Session\\TempPath=/downloads/temp

[LegalNotice]
Accepted=true

[Preferences]
Downloads\\SavePath=/downloads
Downloads\\TempPath=/downloads/temp
WebUI\\Address=*
WebUI\\Port=8090
WebUI\\Username=${qbittorrent_user}
WebUI\\Password_PBKDF2="${qbittorrent_password}"
WebUI\\CSRFProtection=false
WebUI\\HostHeaderValidation=false
CONF_EOF

# qBittorrent Compose
cat << COMPOSE_EOF > /home/ubuntu/qbittorrent/docker-compose.yml
services:
  downloader:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent_app
    network_mode: "container:gluetun_vpn"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - WEBUI_PORT=8090
    volumes:
      - ./config:/config
      - /home/ubuntu/downloads:/downloads
    restart: unless-stopped
COMPOSE_EOF

chown -R ubuntu:ubuntu /home/ubuntu/qbittorrent /home/ubuntu/downloads
su - ubuntu -c "cd /home/ubuntu/qbittorrent && docker compose up -d"

echo "[+] qBittorrent stack started successfully."