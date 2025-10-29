resource "aws_s3_bucket" "this" {
  bucket = var.name
  tags   = { Name = var.name }
}

// ACL = Access Control List
// Set a highly restrictive public access block configuration:
resource "aws_s3_bucket_public_access_block" "pab" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true  // Stops new ACLs that would make things public
  block_public_policy     = true  // Block public bucket policies
  ignore_public_acls      = true  // Causes S3 to act as if any public ACLs don't exist.
  restrict_public_buckets = true  // Further limits policies so only the same account or trusted AWS services can be allowed
}

// Optionally enable versioning
resource "aws_s3_bucket_versioning" "ver" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration { status = "Enabled" }
}