# Data stack: Postgres + Neo4j + MinIO on GCP (Terraform + GitHub Actions)

Infrastructure as code. Terraform provisions the GCP infra; GitHub Actions
deploys the Docker Compose stack to the VM on every push to `main`.
Services are reached directly at the VM's public IP:port (no reverse proxy).

```
terraform/            # GCP infra: VPC, VM, disk, firewall, secrets, WIF
stack/                # docker-compose.yml (Postgres, Neo4j, MinIO)
scripts/              # startup.sh (boot), render.sh (writes .env from secrets)
.github/workflows/    # infra.yml (terraform), deploy.yml (compose)
```

## One-time bootstrap (local)

1. `gcloud auth login` and `gcloud auth application-default login`
2. Enable APIs:
   ```bash
   gcloud services enable compute.googleapis.com secretmanager.googleapis.com \
     iam.googleapis.com iamcredentials.googleapis.com iap.googleapis.com \
     sts.googleapis.com --project YOUR_PROJECT
   ```
3. Configure + apply:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars   # set project_id + github_repo
   terraform init
   terraform apply
   ```
4. Add two GitHub repo secrets (Settings → Secrets and variables → Actions):
   - `WIF_PROVIDER` ← `terraform output -raw wif_provider`
   - `DEPLOYER_SA`  ← `terraform output -raw deployer_sa`

## Deploy

Push to `main` (or run the **deploy** workflow manually). It copies the stack to
the VM, writes `.env` from Secret Manager, and runs `docker compose up`.

## Reach the services

Get the IP: `terraform output -raw public_ip`

| Service       | Address                        |
|---------------|--------------------------------|
| MinIO Console | http://<public_ip>:9001        |
| MinIO S3 API  | http://<public_ip>:9000        |
| Neo4j Browser | http://<public_ip>:7474        |
| Neo4j Bolt    | bolt://<public_ip>:7687        |
| Postgres      | <public_ip>:5432               |
| pgAdmin (Postgres UI) | http://<public_ip>:8080 |

Passwords are in Secret Manager:
```bash
gcloud secrets versions access latest --secret=postgres-password
gcloud secrets versions access latest --secret=neo4j-password
gcloud secrets versions access latest --secret=minio-password
gcloud secrets versions access latest --secret=pgadmin-password
```
Logins: Postgres user `appuser` / db `appdb`; Neo4j user `neo4j`;
MinIO user `minioadmin`.

pgAdmin login: email `admin@admin.com`, password from `pgadmin-password`.
Once in, add a server → Host `postgres`, Port `5432`, User `appuser`,
Password from `postgres-password`, Database `appdb`.

## Security note

By default the service ports are open to the whole internet (`0.0.0.0/0`). This
is fine for a quick demo but risky for anything real — Postgres in particular
gets scanned constantly. Lock the ports to your own IP by setting in
`terraform.tfvars`:
```hcl
allowed_source_ranges = ["YOUR.IP.HERE/32"]   # curl ifconfig.me
```
then `terraform apply`. SSH is always IAP-only, never public.

## MinIO note

Community Edition's console is object-browser only — manage buckets/users with
the `mc` CLI. Point apps at the S3 API on :9000 with path-style addressing.

## Troubleshooting

**deploy fails at the auth step with `unauthorized_client` / "rejected by the
attribute condition".** GitHub's OIDC token repo doesn't match `github_repo`.
It must be *exactly* `owner/repo` — no `.git` suffix, no `https://` prefix
(e.g. `danganhdat/CS2307-infra-data-stack`, not `...-stack.git`). Fix it in
`terraform.tfvars`, run `terraform apply` (updates the WIF provider's
attribute condition), then re-run the deploy workflow.

**Can't reach a service on its port.** Check the firewall (`allowed_source_ranges`
covers your IP) and that the container is up (`docker compose ps` on the VM).
Remember it's plain HTTP — `http://<ip>:9001`, not `https://`.

## Backups (you own these)

- Snapshot schedule on `data-disk`.
- `pg_dump` cron for Postgres; `neo4j-admin database dump` for Neo4j.
- `mc mirror` MinIO to a GCS bucket for offsite copies.
