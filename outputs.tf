output "instance_public_ip" {
  description = "EC2 Instance Public IP"
  value       = aws_instance.server.public_ip
}

output "ssh_command" {
  description = "Standard SSH connection"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.server.public_ip}"
}

output "ssh_tunnel_command" {
  description = "Run this in your local terminal to access the Web UI securely"
  value       = "ssh -i ${var.key_name}.pem -L 8090:localhost:8090 ubuntu@${aws_instance.server.public_ip}"
}

output "webui_local_url" {
  description = "Open in your browser after running the ssh_tunnel_command"
  value       = "http://localhost:8090"
}

output "qbittorrent_webui_url" {
  description = "Universal WebUI URL"
  value       = "http://${aws_instance.server.public_ip}:8090"
}
