resource "aws_security_group" "sg" {
  name        = "qbittorrent_sg_secure"
  description = "Locked down security group for VPN-routed qBittorrent"
  vpc_id      = aws_vpc.main.id

  # SSH Access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Universal WebUI Access (Direct EC2 Public IP)
  ingress {
    description = "qBittorrent WebUI"
    from_port   = 8090
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Internet (Required for WireGuard/OpenVPN tunnel & AWS CLI)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "qbittorrent-locked-sg"
  }
}