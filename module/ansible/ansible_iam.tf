resource "aws_iam_user" "ansible-user" {
  name = "ansible-user"
}

resource "aws_iam_group" "ansible-group" {
  name = "ansible-group"
}

resource "aws_iam_access_key" "ansible-user-key" {
  user = aws_iam_user.ansible-user.name
}

resource "aws_iam_user_group_membership" "ansible-group-member" {
  user = aws_iam_user.ansible-user.name 
  groups = [aws_iam_group.ansible-group.name]
}

resource "aws_iam_group_policy_attachment" "ansible-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  group = aws_iam_group.ansible-group.name
}