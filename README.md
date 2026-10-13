# icp-portal

React SPA served from S3 behind CloudFront. Terraform creates the bucket + distribution,
once. Shipping a new build never touches Terraform — it's a plain file sync.

**Live site:** https://d2xjngw4ys9gpv.cloudfront.net
**Bucket:** `icp-portal-211125351774`
**CloudFront distribution id:** `ELMWTFFQXEYGT`

## Redeploying a new version (frontend developer — do this every time)

No Terraform, no AWS console. Three commands, from the repo root:

```bash
npm run build   # or: npm run build -- outputs to dist/ (vite) / build/ (CRA — adjust path below)

aws s3 sync dist s3://icp-portal-211125351774 --delete

aws cloudfront create-invalidation --distribution-id ELMWTFFQXEYGT --paths "/*"
```

- `s3 sync --delete` uploads anything new/changed and removes files that no longer exist
  in `dist/` (e.g. old hashed asset filenames from a previous build).
- The invalidation is what makes the change show up immediately — without it, CloudFront
  can keep serving the previous build to visitors for a while from cache.
- Needs AWS credentials with `s3:PutObject`/`s3:DeleteObject` on that bucket and
  `cloudfront:CreateInvalidation` on that distribution — doesn't need Terraform/admin access.
- Give it a minute after the invalidation, then hard-refresh the site to confirm.

## First-time infra setup (one person, once — not a per-deploy step)

```bash
cd terraform
terraform init
terraform apply -var="bucket_name=icp-portal-<something-globally-unique>"
```

Note the `bucket_name` and `cloudfront_distribution_id` outputs and use those in the
redeploy commands above. Terraform state is local (`terraform/terraform.tfstate`,
gitignored) — fine solo; move to an S3 backend if more than one person/machine applies this.
Re-run `terraform apply` only when changing the infra itself (price class, adding a custom
domain, etc.) — never as part of a normal deploy.
