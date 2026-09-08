variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "Ubuntu 24.04 AMI ID"
  type        = string
  default     = "ami-0ecb62995f68bb549"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of the existing EC2 key pair"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket for upload script and torrent data archives"
  type        = string
}

variable "pia_user" {
  description = "Private Internet Access username"
  type        = string
  sensitive   = true
}

variable "pia_password" {
  description = "Private Internet Access password"
  type        = string
  sensitive   = true
}

variable "qbittorrent_user" {
  description = "qBittorrent Web UI username"
  type        = string
  default     = "admin"
}

variable "qbittorrent_password" {
  description = "qBittorrent Web UI password"
  type        = string
  sensitive   = true
}

variable "protonvpn_user" {
  description = "username/email to cyberghost"
  type        = string
  sensitive   = true

}

variable "protonvpn_password" {
  description = "password to cyberghost"
  type        = string
  sensitive   = true

}
variable "vpn_client" {
  description = "vpn using"
  type        = string
  sensitive   = true
}


variable "proton_private_key" {
  description = "pivate key"
  type        = string
  sensitive   = true
}