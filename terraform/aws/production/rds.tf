locals {
  name = "lornu-ai-production-aurora"
}

resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "${local.name}-kms"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "${local.name}-subnet-group"
  }
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${local.name}-credentials"
  description = "Database credentials for Lornu AI production"
  kms_key_id  = aws_kms_key.rds.arn
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    host     = aws_rds_cluster.main.endpoint
    port     = aws_rds_cluster.main.port
    dbname   = var.db_name
  })
}

resource "aws_rds_cluster" "main" {
  cluster_identifier      = local.name
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = "14.6"
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = random_password.db_password.result
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  skip_final_snapshot     = false
  backup_retention_period = 7
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.rds.arn
  apply_immediately       = true
  deletion_protection     = true

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }

  tags = {
    Name = local.name
  }
}

resource "aws_rds_cluster_instance" "main" {
  identifier                      = "${local.name}-1"
  cluster_identifier              = aws_rds_cluster.main.id
  instance_class                  = "db.serverless"
  engine                          = aws_rds_cluster.main.engine
  engine_version                  = aws_rds_cluster.main.engine_version
  publicly_accessible             = false
  db_subnet_group_name            = aws_db_subnet_group.main.name
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn

  tags = {
    Name = "${local.name}-1"
  }
}

resource "aws_security_group" "rds" {
  name        = "${local.name}-sg"
  description = "Security group for Aurora Serverless v2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL access from EKS cluster"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  tags = {
    Name = "${local.name}-sg"
  }
}
