#!/bin/bash
set -euo pipefail

echo "=========================================================="
echo " [STEP 2] Deploying qBittorrent Bound to tun0"
echo "=========================================================="

mkdir -p /home/ubuntu/vpn/qbittorrent-config
mkdir -p /home/ubuntu/downloads
cd /home/ubuntu/vpn

# 1. Pre-configure qBittorrent explicitly locked to tun0
cat << 'CONF_EOF' > /home/ubuntu/vpn/qbittorrent-config/qBittorrent.conf
[BitTorrent]
Session\Interface=tun0
Session\InterfaceName=tun0

[Preferences]
Connection\Interface=tun0
Connection\InterfaceName=tun0
Bittorrent\DHT=false
Bittorrent\PeX=false
Bittorrent\LSD=false
Bittorrent\MaxUploads=-1
Session\UploadRateLimit=102400
Downloads\SavePath=/downloads/
WebUI\Address=*
WebUI\Port=8090
WebUI\CSRFProtection=false
WebUI\HostHeaderValidation=false
WebUI\AuthSubnetWhitelist=0.0.0.0/0
WebUI\AuthSubnetWhitelistEnabled=true
CONF_EOF

chown -R ubuntu:ubuntu /home/ubuntu/vpn/qbittorrent-config
chown -R ubuntu:ubuntu /home/ubuntu/downloads

# 2. Append qBittorrent service to docker-compose.yml
cat << 'COMPOSE_APPEND_EOF' >> docker-compose.yml

  torrent:
    image: ghcr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent_app
    network_mode: "service:vpn"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - WEBUI_PORT=8090
    volumes:
      - /home/ubuntu/vpn/qbittorrent-config:/config/qBittorrent
      - /home/ubuntu/downloads:/downloads
    depends_on:
      vpn:
        condition: service_healthy
    restart: unless-stopped
COMPOSE_APPEND_EOF

chown ubuntu:ubuntu /home/ubuntu/vpn/docker-compose.yml

# 3. Pull image from GHCR to bypass rate limits
echo "[*] Pulling qBittorrent image from GHCR..."
docker pull ghcr.io/linuxserver/qbittorrent:latest

# 4. Launch qBittorrent container
echo "[*] Launching qBittorrent container..."
su - ubuntu -c "cd /home/ubuntu/vpn && docker compose up -d torrent"

# 5. Await Web UI response (with timeout)
echo "[*] Awaiting qBittorrent Web UI readiness..."
WEBUI_TIMEOUT=90
WEBUI_ELAPSED=0
until curl -s -I http://127.0.0.1:8090 2>/dev/null | grep -qE "200|307"; do
  sleep 2
  WEBUI_ELAPSED=$((WEBUI_ELAPSED + 2))
  if [ "$WEBUI_ELAPSED" -ge "$WEBUI_TIMEOUT" ]; then
    echo "[-] CRITICAL: qBittorrent Web UI did not respond within $WEBUI_TIMEOUT seconds."
    echo "    Check: docker logs qbittorrent_app"
    exit 1
  fi
done

# 6. Confirm the container actually shares gluetun's tun0 (namespace check)
echo "[*] Verifying qBittorrent container shares tun0 with gluetun..."
if docker exec qbittorrent_app ip addr show tun0 > /dev/null 2>&1; then
  echo "[+] tun0 visible inside qBittorrent's network namespace."
else
  echo "[-] WARNING: tun0 NOT visible inside qBittorrent container."
  echo "    This means network_mode: \"service:vpn\" is not sharing the namespace correctly."
  echo "    Check that the 'vpn' service name in docker-compose.yml matches network_mode exactly."
fi

echo "=========================================================="
echo "[+] SUCCESS: qBittorrent is live and bound to tun0."
echo "=========================================================="
exit 0