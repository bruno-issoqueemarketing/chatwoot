#!/usr/bin/env bash
# [custom] Builds the Smartlub Chat image from the current git checkout.
# Usage: smartlub/build.sh <tag>   e.g. smartlub/build.sh v4.19.1-c1
set -euo pipefail
TAG="${1:?usage: build.sh <tag>}"
IMAGE="${CHATWOOT_IMAGE_NAME:-smartlub-chatwoot}"
cd "$(git rev-parse --show-toplevel)"
[ -z "$(git status --porcelain)" ] || { echo "Working tree is dirty; commit first." >&2; exit 1; }
SHA="$(git rev-parse --short HEAD)"
docker build -f docker/Dockerfile -t "$IMAGE:$TAG" --label "git.sha=$SHA" .
echo "Built $IMAGE:$TAG ($SHA)"
