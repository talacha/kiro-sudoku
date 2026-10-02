output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (useful for cache invalidations)."
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name serving the app."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "website_url" {
  description = "Full HTTPS URL to open the Sudoku app."
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "s3_bucket_name" {
  description = "Name of the private S3 bucket hosting the content."
  value       = aws_s3_bucket.site.id
}

output "s3_bucket_arn" {
  description = "ARN of the private S3 bucket."
  value       = aws_s3_bucket.site.arn
}
