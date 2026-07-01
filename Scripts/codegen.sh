#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GRAPHQL_DIR="$PROJECT_ROOT/Apps/FinanceOSMac/GraphQL"
CODEGEN_CONFIG="$GRAPHQL_DIR/apollo-codegen-config.json"
SCHEMA_CONFIG="$GRAPHQL_DIR/apollo-schema-config.json"
SCHEMA_FILE="$GRAPHQL_DIR/schema.graphql"
TEMP_SCHEMA_CONFIG=""  # set after GRAPHQL_DIR exists check via mktemp

# ── Helpers ───────────────────────────────────────────────────────────────────

green()  { printf '\033[0;32m✓ %s\033[0m\n' "$*"; }
red()    { printf '\033[0;31m✗ %s\033[0m\n' "$*"; }
header() { printf '\n\033[1m▶ %s\033[0m\n' "$*"; }

cleanup() { rm -f "$TEMP_SCHEMA_CONFIG"; }
trap cleanup EXIT

# ── 1. Parse environment ──────────────────────────────────────────────────────

ENV="${1:-local}"

# shellcheck source=Scripts/codegen-config.sh
source "$SCRIPT_DIR/codegen-config.sh"

case "$ENV" in
  local) ENDPOINT="$ENDPOINT_LOCAL" ;;
  stage) ENDPOINT="$ENDPOINT_STAGE" ;;
  prod)  ENDPOINT="$ENDPOINT_PROD"  ;;
  *)
    red "Unknown environment: $ENV"
    echo "Usage: $0 [local|stage|prod]  (default: local)"
    exit 1
    ;;
esac

echo "Environment : $ENV"
echo "Endpoint    : $ENDPOINT"

# ── Validate paths ────────────────────────────────────────────────────────────

[[ -d "$GRAPHQL_DIR" ]] || { red "GraphQL dir not found: $GRAPHQL_DIR"; exit 1; }
[[ -f "$SCHEMA_CONFIG" ]] || { red "Schema config not found: $SCHEMA_CONFIG"; exit 1; }

TEMP_SCHEMA_CONFIG="$(mktemp "$GRAPHQL_DIR/apollo-schema-config-tmp.XXXXXX.json")"

# ── 2. Prereqs ────────────────────────────────────────────────────────────────

header "Checking prerequisites"

if ! command -v apollo-ios-cli &>/dev/null; then
  echo "apollo-ios-cli not found — installing via Homebrew..."
  if ! command -v brew &>/dev/null; then
    red "Homebrew not found. Install it: https://brew.sh"
    exit 1
  fi
  brew install apollo-ios-cli
fi

CLI_VERSION="$(apollo-ios-cli --version 2>/dev/null || true)"
green "apollo-ios-cli ${CLI_VERSION:-installed}"

# ── 3. Inject endpoint URL into schema config ─────────────────────────────────

header "Preparing schema download config"

SCHEMA_CONFIG="$SCHEMA_CONFIG" \
TEMP_SCHEMA_CONFIG="$TEMP_SCHEMA_CONFIG" \
ENDPOINT="$ENDPOINT" \
python3 - <<'PYEOF'
import json, os

with open(os.environ["SCHEMA_CONFIG"]) as f:
    config = json.load(f)

config["schemaDownloadConfiguration"]["downloadMethod"]["introspection"]["endpointURL"] = os.environ["ENDPOINT"]

with open(os.environ["TEMP_SCHEMA_CONFIG"], "w") as f:
    json.dump(config, f, indent=2)
PYEOF

green "Schema config ready (endpoint injected)"

# ── 4. Fetch schema ───────────────────────────────────────────────────────────

header "Fetching schema from $ENDPOINT"

if ! apollo-ios-cli fetch-schema --path "$TEMP_SCHEMA_CONFIG"; then
  red "Schema fetch failed from $ENDPOINT"
  echo "  → Is the server running?"
  echo "  → Verify the endpoint in Scripts/codegen-config.sh"
  exit 1
fi

green "Schema downloaded → $SCHEMA_FILE"

# ── 5. Generate Apollo models ─────────────────────────────────────────────────

header "Running Apollo codegen"

if ! apollo-ios-cli generate --path "$CODEGEN_CONFIG"; then
  red "Apollo codegen failed"
  echo "  → schema.graphql left at $SCHEMA_FILE for debugging"
  exit 1
fi

green "Apollo models generated"

# ── 6. Build ──────────────────────────────────────────────────────────────────

[[ -f "$SCRIPT_DIR/build-macos.sh" ]] || { red "build-macos.sh not found at $SCRIPT_DIR/build-macos.sh"; exit 1; }

header "Building macOS target"

"$SCRIPT_DIR/build-macos.sh"

green "Build complete"
