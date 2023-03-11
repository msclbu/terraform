terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "${data.aws_caller_identity.current.account_id}-lambdatest" 
  force_destroy = true
}

resource "aws_s3_bucket_acl" "lambda_bucket_acl" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

data "archive_file" "lambda_python_test" {
  type = "zip"

  source_dir  = "${path.module}/helloWorld"
  output_path = "${path.module}/hellowWorld.zip"
}

resource "aws_s3_object" "lambda_python_test" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "helloWorld.zip"
  source = data.archive_file.lambda_python_test.output_path

  etag = filemd5(data.archive_file.lambda_python_test.output_path)
}

resource "aws_lambda_function" "python_test" {
  function_name = "pythonTest"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_python_test.key

  runtime = "python3.9"
  handler = "helloWorld.lambda_handler"

  source_code_hash = data.archive_file.lambda_python_test.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "python_test" {
  name = "/aws/lambda/${aws_lambda_function.python_test.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
  