terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  max_retries = 1
}

# Data sources
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Groups (only created when EC2 or RDS is enabled)
resource "aws_security_group" "backend_sg" {
  count = var.enable_ec2 || var.enable_lambda ? 1 : 0
  
  name_prefix = "attendance-backend-"
  description = "Security group for EC2 backend"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "attendance-backend-sg"
  }
}

resource "aws_security_group" "database_sg" {
  count = var.enable_rds ? 1 : 0
  
  name_prefix = "attendance-database-"
  description = "Security group for RDS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.enable_ec2 || var.enable_lambda ? [aws_security_group.backend_sg[0].id] : []
  }

  tags = {
    Name = "attendance-database-sg"
  }
}

# S3 Module (conditional)
module "s3" {
  count = var.enable_s3 ? 1 : 0
  source = "./modules/s3"
  
  bucket_name = var.s3_bucket_name
  tags        = var.tags
}

# EC2 Module (conditional)
module "ec2" {
  count = var.enable_ec2 ? 1 : 0
  source = "./modules/ec2"
  
  instance_type     = var.ec2_instance_type
  key_name          = var.key_pair_name
  security_group_id = aws_security_group.backend_sg[0].id
  subnet_id         = data.aws_subnets.default.ids[0]
  tags              = var.tags
}

# RDS Module (conditional)
module "rds" {
  count = var.enable_rds ? 1 : 0
  source = "./modules/rds"
  
  database_name      = var.database_name
  instance_class     = var.rds_instance_class
  allocated_storage  = var.rds_allocated_storage
  master_username    = var.database_username
  master_password    = var.database_password
  vpc_security_group_ids = [aws_security_group.database_sg[0].id]
  subnet_ids         = data.aws_subnets.default.ids
  tags               = var.tags
}

# Lambda Module (conditional)
module "lambda" {
  count = var.enable_lambda ? 1 : 0
  source = "./modules/lambda"
  
  function_name      = var.lambda_function_name
  database_url       = var.enable_rds ? "postgresql://${var.database_username}:${var.database_password}@${module.rds[0].endpoint}:5432/${var.database_name}" : ""
  subnet_ids         = data.aws_subnets.default.ids
  security_group_ids = [aws_security_group.backend_sg[0].id]
  tags               = var.tags
}

# CloudWatch Event Rule for Lambda (conditional)
resource "aws_cloudwatch_event_rule" "lambda_trigger" {
  count = var.enable_lambda ? 1 : 0
  
  name                = "attendance-cleanup-trigger"
  description         = "Trigger Lambda function every hour"
  schedule_expression = "rate(1 hour)"
  state               = var.lambda_schedule_enabled ? "ENABLED" : "DISABLED"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  count = var.enable_lambda ? 1 : 0
  
  rule      = aws_cloudwatch_event_rule.lambda_trigger[0].name
  target_id = "TriggerLambdaFunction"
  arn       = module.lambda[0].function_arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count = var.enable_lambda ? 1 : 0
  
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_trigger[0].arn
}
