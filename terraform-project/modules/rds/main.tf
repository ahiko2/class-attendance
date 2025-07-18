resource "aws_db_subnet_group" "main" {
  name       = "${replace(var.database_name, "_", "-")}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.database_name}-subnet-group"
  })
}

resource "aws_db_parameter_group" "main" {
  family = "postgres15"
  name   = "${replace(var.database_name, "_", "-")}-params"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  tags = var.tags
}

resource "aws_db_instance" "main" {
  identifier = replace(var.database_name, "_", "-")
  
  # Engine settings
  engine         = "postgres"
  engine_version = "15.8"
  instance_class = var.instance_class
  
  # Storage settings
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = "gp2"
  storage_encrypted    = true
  
  # Database settings
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password
  port     = 5432
  
  # Network settings
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = false
  
  # Backup settings
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null
  
  # Parameter group
  parameter_group_name = aws_db_parameter_group.main.name
  
  # Performance insights
  performance_insights_enabled = var.performance_insights_enabled
  
  # Deletion protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  
  tags = merge(var.tags, {
    Name = "${var.database_name}-database"
  })
}

resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  name  = "${replace(var.database_name, "_", "-")}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
