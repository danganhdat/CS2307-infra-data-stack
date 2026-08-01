#!/usr/bin/env bash
# Runs ON THE VM. Writes stack/.env by reading the passwords from Secret Manager
# using the VM's service account (via the metadata server). No gcloud needed.
set -euo pipefail

DIR=/mnt/data/stack
META="http://metadata.google.internal/computeMetadata/v1"

PROJECT=$(curl -s -H "Metadata-Flavor: Google" "$META/project/project-id")
TOKEN=$(curl -s -H "Metadata-Flavor: Google" \
  "$META/instance/service-accounts/default/token" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['access_token'])")

get_secret() {
  curl -s -H "Authorization: Bearer $TOKEN" \
    "https://secretmanager.googleapis.com/v1/projects/$PROJECT/secrets/$1/versions/latest:access" \
    | python3 -c "import sys,json,base64;print(base64.b64decode(json.load(sys.stdin)['payload']['data']).decode())"
}

umask 077
cat > "$DIR/.env" <<EOF
POSTGRES_USER=appuser
POSTGRES_PASSWORD=$(get_secret postgres-password)
POSTGRES_DB=appdb
NEO4J_PASSWORD=$(get_secret neo4j-password)
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=$(get_secret minio-password)
PGADMIN_PASSWORD=$(get_secret pgadmin-password)
EOF
echo "Wrote $DIR/.env"

# pgAdmin runs as uid 5050 and needs its data dir writable.
mkdir -p /mnt/data/pgadmin
chown -R 5050:5050 /mnt/data/pgadmin
