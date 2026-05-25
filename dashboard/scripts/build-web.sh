#!/usr/bin/env bash
# Build the dashboard web bundle with a specific environment.
#
#   ./scripts/build-web.sh                  # production (default)
#   ./scripts/build-web.sh local
#   ./scripts/build-web.sh dev
#   ./scripts/build-web.sh production --deploy
#
# Same pattern as poliglots_app/scripts/build-web.sh — see that file
# for the full explanation. The only differences are the output path
# (build/web/) and the deploy target (../deploy/html/dashboard/web/).
set -euo pipefail

cd "$(dirname "$0")/.."

ENV=${1:-production}
shift || true
DEPLOY=0
for arg in "$@"; do
    case "$arg" in
        --deploy) DEPLOY=1 ;;
        *) echo "Unknown flag: $arg" >&2; exit 2 ;;
    esac
done

CONFIG="env/${ENV}.json"
if [[ ! -f "$CONFIG" ]]; then
    echo "No env file: $CONFIG" >&2
    echo "Available: $(ls env/ 2>/dev/null | sed 's/\.json//g' | tr '\n' ' ')" >&2
    exit 1
fi

echo "==> Building dashboard web (env=$ENV)…"
flutter build web --release --dart-define-from-file="$CONFIG"

OUT="build/web"
echo "==> Output: $(pwd)/$OUT"

if [[ "$DEPLOY" == "1" ]]; then
    DEPLOY_DST="../deploy/html/dashboard/web"
    mkdir -p "$DEPLOY_DST"
    echo "==> Rsync → $DEPLOY_DST"
    rsync -a --delete --exclude 'assets/assets/.env' "$OUT/" "$DEPLOY_DST/"
fi

echo "==> Done."
