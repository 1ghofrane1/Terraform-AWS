resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "app" {
  bucket = "${var.project_name}-app-${random_id.suffix.hex}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-app-bucket"
  })
}

resource "aws_s3_bucket_ownership_controls" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "app_src" {
  for_each = fileset(var.source_dir, "**")

  bucket = aws_s3_bucket.app.id
  key    = each.value
  source = "${var.source_dir}/${each.value}"
  etag   = filemd5("${var.source_dir}/${each.value}")
}
