#!/bin/bash
set -euo pipefail

echo "=========================================="
echo " [STEP 1] Installing Base Packages & Docker"
echo "=========================================="
apt-get update -y
apt-get install -y unzip curl bc zip python3 ca-certificates docker.io docker-compose-v2
sudo apt-get update -y && sudo apt-get install -y tcpdump
usermod -aG docker ubuntu

echo "=========================================="
echo " [STEP 2] Installing AWS CLI v2"
echo "=========================================="
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws

echo "=========================================="
echo " [STEP 3] Setting Up Directory Layout"
echo "=========================================="
mkdir -p /home/ubuntu/vpn
mkdir -p /home/ubuntu/qbittorrent/config/qBittorrent
mkdir -p /home/ubuntu/downloads

echo "=========================================="
echo " [STEP 4] Fetching S3 Upload Script"
echo "=========================================="
aws s3 cp "${s3_script_uri}" /home/ubuntu/upload.sh --region "${s3_bucket_region}"
chmod +x /home/ubuntu/upload.sh

chown -R ubuntu:ubuntu /home/ubuntu/