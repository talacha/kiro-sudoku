locals {
  # Map file extensions to MIME types for correct Content-Type on upload.
  mime_types = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".txt"  = "text/plain"
  }
}

# Random suffix keeps the bucket name globally unique without manual coordination.
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "site" {
  bucket = "${var.project_name}-${random_id.bucket_suffix.hex}"
}

# Enforce bucket-owner ownership; disable ACLs (ACLs are not needed with OAC).
resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Block all public access — content is reachable only through CloudFront.
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Upload the single-file app as the site index.
resource "aws_s3_object" "app" {
  bucket       = aws_s3_bucket.site.id
  key          = var.index_document
  source       = var.app_source_file
  content_type = lookup(local.mime_types, ".html", "application/octet-stream")
  etag         = filemd5(var.app_source_file)
}

# Bucket policy: allow read access only from this CloudFront distribution (OAC).
data "aws_iam_policy_document" "s3_cloudfront" {
  statement {
    sid     = "AllowCloudFrontServicePrincipalReadOnly"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    resources = ["${aws_s3_bucket.site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.s3_cloudfront.json

  # Ensure public access block is in place before attaching the policy.
  depends_on = [aws_s3_bucket_public_access_block.site]
}
