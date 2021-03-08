variable "aws_default_region" {
  description = "Region where the Terraform script is to be deployed"
  type        = string
  default     = "ap-south-1"
}

# S3 resource variables

variable "logs_bucket_name" {
  description = "S3 Bucket name where the User and Time logs should be stored"
  type        = string
  default     = "ec2-invoke-logs"
}

variable "cloudtrail_logs_bucket" {
  description = "S3 Bucket name for CloudTrail Logs"
  type        = string
  default     = "aws-cloudtrail-logs-for-growthplug-task"
}

# IAM resource variables

variable "lambda_s3_acces_role_policy_name" {
  description = "Role Policy name for Lambda role's S3 access"
  type        = string
  default     = "S3WriteAccessFromLambda"
}

variable "lambda_role_name" {
  description = "IAM Role name for Lambda"
  type        = string
  default     = "LogsToS3"
}

variable "cloudwatch_log_access_policy_name" {
  description = "IAM Role policy name for Cloudwatch Logs access from Lambda"
  type        = string
  default     = "AWSLambdaBasicExecutionRoleForEC2Logging"
}

# Lambda resource variables

variable "lambda_function_name" {
  description = "Function name for Lambda function"
  type        = string
  default     = "logs_to_S3"
}

variable "cloudwatch_rule_name" {
  description = "Name for CloudWatch / EventBridge rule"
  type        = string
  default     = "EC2StateChangeRule"
}

variable "cloudtrail_trail_name" {
  description = "Trail name for CloudTrail trail"
  type        = string
  default     = "ec2-states"
}

# Lambda resource variables

variable "ec2_ami_image" {
  description = "EC2 AMI name"
  type        = string
  default     = "amzn2-ami-hvm-2.0.20210219.0-x86_64-gp2"
}

variable "ec2_instance_type" {
  description = "EC2 instance type to deploy"
  type        = string
  default     = "t2.micro"
}