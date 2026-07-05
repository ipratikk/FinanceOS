# GraphQL Codegen Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a script to fetch the latest GraphQL schema via introspection from a configurable environment endpoint, regenerate Apollo iOS models, and build the macOS target.

**Architecture:** Two new scripts — `codegen-config.sh` stores endpoint URLs per environment; `codegen.sh` orchestrates prereq check → schema fetch (`apollo-ios-cli fetch-schema`) → code generation (`apollo-ios-cli generate`) → macOS build. Schema lands at `Apps/FinanceOSMac/GraphQL/schema.graphql`. A separate `apollo-schema-config.json` holds the download configuration template; the script injects the endpoint URL at runtime via python3.

**Tech Stack:** Bash, apollo-ios-cli (Homebrew), python3 (JSON config injection), xcodebuild/xcbeautify

---

### Task 1: Update apollo-codegen-config.json

Change `schemaSearchPaths` to reference the local schema file instead of the sibling-repo path.

**Files:**
- Modify: `Apps/FinanceOSMac/GraphQL/apollo-codegen-config.json`

- [ ] **Step 1: Replace file contents**

Write `Apps/FinanceOSMac/GraphQL/apollo-codegen-config.json`:

```json
{
  "schemaNamespace": "FinanceOSAPI",
  "input": {
    "operationSearchPaths": ["Operations/**/*.graphql"],
    "schemaSearchPaths": ["schema.graphql"]
  },
  "output": {
    "schemaTypes": {
      "path": "Generated/SchemaTypes",
      "moduleType": { "swiftPackageManager": {} }
    },
    "operations": {
      "inSchemaModule": {}
    },
    "testMocks": {
      "none": {}
    }
  }
}
```

`schema.graphql` is relative to the config file location (`Apps/FinanceOSMac/GraphQL/`).

- [ ] **Step 2: Commit**

```bash
git add Apps/FinanceOSMac/GraphQL/apollo-codegen-config.json
git commit -m "chore(graphql): point codegen config to local schema.graphql"
```

---

### Task 2: Create apollo-schema-config.json

Separate config for `apollo-ios-cli fetch-schema`. The script injects the live endpoint URL into this template at runtime.

**Files:**
- Create: `Apps/FinanceOSMac/GraphQL/apollo-schema-config.json`

- [ ] **Step 1: Create the template**

Create `Apps/FinanceOSMac/GraphQL/apollo-schema-config.json`:

```json
{
  "schemaDownloadConfiguration": {
    "downloadMethod": {
      "introspection": {
        "endpointURL": "__ENDPOINT_URL__",
        "httpMethod": { "POST": {} },
        "includeDeprecatedInputValues": false,
        "outputFormat": "SDL"
      }
    },
    "downloadTimeout": 60,
    "headers": [],
    "outputPath": "schema.graphql"
  }
}
```

`__ENDPOINT_URL__` is replaced by the script. `outputPath` is relative to the config file — so `schema.graphql` lands at `Apps/FinanceOSMac/GraphQL/schema.graphql`.

- [ ] **Step 2: Commit**

```bash
git add Apps/FinanceOSMac/GraphQL/apollo-schema-config.json
git commit -m "chore(graphql): add schema download config template"
```

---

### Task 3: Create Scripts/codegen-config.sh

Defines endpoint URLs per environment. Sourced by `codegen.sh` — not executed directly.

**Files:**
- Create: `Scripts/codegen-config.sh`

- [ ] **Step 1: Create the file**

Create `Scripts/codegen-config.sh`:

```bash
# GraphQL endpoint URLs per environment.
# Fill in PLACEHOLDER values before using stage/prod.
ENDPOINT_LOCAL="http://localhost:4000/graphql"
ENDPOINT_STAGE="https://stage.PLACEHOLDER.com/graphql"
ENDPOINT_PROD="https://api.PLACEHOLDER.com/graphql"
```

- [ ] **Step 2: Verify it sources cleanly**

```bash
source Scripts/codegen-config.sh && echo "LOCAL=$ENDPOINT_LOCAL STAGE=$ENDPOINT_STAGE PROD=$ENDPOINT_PROD"
```

Expected:

```
LOCAL=http://localhost:4000/graphql STAGE=https://stage.PLACEHOLDER.com/graphql PROD=https://api.PLACEHOLDER.com/graphql
```

- [ ] **Step 3: Commit**

```bash
git add Scripts/codegen-config.sh
git commit -m "chore(graphql): add codegen endpoint config"
```

---

### Task 4: Create Scripts/codegen.sh

Main orchestration script. Handles prereqs, endpoint injection, schema fetch, codegen, and build.

**Files:**
- Create: `Scripts/codegen.sh`

- [ ] **Step 1: Create the script**

Create `Scripts/codegen.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GRAPHQL_DIR="$PROJECT_ROOT/Apps/FinanceOSMac/GraphQL"
CODEGEN_CONFIG="$GRAPHQL_DIR/apollo-codegen-config.json"
SCHEMA_CONFIG="$GRAPHQL_DIR/apollo-schema-config.json"
SCHEMA_FILE="$GRAPHQL_DIR/schema.graphql"
TEMP_SCHEMA_CONFIG="$GRAPHQL_DIR/apollo-schema-config-tmp.json"

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

python3 - <<PYEOF
import json

with open("$SCHEMA_CONFIG") as f:
    config = json.load(f)

config["schemaDownloadConfiguration"]["downloadMethod"]["introspection"]["endpointURL"] = "$ENDPOINT"

with open("$TEMP_SCHEMA_CONFIG", "w") as f:
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

header "Building macOS target"

"$SCRIPT_DIR/build-macos.sh"

green "Build complete"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x Scripts/codegen.sh
```

- [ ] **Step 3: Verify syntax**

```bash
bash -n Scripts/codegen.sh && echo "Syntax OK"
```

Expected: `Syntax OK`

- [ ] **Step 4: Commit**

```bash
git add Scripts/codegen.sh
git commit -m "feat(graphql): add codegen.sh — schema fetch, codegen, build"
```

---

### Task 5: Verify apollo-ios-cli fetch-schema flag

`apollo-ios-cli` may not be in Homebrew's default tap. Confirm install source and verify `--path` flag is correct.

**Files:** (none — validation only)

- [ ] **Step 1: Attempt install**

```bash
brew install apollo-ios-cli 2>&1 || true
```

If formula not found, try the Apollo tap:

```bash
brew tap apollographql/apollo-ios
brew install apollo-ios-cli
```

- [ ] **Step 2: Confirm fetch-schema flag**

```bash
apollo-ios-cli fetch-schema --help
```

Look for a `--path` flag (points to config file). If the flag name differs, update `Scripts/codegen.sh` line:

```bash
if ! apollo-ios-cli fetch-schema --path "$TEMP_SCHEMA_CONFIG"; then
```

to match the actual flag from `--help`.

- [ ] **Step 3: Confirm generate flag**

```bash
apollo-ios-cli generate --help
```

Verify `--path` flag exists. If it differs, update `Scripts/codegen.sh` line:

```bash
if ! apollo-ios-cli generate --path "$CODEGEN_CONFIG"; then
```

- [ ] **Step 4: Commit any flag corrections**

If flags needed updating:

```bash
git add Scripts/codegen.sh
git commit -m "fix(graphql): correct apollo-ios-cli flag names"
```

---

### Task 6: End-to-end smoke test

Run the full pipeline with local backend.

**Files:** (none — validation only)

- [ ] **Step 1: Start the local backend**

In a separate terminal, start `financeos-backend`. Confirm it's responding:

```bash
curl -s -X POST -H "Content-Type: application/json" \
  -d '{"query":"{ __typename }"}' \
  http://localhost:4000/graphql
```

Expected: JSON response with no `"errors"` key (e.g., `{"data":{"__typename":"Query"}}`).

- [ ] **Step 2: Run the codegen script**

```bash
./Scripts/codegen.sh local
```

Expected terminal output:

```
Environment : local
Endpoint    : http://localhost:4000/graphql

▶ Checking prerequisites
✓ apollo-ios-cli ...

▶ Preparing schema download config
✓ Schema config ready (endpoint injected)

▶ Fetching schema from http://localhost:4000/graphql
✓ Schema downloaded → .../Apps/FinanceOSMac/GraphQL/schema.graphql

▶ Running Apollo codegen
✓ Apollo models generated

▶ Building macOS target
✓ macOS build complete

✓ Build complete
```

- [ ] **Step 3: Verify outputs**

```bash
ls -la Apps/FinanceOSMac/GraphQL/schema.graphql
ls -la Apps/FinanceOSMac/GraphQL/Generated/SchemaTypes/
```

Both should show recent modification timestamps.

- [ ] **Step 4: Verify temp config cleaned up**

```bash
ls Apps/FinanceOSMac/GraphQL/apollo-schema-config-tmp.json 2>/dev/null \
  && echo "ERROR: temp file not cleaned up" \
  || echo "OK: temp file cleaned up"
```

Expected: `OK: temp file cleaned up`

- [ ] **Step 5: Commit updated generated files**

If `schema.graphql` or `Generated/` files changed:

```bash
git add Apps/FinanceOSMac/GraphQL/schema.graphql \
        Apps/FinanceOSMac/GraphQL/Generated/
git commit -m "chore(graphql): regenerate Apollo models from latest schema"
```

---

### Task 7: Optionally gitignore schema.graphql

If the team prefers not to commit the downloaded schema (always re-fetchable via `codegen.sh`).

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Check for existing entry**

```bash
grep -n "schema" .gitignore 2>/dev/null || echo "(no schema entry)"
```

- [ ] **Step 2: Add entry if absent**

Add to `.gitignore`:

```
# Downloaded GraphQL schema — regenerated by Scripts/codegen.sh
Apps/FinanceOSMac/GraphQL/schema.graphql
```

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: gitignore downloaded schema.graphql"
```
