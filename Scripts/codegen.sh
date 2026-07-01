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

[[ -f "$SCRIPT_DIR/codegen-config.sh" ]] || { red "Configuration not found: $SCRIPT_DIR/codegen-config.sh"; exit 1; }
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

if [[ "$ENDPOINT" == *"PLACEHOLDER"* ]]; then
  red "Endpoint contains PLACEHOLDER — update Scripts/codegen-config.sh before using $ENV"
  exit 1
fi

# ── Validate paths ────────────────────────────────────────────────────────────

[[ -d "$GRAPHQL_DIR" ]] || { red "GraphQL dir not found: $GRAPHQL_DIR"; exit 1; }
[[ -f "$SCHEMA_CONFIG" ]] || { red "Schema config not found: $SCHEMA_CONFIG"; exit 1; }

TEMP_SCHEMA_CONFIG="$(mktemp "$GRAPHQL_DIR/apollo-schema-config-tmp.XXXXXX.json")"

# ── 2. Prereqs ────────────────────────────────────────────────────────────────

header "Checking prerequisites"

if ! command -v apollo-ios-cli &>/dev/null; then
  echo "apollo-ios-cli not found — downloading from GitHub releases..."
  readonly APOLLO_VERSION="2.2.0"
  APOLLO_URL="https://github.com/apollographql/apollo-ios/releases/download/${APOLLO_VERSION}/apollo-ios-cli.tar.gz"
  APOLLO_INSTALL_DIR="$HOME/.local/bin"
  mkdir -p "$APOLLO_INSTALL_DIR"
  curl -sL "$APOLLO_URL" | tar -xz -C "$APOLLO_INSTALL_DIR"
  chmod +x "$APOLLO_INSTALL_DIR/apollo-ios-cli"
  export PATH="$APOLLO_INSTALL_DIR:$PATH"
  if ! command -v apollo-ios-cli &>/dev/null; then
    red "apollo-ios-cli install failed. Download manually: $APOLLO_URL"
    exit 1
  fi
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
