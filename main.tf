# Create Bucket
resource "aws_s3_bucket" "bucket" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = {
    Project = "serverless-color-palette"
    Owner   = "terraform"
  }
}

# Enforce bucket-level ownership
resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_sqs_queue" "palette" {
  name                       = "${var.bucket_name}-palette-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 1209600
}

resource "aws_sqs_queue" "thumbnail" {
  name                       = "${var.bucket_name}-thumbnail-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 1209600
}

resource "aws_s3_bucket_notification" "bucket" {
  bucket      = aws_s3_bucket.bucket.id
  eventbridge = true
}

resource "aws_cloudwatch_event_rule" "s3_object_created" {
  name = "${var.bucket_name}-object-created"
  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.bucket.id]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "palette_queue" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  target_id = "palette-queue"
  arn       = aws_sqs_queue.palette.arn
}

resource "aws_cloudwatch_event_target" "thumbnail_queue" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  target_id = "thumbnail-queue"
  arn       = aws_sqs_queue.thumbnail.arn
}

resource "aws_sqs_queue_policy" "palette" {
  queue_url = aws_sqs_queue.palette.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "SQS:SendMessage"
      Resource = aws_sqs_queue.palette.arn
    }]
  })
}

resource "aws_sqs_queue_policy" "thumbnail" {
  queue_url = aws_sqs_queue.thumbnail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "SQS:SendMessage"
      Resource = aws_sqs_queue.thumbnail.arn
    }]
  })
}

