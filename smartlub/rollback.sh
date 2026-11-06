#!/usr/bin/env bash
# [custom] Restores the image/config saved by deploy.sh.
# Usage: smartlub/rollback.sh [backup-id] [--restore-db]
#   backup-id defaults to the latest one in /opt/chatwoot/backups.
#   --restore-db also restores the database dump (LOSES data written after the backup).
set -euo pipefail
APP_DIR="${APP_DIR:-/opt/chatwoot}"
cd "$APP_DIR"
ID="${1:-}"; [ "$ID" = "--restore-db" ] && ID=""
[ -n "$ID" ] || ID="$(ls -1 backups | sort | tail -1)"
BK="$APP_DIR/backups/$ID"
[ -d "$BK" ] || { echo "Backup $BK not found" >&2; exit 1; }

echo ">> Restoring config from $BK (image: $(cat "$BK/previous_image"))"
cp "$BK/.env" .env
cp "$BK/docker-compose.yaml" docker-compose.yaml
[ -f "$BK/docker-compose.override.yaml" ] && cp "$BK/docker-compose.override.yaml" docker-compose.override.yaml

if [[ " $* " == *" --restore-db "* ]]; then
  echo ">> Restoring database from $BK/db.dump"
  docker compose stop rails sidekiq
  docker compose exec -T postgres sh -c 'pg_restore -U "$POSTGRES_USERNAME" -d "${POSTGRES_DATABASE:-chatwoot_production}" --clean --if-exists' < "$BK/db.dump"
fi
docker compose up -d rails sidekiq
echo ">> Rolled back to $(cat "$BK/previous_image")"
