provider "aws" {
  region = var.aws_region
}

# --- CLOUD-INIT MULTIPART USER DATA ---
data "cloudinit_config" "server_config" {
  gzip          = false
  base64_encode = false

  # 1. Base system, Docker, AWS CLI, S3 script
  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/scripts/system.sh", {
      s3_script_uri    = "s3://mybuckets123tarunv7/scripts/upload.sh"
      s3_bucket_region = "ap-south-2"
    })
  }

  # 2. VPN Layer (Gluetun)
  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/scripts/vpn.sh", {
      vpn_client          = var.vpn_client
      pia_user            = var.pia_user
      pia_password        = var.pia_password
      cyberghost_user     = var.pia_user
      cyberghost_password = var.pia_password
      protonvpn_user      = var.protonvpn_user
      protonvpn_password  = var.protonvpn_password
      proton_private_key  = var.proton_private_key
    })
  }

  # 3. qBittorrent Layer (Attaches to VPN)
  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/scripts/qbit.sh", {
      qbittorrent_user     = var.qbittorrent_user
      qbittorrent_password = var.qbittorrent_password
    })
  }
}

# --- EC2 INSTANCE ---
resource "aws_instance" "server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.profile.name

  user_data = data.cloudinit_config.server_config.rendered

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  tags = {
    Name = "qbittorrent-secure-downloader"
  }
}