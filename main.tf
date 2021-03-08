data "aws_caller_identity" "current" {}

# S3 Buckets

resource "aws_s3_bucket" "ec2_logs_bucket" {
  bucket = var.logs_bucket_name

  # Attribute to enable force delete non-empty bucket
  force_destroy = true
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = var.cloudtrail_logs_bucket

  # Attribute to enable force delete non-empty bucket
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action    = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.bucket}"
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action    = "s3:PutObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.bucket}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

// ------------------------------------------------------------------

# AWS IAM resources

resource "aws_iam_role_policy" "s3_access_for_lambda" {
  name = var.lambda_s3_acces_role_policy_name
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.ec2_logs_bucket.bucket}/*"
      },
    ]
  })
}

resource "aws_iam_role" "lambda_role" {
  name               = var.lambda_role_name
  description = "IAM Role for AWS Lambda for EC2 Instances State logging"
  path = "/service-role/"

assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Principal = {
            "Service" = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }
  ]
})
}

resource "aws_iam_policy" "cloudwatch_logs_access" {
  name        = var.cloudwatch_log_access_policy_name
  description = "Access to CloudWatch logs from Lambda"
  path        = "/service-role/"
  policy = jsonencode(
  {
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup"
        ],
        Resource = "arn:aws:logs:${var.aws_default_region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${var.aws_default_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.logs_to_s3.function_name}:*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "cloudwatch_access_attach" {
  name = "cloudwatch_lambda_access_attach"
  policy_arn = aws_iam_policy.cloudwatch_logs_access.arn
  roles = [
    aws_iam_role.lambda_role.name
  ]
}

// ------------------------------------------------------------------

# AWS Lambda resources

data "template_file" "lambda_function_code" {
  template = file("${path.module}/lambda_function_code/lambda_function.py.tpl")
  vars = {
    s3_bucket_name = aws_s3_bucket.ec2_logs_bucket.bucket
  }
}

resource "local_file" "rendered_template" {
  content     = data.template_file.lambda_function_code.rendered
  filename 	= "${path.module}/lambda_function_code/lambda_function.py"
}

data "archive_file" "lambda_python_archive" {
  type = "zip"
  output_path = "${path.module}/lambda_function.zip"
  source {
    content = file(local_file.rendered_template.filename)
    filename = "lambda_function.py"
  }
  depends_on = [local_file.rendered_template]
}

resource "aws_lambda_function" "logs_to_s3" {
  function_name = var.lambda_function_name
  filename      = data.archive_file.lambda_python_archive.output_path
  source_code_hash = data.archive_file.lambda_python_archive.output_base64sha256

  handler     = "lambda_function.lambda_handler"
  runtime     = "python3.8"
  memory_size = 128
  timeout     = 3
  role        = aws_iam_role.lambda_role.arn


}


resource "aws_lambda_permission" "lambda_cloudwatch_rule_permission" {
  statement_id  = "AWSEvents_EC2StateChangeRule"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.logs_to_s3.arn
  principal     = "events.amazonaws.com"
  source_arn = "arn:aws:events:${var.aws_default_region}:${data.aws_caller_identity.current.account_id}:rule/${aws_cloudwatch_event_rule.ec2_state_rule.name}"
}

# ------------------------------------------------------------------

# CLoudwatch Events / EventBridge resources

resource "aws_cloudwatch_event_rule" "ec2_state_rule" {
  name        = var.cloudwatch_rule_name
  description = "Rule for capturing EC2 Instance start and stop and trigger lambda"

  event_pattern = <<EOF
{
  "detail": {
    "eventName": [
      "StartInstances",
      "StopInstances"
    ],
    "eventSource": [
      "ec2.amazonaws.com"
    ]
  },
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "source": [
    "aws.ec2"
  ]
}
EOF
}

resource "aws_cloudwatch_event_target" "lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.ec2_state_rule.name
  arn       = aws_lambda_function.logs_to_s3.arn
}

resource "aws_cloudtrail" "primary_trail" {
  name = var.cloudtrail_trail_name
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.bucket

  is_multi_region_trail         = false
  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
}

// ------------------------------------------------------------------

# AWS EC2 resources

data "aws_ami" "linux" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ec2_ami_image]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
}

resource "aws_instance" "primary" {
  ami           = data.aws_ami.linux.id
  instance_type = var.ec2_instance_type

  depends_on = [
    aws_lambda_function.logs_to_s3,
  ]
}
