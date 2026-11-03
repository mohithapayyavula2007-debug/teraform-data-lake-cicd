terraform {
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}
provider "aws" { region = var.region }

variable "region"  { default = "ap-south-1" }
variable "project" { default = "ds-data-lake" }

resource "random_id" "suffix" { byte_length = 3 }

resource "aws_s3_bucket" "zones" {
  for_each = toset(["raw", "processed", "curated"])
  bucket   = "${var.project}-${each.key}-${random_id.suffix.hex}"
  tags     = { Project = var.project, Zone = each.key }
}

resource "aws_s3_bucket_versioning" "v" {
  for_each = aws_s3_bucket.zones
  bucket   = each.value.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "block" {
  for_each                = aws_s3_bucket.zones
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_glue_catalog_database" "db" { name = replace(var.project, "-", "_") }

resource "aws_iam_role" "glue" {
  name = "${var.project}-glue-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "glue.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "glue" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_glue_crawler" "raw" {
  name          = "${var.project}-raw-crawler"
  role          = aws_iam_role.glue.arn
  database_name = aws_glue_catalog_database.db.name
  s3_target { path = "s3://${aws_s3_bucket.zones["raw"].bucket}/" }
}

output "buckets" { value = { for k, b in aws_s3_bucket.zones : k => b.bucket } }
