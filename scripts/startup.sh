#!/usr/bin/env bash
# Runs automatically on VM boot (Terraform metadata_startup_script).
# Installs Docker + Compose and mounts the attached data disk.
set -euo pipefail

# ---- Docker Engine + Compose plugin ----
if ! command -v docker >/dev/null 2>&1; then
  apt-get update
  apt-get install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# ---- Data disk ----
DEVICE=/dev/disk/by-id/google-data-disk
MOUNT=/mnt/data

if ! blkid "$DEVICE" >/dev/null 2>&1; then
  mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard "$DEVICE"
fi

mkdir -p "$MOUNT"
if ! grep -q "$MOUNT" /etc/fstab; then
  echo "UUID=$(blkid -s UUID -o value "$DEVICE") $MOUNT ext4 discard,defaults,nofail 0 2" >> /etc/fstab
fi
mount -a

mkdir -p "$MOUNT"/stack "$MOUNT"/postgres "$MOUNT"/neo4j/data "$MOUNT"/neo4j/logs "$MOUNT"/minio
