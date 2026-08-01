# Access Reference — LOCAL, DO NOT COMMIT

> This file contains live credentials and is gitignored (`*.local.md`).
> Never commit, push, or share it. Rotate the secrets if it leaks.

All services run at **`34.128.92.247`**.

## Web UIs (open in browser)

| UI | URL | Username | Password |
|----|-----|----------|----------|
| MinIO Console | http://34.128.92.247:9001 | `minioadmin` | `fTMTOsX8gmUsvzV2i3vUrQwf` |
| Neo4j Browser | http://34.128.92.247:7474 | `neo4j` | `bU1HJuvji860jaiEVZDwa6Wd` |
| pgAdmin | http://34.128.92.247:8080 | `admin@admin.com` | `FoTdJM3vv5zh9XxGiJhMfPpE` |

> **Neo4j Browser:** in the connect dialog, set the protocol dropdown to `bolt://`
> (not the default `neo4j://`, which fails on a single instance).

## Connection strings (for apps / clients)

```
Postgres  postgresql://appuser:vfNgdUzhkKbOoVPhHHRZsEFe@34.128.92.247:5432/appdb
Neo4j     bolt://neo4j:bU1HJuvji860jaiEVZDwa6Wd@34.128.92.247:7687
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
Secret key: fTMTOsX8gmUsvzV2i3vUrQwf
Region:     us-east-1     (default; ignored)
Addressing: path-style
```
mc CLI: `mc alias set data http://34.128.92.247:9000 minioadmin fTMTOsX8gmUsvzV2i3vUrQwf`

**pgAdmin → Postgres** (inside the UI, once):
```
Host: postgres    Port: 5432    User: appuser
Password: vfNgdUzhkKbOoVPhHHRZsEFe   Database: appdb
```
