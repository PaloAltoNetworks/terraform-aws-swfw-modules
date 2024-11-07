resource "random_id" "sufix" {
  byte_length = 8
}

locals {
  random_name   = "${var.prefix}${random_id.sufix.hex}"
  bucket_name   = coalesce(var.bucket_name, local.random_name)
  aws_s3_bucket = var.create_bucket ? aws_s3_bucket.this[0] : data.aws_s3_bucket.this[0]
}

data "aws_s3_bucket" "this" {
  count = var.create_bucket == false ? 1 : 0

  bucket = local.bucket_name
}

resource "aws_s3_bucket" "this" {
  count = var.create_bucket == true ? 1 : 0

  bucket        = local.bucket_name
  force_destroy = var.force_destroy
  tags          = var.global_tags
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.create_bucket == true ? 1 : 0
  bucket = aws_s3_bucket.this[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  count  = var.create_bucket == true ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count  = var.create_bucket == true ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count  = var.create_bucket == true ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_object" "bootstrap_dirs" {
  for_each = toset(var.bootstrap_directories)

  bucket  = local.aws_s3_bucket.id
  key     = each.value
  content = "/dev/null"
}

resource "aws_s3_object" "init_cfg" {
  count = contains(fileset(local.source_root_directory, "**"), "config/init-cfg.txt") ? 0 : 1

  bucket  = local.aws_s3_bucket.id
  key     = "config/init-cfg.txt"
  content = templatefile("${path.module}/init-cfg.txt.tmpl", { bootstrap_options = var.bootstrap_options })
}

locals {
  source_root_directory = coalesce(var.source_root_directory, "${path.root}/files")
}

resource "aws_s3_object" "bootstrap_files" {
  for_each = fileset(local.source_root_directory, "**/[^.]*")

  bucket = local.aws_s3_bucket.id
  key    = each.value
  source = "${local.source_root_directory}/${each.value}"
}
