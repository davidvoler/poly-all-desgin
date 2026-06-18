#!/usr/bin/env bash
# Build the learner-app web bundle with a specific environment.
#
#   ./scripts/build-web.sh                  # production (default)
#   ./scripts/build-web.sh local
#   ./scripts/build-web.sh dev
#   ./scripts/build-web.sh production --deploy
#
# Reads env/<env>.json and passes it as --dart-define-from-file. The
# bundled assets/.env stays untouched, so `flutter run` keeps using
# local defaults. The dart-define values override anything from
# assets/.env — see lib/config/app_config.dart for the precedence rule.
#
# Optional --deploy flag rsyncs build/web/ into ../deploy/html/app/web/
# so nginx (which the production conf points at that path) picks up
# the new bundle immediately. Skip the flag if you just want the
# build output without touching deploy/.
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

echo "==> Building poliglots_app web (env=$ENV)…"
flutter build web --release --dart-define-from-file="$CONFIG"

OUT="build/web"
echo "==> Output: $(pwd)/$OUT"

if [[ "$DEPLOY" == "1" ]]; then
    DEPLOY_DST="../deploy/html/app/web"
    mkdir -p "$DEPLOY_DST"
    # --delete so removed files from previous builds don't linger.
    # Exclude .env so the bundled assets/.env (gitignored) isn't
    # accidentally published — production reads dart-defines instead.
    echo "==> Rsync → $DEPLOY_DST"
    rsync -a --delete --exclude 'assets/assets/.env' "$OUT/" "$DEPLOY_DST/"
fi

echo "==> Done."
