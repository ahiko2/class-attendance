variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "119.172.132.227/32"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for frontend hosting"
  type        = string
  default     = "attendance-system-frontend-mk-ap-northeast-1"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of the AWS Key Pair"
  type        = string
  default     = "class-attendance-mk"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "attendance_db"
}

variable "database_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "database_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  default     = "admin123"  # Added default value
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "cleanupExpiredSessions"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "QR-Attendance-System"
    Environment = "dev"
  }
}
