# Terraform — Sudoku static hosting (S3 + CloudFront)

Infrastructure as code to host the single-file Sudoku app on a **private S3 bucket**
delivered through **Amazon CloudFront** using **Origin Access Control (OAC)**.

## Architecture

```
Viewer (HTTPS)
      │
      ▼
┌──────────────┐     SigV4-signed      ┌─────────────────────────┐
│  CloudFront  │ ───── origin req ────▶│  Private S3 bucket       │
│ distribution │   (via OAC)           │  (all public access off) │
└──────────────┘                       └─────────────────────────┘
```

- The S3 bucket blocks **all** public access.
- The bucket policy grants `s3:GetObject` **only** to this CloudFront distribution,
  scoped by the `AWS:SourceArn` condition.
- CloudFront serves `sudoku.html` as the default root object over HTTPS.

## Files

| File             | Purpose                                              |
| ---------------- | ---------------------------------------------------- |
| `versions.tf`    | Terraform + provider versions, provider config       |
| `variables.tf`   | Input variables (region, names, source file, etc.)   |
| `s3.tf`          | Private bucket, encryption, versioning, policy, upload|
| `cloudfront.tf`  | OAC + CloudFront distribution                         |
| `outputs.tf`     | Distribution ID, domain, website URL, bucket name     |

## Usage

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

After apply, open the printed `website_url`. CloudFront takes a few minutes to
deploy globally on first creation.

### Updating the app

When `sudoku.html` changes, re-apply to upload the new object, then invalidate the
CloudFront cache so edges fetch the new version:

```bash
terraform apply
aws cloudfront create-invalidation \
  --distribution-id "$(terraform output -raw cloudfront_distribution_id)" \
  --paths "/*"
```

## Variables

| Variable          | Default          | Description                               |
| ----------------- | ---------------- | ----------------------------------------- |
| `aws_region`      | `us-east-1`      | Region for the S3 bucket                  |
| `project_name`    | `kiro-sudoku`    | Resource name prefix / tag                |
| `app_source_file` | `../sudoku.html` | Path to the app file to upload            |
| `index_document`  | `sudoku.html`    | Default root object                       |
| `price_class`     | `PriceClass_100` | CloudFront edge coverage                  |

## Teardown

```bash
terraform destroy
```

Versioning is enabled on the bucket; `terraform destroy` will remove the bucket and
its objects (including versions) managed by this configuration.
