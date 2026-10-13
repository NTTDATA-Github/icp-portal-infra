variable "bucket_name" {
  description = "Globally-unique S3 bucket name to hold the built SPA (e.g. icp-portal-prod-<your-account-id>)."
  type        = string
}

variable "region" {
  description = "AWS region the bucket lives in (CloudFront itself is global)."
  type        = string
  default     = "us-east-1"
}

variable "price_class" {
  description = "CloudFront price class. PriceClass_100 = North America + Europe only (cheapest)."
  type        = string
  default     = "PriceClass_100"
}
