resource "aws_iam_role" "backend_role" {
  name = "backend-access-role"

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
    Name = "backend-access-role"
  }
}

resource "aws_iam_role_policy_attachment" "s3-attach" {
  role       = aws_iam_role.backend_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
