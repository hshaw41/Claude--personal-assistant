#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> git fetch + reset"
git fetch origin
git reset --hard origin/main

echo "==> npm ci"
npm ci

echo "==> build"
npm run build

echo "==> restart service"
sudo systemctl restart assistant

echo "==> status"
sudo systemctl is-active assistant
