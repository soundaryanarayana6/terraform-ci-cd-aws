resource "aws_security_group" "rds_sg" {
  name        = "${var.env}-rds-sg"
  description = "Allow PostgreSQL access from EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_sg_id]  # Only EKS node SG can access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-rds-sg"
    Environment = var.env
    Project     = var.project
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.env}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids
  description = "Subnets for RDS ${var.env}"

  tags = {
    Name        = "${var.env}-rds-subnet-group"
    Environment = var.env
    Project     = var.project
  }
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.env}-db-password-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  recovery_window_in_days = 0
  force_overwrite_replica_secret = true
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = var.db_password
  })
}

resource "aws_db_instance" "postgres" {
  allocated_storage      = 20
  engine                 = "postgres"
  # engine_version         = "15.3
  instance_class         = "db.t3.micro"
  identifier             = "${var.env}-postgres"
  db_name                = "mydb"  # optional initial DB
  username               = jsondecode(aws_secretsmanager_secret_version.db_password_version.secret_string)["username"]
  password               = jsondecode(aws_secretsmanager_secret_version.db_password_version.secret_string)["password"]
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name

  tags = {
    Name        = "${var.env}-postgres"
    Environment = var.env
    Project     = var.project
  }
}
