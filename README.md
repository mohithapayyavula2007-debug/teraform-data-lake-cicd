# Project 5 – Infrastructure as Code: Data Lake with Terraform + CI/CD

**Cloud concepts:** IaC, S3 data-lake zones (raw/processed/curated), IAM least privilege, Glue Data Catalog, CI/CD.

## Use
```
aws configure
terraform init && terraform plan && terraform apply
# upload data to the raw bucket, then: aws glue start-crawler --name ds-data-lake-raw-crawler
terraform destroy      # IMPORTANT: avoid charges
```
## CI
Push to GitHub: Actions runs pytest + `terraform validate` automatically.

## Extensions
Add Lambda ingestion, remote state in S3 + DynamoDB lock, Athena workgroup, cost budget alarm.
