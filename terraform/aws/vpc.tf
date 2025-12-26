data "aws_availability_zones" "available" {}

data "aws_iam_policy_document" "cloudwatch_kms" {
  statement {
    sid = "Enable IAM User Permissions"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow CloudWatch Logs to use the key"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "cloudwatch" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cloudwatch_kms.json

  tags = {
    Name = "lornu-ai-production-cloudwatch-kms"
  }
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/lornu-ai-production-cloudwatch"
  target_key_id = aws_kms_key.cloudwatch.key_id
}

resource "aws_vpc" "lornu_vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "lornu-ai-production-vpc"
  }
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.lornu_vpc.id

  tags = {
    Name = "lornu-ai-production-vpc-flow-log"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/lornu-ai-production"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn

  depends_on = [
    aws_kms_key.cloudwatch,
    aws_kms_alias.cloudwatch
  ]

  tags = {
    Name = "lornu-ai-production-vpc-flow-log"
  }
}

resource "aws_iam_role" "vpc_flow_log" {
  name = "lornu-ai-production-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "lornu-ai-production-vpc-flow-log-role"
  }
}

resource "aws_iam_role_policy" "vpc_flow_log" {
  name = "lornu-ai-production-vpc-flow-log-policy"
  role = aws_iam_role.vpc_flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.lornu_vpc.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name                                                = "lornu-ai-production-public-a"
    "kubernetes.io/cluster/lornu-ai-production-cluster" = "shared"
    "kubernetes.io/role/elb"                            = "1"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.lornu_vpc.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name                                                = "lornu-ai-production-public-b"
    "kubernetes.io/cluster/lornu-ai-production-cluster" = "shared"
    "kubernetes.io/role/elb"                            = "1"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.lornu_vpc.id
  cidr_block        = "10.1.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name                                                = "lornu-ai-production-private-a"
    "kubernetes.io/cluster/lornu-ai-production-cluster" = "shared"
    "kubernetes.io/role/internal-elb"                   = "1"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.lornu_vpc.id
  cidr_block        = "10.1.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name                                                = "lornu-ai-production-private-b"
    "kubernetes.io/cluster/lornu-ai-production-cluster" = "shared"
    "kubernetes.io/role/internal-elb"                   = "1"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.lornu_vpc.id

  tags = {
    Name = "lornu-ai-production-igw"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "lornu-ai-production-nat"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lornu_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "lornu-ai-production-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.lornu_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "lornu-ai-production-private-rt"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}
