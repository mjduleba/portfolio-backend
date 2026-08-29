#!/usr/bin/env bash
# Builds and pushes the backend and frontend images used by
# docker-compose.prod.yml. Always targets linux/amd64 explicitly, since the
# GCP VM is amd64 and a plain `docker build` on an Apple Silicon Mac
# defaults to arm64 (host architecture), producing an image the VM can't
# pull ("no matching manifest for linux/amd64/v3").
#
# The frontend's NEXT_PUBLIC_API_URL is inlined into the JS bundle at build
# time, so it must be passed here rather than set in the VM's .env. Default
# below points at the backend container over the Compose network, since all
# frontend data fetching happens server-side inside the frontend container.
#
# Usage:
#   deploy/build-and-push.sh
#   NEXT_PUBLIC_API_URL=http://backend:8000 deploy/build-and-push.sh

set -euo pipefail

NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-http://backend:8000}"

echo "Building backend (linux/amd64)..."
docker buildx build --platform linux/amd64 \
  -t mjduleba/portfolio-backend:latest \
  --push ./backend

echo "Building frontend (linux/amd64, NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL)..."
docker buildx build --platform linux/amd64 \
  --build-arg NEXT_PUBLIC_API_URL="$NEXT_PUBLIC_API_URL" \
  -t mjduleba/portfolio-frontend:latest \
  --push ./frontend

echo "Done. On the VM, run:"
echo "  docker compose -f docker-compose.prod.yml pull"
echo "  docker compose -f docker-compose.prod.yml up -d"
