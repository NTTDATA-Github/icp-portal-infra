# icp-portal

React SPA served from S3 behind CloudFront.

**Live site:** https://d2xjngw4ys9gpv.cloudfront.net
**Bucket:** `icp-portal-211125351774`
**CloudFront distribution id:** `ELMWTFFQXEYGT`

## How this is put together, and why

- **S3** holds the built static files (`dist/` after `npm run build`) — just a file store,
  not reachable directly from the internet (it's private).
- **CloudFront** sits in front of it: a CDN that caches those files at edge locations
  worldwide so visitors load the site fast, and is what people actually connect to over
  HTTPS (S3 alone doesn't give you a free HTTPS endpoint for a private bucket).
- **Terraform** (`terraform/`) creates those two things — once. It is **not** part of
  shipping a new build; see "Redeploying" below. Re-run `terraform apply` only when
  changing the infrastructure itself (e.g. price class, adding a custom domain).

## Redeploying a new version (do this every time the app changes)

```bash
# 1. Build the app — Vite outputs to dist/ (CRA outputs to build/ — adjust the path below)
npm run build

# 2. Upload the new build to S3, removing anything that's no longer in dist/
aws s3 sync dist s3://icp-portal-211125351774 --delete

# 3. Tell CloudFront to stop serving its cached (old) copies
aws cloudfront create-invalidation --distribution-id ELMWTFFQXEYGT --paths "/*"
```

**Why step 2 matters:** `--delete` removes files from the bucket that no longer exist in
your local `dist/` — otherwise old hashed asset files (`index-abc123.js` from three builds
ago) would sit in the bucket forever, unused but never cleaned up.

**Why step 3 matters (the one people usually skip and then get confused):** uploading to
S3 does not reach CloudFront's caches. CloudFront had already cached `index.html`, and
keeps serving that cached copy to visitors — by default for up to ~24 hours — even though
S3 now has a newer one sitting right there. An invalidation is the explicit "throw away
what you cached, go re-fetch next time" command. It finishes in about 30–60 seconds; it's
not a setting that stays on, there's nothing to remove afterwards, and it does **not**
carry forward to the next deploy — you repeat it every single time you deploy a change,
for as long as this site exists. (Strictly, only `index.html`, `favicon.svg`, and
`icons.svg` ever need invalidating — they keep the same filename on every build. The
JS/CSS files are already content-hashed, e.g. `index-GPhTQusm.js`, so a new build gets a
new filename and never needs invalidating. `/*` invalidates everything anyway because it's
simpler to type and, at this site's size, costs nothing extra — AWS's free tier covers
1,000 invalidation *paths*/month, and `/*` only counts as one.)

Needs AWS credentials with `s3:PutObject`/`s3:DeleteObject` on the bucket and
`cloudfront:CreateInvalidation` on the distribution — no Terraform/admin access required.
Give it a minute after the invalidation, then hard-refresh the site to confirm.

### No CLI access? Use the AWS Console instead

1. **S3** → open bucket `icp-portal-211125351774` → select all existing objects → Delete
   (the console has no `--delete`-on-sync, so clear stale hashed filenames from the last
   build yourself) → **Upload** → drag the whole `dist` folder in (keeps the `assets/`
   subfolder structure) → Upload.
2. **CloudFront** → distributions list → click the row whose **ID** is `ELMWTFFQXEYGT` →
   **Invalidations** tab → **Create invalidation** → type `/*` in Object paths → **Create
   invalidation**. Status goes "In Progress" → "Completed" in roughly 30–60 seconds.
3. Wait ~1 minute, hard-refresh the site.

Same result as the CLI steps above, just clickier and with no audit trail — fine
occasionally, prefer the CLI for routine deploys.

### Common gotcha: images missing after deploy, but fine in `npm run dev`

Usually means an `<img>` (or similar) references a file by a literal path like
`/src/assets/foo.png` instead of importing it. That resolves in dev only because Vite's
dev server happens to serve the whole project, including `src/`. A production build only
copies/hashes files it sees through an actual `import ... from "./assets/foo.png"` (or
`new URL(...)`) — a raw string path is invisible to the bundler, so the file is silently
left out of `dist/` entirely. Fix: import the image properly, or move it into `public/`
and reference it as a root-relative path (e.g. `/foo.png`). Verify before redeploying:
`find dist -iname "*.png" -o -iname "*.jpg"` should list every image the app uses.

## First-time infra setup (one person, once — not a per-deploy step)

```bash
cd terraform
terraform init
terraform apply -var="bucket_name=icp-portal-<something-globally-unique>"
```

Note the `bucket_name` and `cloudfront_distribution_id` outputs and use those in the
redeploy commands above. Terraform state is local (`terraform/terraform.tfstate`,
gitignored) — fine solo; move to an S3 backend if more than one person/machine applies this.
