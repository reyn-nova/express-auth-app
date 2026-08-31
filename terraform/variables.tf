variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-2"
}

variable "my_ip" {
  description = "Your IP address for SSH access"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair for EC2 instances"
  type        = string
}

variable "db_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT signing secret"
  type        = string
  sensitive   = true
}

variable "cors_origin" {
  description = "Allowed CORS origin"
  type        = string
  default     = "*"
}

variable "git_repo" {
  description = "Git repository URL to clone"
  type        = string
}

variable "git_branch" {
  description = "Git branch to checkout"
  type        = string
  default     = "main"
}
