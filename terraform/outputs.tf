output "bucket_name" {
  value = aws_s3_bucket.spa.id
}

output "cloudfront_domain_name" {
  description = "Open https://<this> to view the deployed SPA."
  value       = aws_cloudfront_distribution.spa.domain_name
}

output "cloudfront_distribution_id" {
  description = "Used to invalidate the cache after every deploy."
  value       = aws_cloudfront_distribution.spa.id
}
