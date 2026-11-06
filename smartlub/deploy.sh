#!/usr/bin/env bash
# [custom] Deploys an image to /opt/chatwoot with a backup taken first.
# Usage: smartlub/deploy.sh <image:tag>   e.g. smartlub/deploy.sh smartlub-chatwoot:v4.19.1-c1
set -euo pipefail
NEW="${1:?usage: deploy.sh <image:tag>}"
APP_DIR="${APP_DIR:-/opt/chatwoot}"
cd "$APP_DIR"
docker image inspect "$NEW" >/dev/null

TS="$(date +%Y%m%d-%H%M%S)"
BK="$APP_DIR/backups/$TS"
mkdir -p "$BK"
CURRENT="$(docker inspect --format '{{.Config.Image}}' "$(docker compose ps -q rails)")"
echo "$CURRENT" > "$BK/previous_image"
echo "$NEW" > "$BK/new_image"
cp .env docker-compose.yaml docker-compose.override.yaml Caddyfile "$BK/" 2>/dev/null || true

echo ">> Backing up database to $BK/db.dump"
docker compose exec -T postgres sh -c 'pg_dump -U "$POSTGRES_USERNAME" -d "${POSTGRES_DATABASE:-chatwoot_production}" -Fc' > "$BK/db.dump"
[ -s "$BK/db.dump" ] || { echo "Database backup failed" >&2; exit 1; }

set_env() { grep -q "^$1=" .env && sed -i "s#^$1=.*#$1=$2#" .env || echo "$1=$2" >> .env; }
set_env CHATWOOT_IMAGE "${NEW%:*}"
set_env CHATWOOT_VERSION "${NEW##*:}"

echo ">> Running migrations with $NEW"
if ! docker compose run --rm rails bundle exec rails db:chatwoot_prepare; then
  echo "Migration failed; restoring previous .env (database untouched or partially migrated, see $BK)" >&2
  cp "$BK/.env" .env
  exit 1
fi
docker compose up -d rails sidekiq
echo ">> Deployed $NEW (previous: $CURRENT). Backup: $BK"
echo ">> Rollback: smartlub/rollback.sh $TS"
