sudo docker logs qbittorrent_vpn 2>&1 | grep -i "temporary password"

---------
echo "=== 1. REAL EC2 PUBLIC IP (AWS Host) ==="
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4 && echo ""

echo -e "\n=== 2. VPN EXIT IP (Protected Swarm IP) ==="
sudo docker exec gluetun_vpn wget -qO- https://api.ipify.org && echo ""
------------