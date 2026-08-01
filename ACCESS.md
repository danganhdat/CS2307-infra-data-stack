# Access Reference

All services run on the VM at **`34.128.92.247`**. Passwords are stored in GCP
Secret Manager (not in this file) — fetch them with the commands at the bottom.

## Web UIs (open in browser)

| UI | URL | Username | Password (secret) |
|----|-----|----------|-------------------|
| MinIO Console | http://34.128.92.247:9001 | `minioadmin` | `minio-password` |
| Neo4j Browser | http://34.128.92.247:7474 | `neo4j` | `neo4j-password` |
| pgAdmin | http://34.128.92.247:8080 | `admin@admin.com` | `pgadmin-password` |

> **Neo4j Browser:** in the connect dialog, set the protocol dropdown to `bolt://`
> (not the default `neo4j://`, which fails on a single instance).

## Connection strings (for apps / clients)

```
Postgres  postgresql://appuser:<postgres-password>@34.128.92.247:5432/appdb
Neo4j     bolt://neo4j:<neo4j-password>@34.128.92.247:7687
MinIO S3  http://34.128.92.247:9000
```

## Clients & tools

**psql**
```
psql "host=34.128.92.247 port=5432 dbname=appdb user=appuser"
```

**MinIO (S3)** — SDKs need these separately (not a single URL):
```
Access key: minioadmin
Secret key: <minio-password>
Region:     us-east-1     (default; ignored)
Addressing: path-style
```
mc CLI: `mc alias set data http://34.128.92.247:9000 minioadmin <minio-password>`

**pgAdmin → Postgres** (inside the UI, once) — reaches Postgres by container name:
```
Host: postgres    Port: 5432    User: appuser
Password: <postgres-password>   Database: appdb
```

## Fetch the passwords (run locally)

```bash
gcloud secrets versions access latest --secret=postgres-password
gcloud secrets versions access latest --secret=neo4j-password
gcloud secrets versions access latest --secret=minio-password
gcloud secrets versions access latest --secret=pgadmin-password
```
