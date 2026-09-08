#!/bin/bash
set -euo pipefail

echo "=========================================="
echo " [STEP 5] Deploying Gluetun VPN Container"
echo "=========================================="
mkdir -p /home/ubuntu/vpn
cd /home/ubuntu/vpn

cat << COMPOSE_EOF > docker-compose.yml
services:
  vpn:
    image: qmcgaw/gluetun:latest
    container_name: gluetun_vpn
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    environment:
      - VPN_SERVICE_PROVIDER=private internet access
      - VPN_TYPE=openvpn
      - OPENVPN_USER=${pia_user}
      - OPENVPN_PASSWORD=${pia_password}
      - SERVER_COUNTRIES=Canada
      - PORT_FORWARDING=true
    ports:
      - "8090:8090"
    restart: unless-stopped
COMPOSE_EOF

chown -R ubuntu:ubuntu /home/ubuntu/vpn
su - ubuntu -c "cd /home/ubuntu/vpn && docker compose up -d"

echo "[*] Waiting for Gluetun VPN to become healthy..."
until [ "$(docker inspect --format '{{.State.Health.Status}}' gluetun_vpn 2>/dev/null)" = "healthy" ]; do
  sleep 2
done
echo "[+] Gluetun VPN is healthy and ready."