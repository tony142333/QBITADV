#!/bin/bash
set -euo pipefail

echo "=========================================================="
echo " [STEP 1] Initializing WireGuard Gateway (tun0)"
echo "=========================================================="

mkdir -p /home/ubuntu/vpn
mkdir -p /home/ubuntu/downloads
cd /home/ubuntu/vpn

# 1. System IPv6 leak prevention
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 > /dev/null

# 2. Docker Compose (Gluetun WireGuard Gateway)
cat << 'COMPOSE_EOF' > docker-compose.yml
services:
  vpn:
    image: qmcgaw/gluetun:latest
    container_name: gluetun_vpn
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    sysctls:
      - net.ipv6.conf.all.disable_ipv6=1
    environment:
      - VPN_SERVICE_PROVIDER=nordvpn
      - VPN_TYPE=wireguard
      - WIREGUARD_PRIVATE_KEY=${nordvpn_wireguard_private_key}
      - SERVER_COUNTRIES=United States
      - SERVER_CITIES=New York,Secaucus
      - SERVER_CATEGORIES=P2P
      - HTTPPROXY=on
      - HTTPPROXY_STEALTH=on
      - BLOCK_MALICIOUS=on
      - BLOCK_SURVEILLANCE=on
      - BLOCK_ADS=on
      - DNS_KEEP_NAMESERVER=off
      - DOT=on
      - FIREWALL=on
      - FIREWALL_OUTBOUND_SUBNETS=172.16.0.0/12,192.168.0.0/16,10.0.0.0/8
      - PORT_FORWARDING=false
      - HEALTH_SERVER_ADDRESS=127.0.0.1:9999
      - UPDATER_PERIOD=24h
    ports:
      - "127.0.0.1:8090:8090"
      - "127.0.0.1:8888:8888"
    restart: unless-stopped
COMPOSE_EOF

chown -R ubuntu:ubuntu /home/ubuntu/vpn

# 3. Launch Gluetun and wait for healthy status
echo "[*] Launching Gluetun VPN container..."
su - ubuntu -c "cd /home/ubuntu/vpn && docker compose up -d vpn"

echo "[*] Awaiting WireGuard tunnel handshake..."
until [ "$(docker inspect --format '{{.State.Health.Status}}' gluetun_vpn 2>/dev/null)" = "healthy" ]; do
  sleep 2
done

# 4. Confirm tun0 interface presence
if docker exec gluetun_vpn ip link show tun0 > /dev/null 2>&1; then
  echo "[+] WireGuard tun0 interface confirmed active."
else
  echo "[-] CRITICAL ERROR: tun0 missing inside Gluetun! Tearing down..."
  cd /home/ubuntu/vpn && docker compose down
  exit 1
fi

# 5. IP & Kill switch leak test
IMDS_TOKEN=$(curl -s --max-time 2 -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60" || echo "")
EC2_IP=""
if [ -n "$IMDS_TOKEN" ]; then
  EC2_IP=$(curl -s --max-time 5 -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4 || echo "")
fi
if [ -z "$EC2_IP" ]; then
  EC2_IP=$(curl -s --max-time 5 https://api.ipify.org || echo "UNKNOWN")
fi
VPN_IP=$(docker exec gluetun_vpn wget -qO- https://api.ipify.org || echo "FAILED")

echo "[*] Host EC2 Public IP : $EC2_IP"
echo "[*] Gluetun Egress IP  : $VPN_IP"

if [ "$VPN_IP" = "FAILED" ] || [ "$EC2_IP" = "$VPN_IP" ]; then
  echo "[-] CRITICAL LEAK: VPN IP matches EC2 IP or tunnel failed!"
  cd /home/ubuntu/vpn && docker compose down
  exit 1
fi

echo "[*] Running kill switch circuit test on tun0..."
TEST_CHECK=$(docker exec gluetun_vpn sh -c "ip route del default dev tun0 2>/dev/null && wget -qO- --timeout=3 https://api.ipify.org || true")

if [ -n "$TEST_CHECK" ]; then
  echo "[-] CRITICAL: Leak detected when tun0 route dropped!"
  cd /home/ubuntu/vpn && docker compose down
  exit 1
else
  echo "[+] Kill switch verified: Outbound packets drop without tun0."
  cd /home/ubuntu/vpn && docker compose restart vpn
  until [ "$(docker inspect --format '{{.State.Health.Status}}' gluetun_vpn 2>/dev/null)" = "healthy" ]; do
    sleep 2
  done
fi

echo "[+] Step 1 completed successfully."
exit 0