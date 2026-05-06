# S3 Bucket for project assets
resource "aws_s3_bucket" "asset_bucket" {
  bucket        = "ai-pr-reviewer-storage-dev"
  force_destroy = true
}