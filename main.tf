provider "aws" {
  region = "us-east-1"
}
resource "aws_key_pair" "my_key" {
  key_name   = "terraform-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # anyone can connect (we can restrict later)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "my_ec2" {
  ami                    = "ami-0c02fb55956c7d316" # Ubuntu 20.04 in us-east-1
  instance_type          = "t2.micro"             # Free-tier eligible
  key_name               = aws_key_pair.my_key.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_cloudwatch_profile.name

  tags = {
    Name = "Terraform-EC2"
  }
}
output "ec2_public_ip" {
  value = aws_instance.my_ec2.public_ip
}
# Create IAM Role
resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "ec2-cloudwatch-role"

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
}

# Attach policy to the role
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_attach" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create instance profile for EC2
resource "aws_iam_instance_profile" "ec2_cloudwatch_profile" {
  name = "ec2-cloudwatch-profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}




