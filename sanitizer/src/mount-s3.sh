#!/bin/bash

log () {
  echo "[mount-s3.sh]> $@"
}

echo "$S3_KEY:$S3_SECRET_KEY" >${HOME}/.passwd-s3fs && chmod 600 ${HOME}/.passwd-s3fs
log "Mounting $S3_BUCKET volume to $S3_BACKUP_MNT_POINT..."
s3fs "$S3_BUCKET" "$S3_BACKUP_MNT_POINT" \
  -o passwd_file=${HOME}/.passwd-s3fs \
  -o url=$S3_BUCKET_URL \
  -o use_path_request_style

log "Mounting $S3_SANITIZED_BUCKET bucket to $S3_SANITIZED_BACKUP_MNT_POINT..."
s3fs "$S3_SANITIZED_BUCKET" "$S3_SANITIZED_BACKUP_MNT_POINT" \
  -o passwd_file=${HOME}/.passwd-s3fs \
  -o url=$S3_SANITIZED_BUCKET_URL \
  -o use_path_request_style

