# --- IAM ROLE & INSTANCE PROFILE ---
resource "aws_iam_role" "ec2_s3_role" {
  name = "qbittorrent_s3_read_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "qbittorrent-ec2-s3-role"
  }
}

# IAM Policy for S3 access (least privilege access to specific bucket)
resource "aws_iam_policy" "s3_access_policy" {
  name        = "qbittorrent_s3_access_policy"
  description = "Allows EC2 instance to pull scripts and upload files to S3 bucket in ap-south-2"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAndObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::mybuckets123tarunv7",
          "arn:aws:s3:::mybuckets123tarunv7/*"
        ]
      }
    ]
  })
}

# Attach Custom Policy to IAM Role
resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# IAM Instance Profile referenced by EC2
resource "aws_iam_instance_profile" "profile" {
  name = "qbittorrent_ec2_instance_profile"
  role = aws_iam_role.ec2_s3_role.name
}