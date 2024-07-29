# Define an IAM policy for Vault instances to access KMS
resource "aws_iam_policy" "vault_kms_policy" {
  name        = "vault-kms-access-policy"
  description = "Policy for vault instances to access KMS"

  # Policy document defining permissions for accessing KMS
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Effect   = "Allow",
        Resource = ["${aws_kms_key.vault.arn}"]
      }
    ]
  })

  tags = {
    Name = "ec2-kms-access-policy"
  }
}

# Define an IAM role for Vault instances
resource "aws_iam_role" "vault_role" {
  name = "vault-kms-access-role"

  # policy allowing EC2 to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ec2-kms-access-role"
  }
}

# Attach the KMS access policy to the IAM role
resource "aws_iam_role_policy_attachment" "vault_kms_policy_attachment" {
  role       = aws_iam_role.vault_role.id
  policy_arn = aws_iam_policy.vault_kms_policy.arn
}

# Attach the S3 full access policy to the IAM role
resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role       = aws_iam_role.vault_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Define an IAM instance profile for EC2 instances to use the IAM role
resource "aws_iam_instance_profile" "vault_instance_profile" {
  name = "vault-ec2-instance-profile"
  role = aws_iam_role.vault_role.name
}