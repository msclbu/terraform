output "lambda_bucket_name" {
  description = "S3 Bucket"

  value = aws_s3_bucket.lambda_bucket.id
}

output "function_name" {
  description = "Lambda Function"

  value = aws_lambda_function.python_test.function_name
}