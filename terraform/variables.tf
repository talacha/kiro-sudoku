variable "aws_region" {
  description = "AWS region for the S3 bucket. CloudFront is global; the bucket is regional."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to tag resources and prefix the bucket name."
  type        = string
  default     = "kiro-sudoku"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,40}$", var.project_name))
    error_message = "project_name must be 1-40 chars, lowercase letters, numbers, and hyphens only."
  }
}

variable "app_source_file" {
  description = "Path to the single-file web app to upload as the site index."
  type        = string
  default     = "../sudoku.html"
}

variable "index_document" {
  description = "Object key served as the CloudFront default root object."
  type        = string
  default     = "sudoku.html"
}

variable "price_class" {
  description = "CloudFront price class controlling edge-location coverage."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be one of PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}
