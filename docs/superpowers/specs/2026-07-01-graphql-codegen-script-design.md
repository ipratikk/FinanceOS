# GraphQL Codegen Script Design

**Date:** 2026-07-01  
**Status:** Approved

---

## Goal

Single script to: fetch latest GraphQL schema from a running backend → regenerate Apollo models → build macOS target.

---

## Files Created

| File | Purpose |
|------|---------|
| `Scripts/codegen-config.sh` | Endpoint URLs per environment (sourced, not executed) |
| `Scripts/codegen.sh` | Main orchestration script |

## Files Modified

| File | Change |
|------|--------|
| `Apps/FinanceOSMac/GraphQL/apollo-codegen-config.json` | `schemaSearchPaths` → `["schema.graphql"]` (local path) |

---

## Architecture

```
codegen.sh [local|stage|prod]   (default: local)
  │
  ├─ 1. Prereqs: check/install apollo-ios-cli via brew
  ├─ 2. Source codegen-config.sh → resolve endpoint URL for env
  ├─ 3. apollo-ios-cli fetch-schema
  │       --path Apps/FinanceOSMac/GraphQL/apollo-codegen-config.json
  │       (endpoint injected via schemaDownloadConfiguration in config,
  │        or env var override — exact flag TBD at implementation)
  ├─ 4. apollo-ios-cli generate
  │       --path Apps/FinanceOSMac/GraphQL/apollo-codegen-config.json
  └─ 5. Scripts/build-macos.sh
```

Downloaded schema saved to `Apps/FinanceOSMac/GraphQL/schema.graphql` — local to project, no sibling repo dependency.

---

## codegen-config.sh

```bash
# Endpoint URLs per environment
ENDPOINT_LOCAL="http://localhost:4000/graphql"
ENDPOINT_STAGE="https://stage.PLACEHOLDER.com/graphql"
ENDPOINT_PROD="https://api.PLACEHOLDER.com/graphql"
```

User fills in `PLACEHOLDER` values before using stage/prod.

---

## codegen.sh

### Usage

```bash
./Scripts/codegen.sh           # local (default)
./Scripts/codegen.sh local
./Scripts/codegen.sh stage
./Scripts/codegen.sh prod
```

### Steps

1. **Prereq check** — if `apollo-ios-cli` missing, `brew install apollo-ios-cli`; fail with message if brew unavailable
2. **Env resolution** — source `codegen-config.sh`, select URL from `$1` arg; unknown arg → error + usage
3. **Schema download** — `apollo-ios-cli fetch-schema --path <config>`; endpoint URL injected into config (or via flag — exact CLI syntax verified at implementation). On failure: print endpoint tried + "is the server running?" and exit 1
4. **Codegen** — `apollo-ios-cli generate`; on failure, note schema.graphql left in place for debugging and exit 1
5. **Build** — delegate to `Scripts/build-macos.sh`

---

## apollo-codegen-config.json Change

`schemaSearchPaths` updated from the old sibling-repo relative path to local:

```json
"schemaSearchPaths": ["schema.graphql"]
```

Path is relative to the config file location (`Apps/FinanceOSMac/GraphQL/`).

---

## Error Handling

| Failure point | Message | Exit |
|--------------|---------|------|
| brew not found | "brew not found — install Homebrew: https://brew.sh" | 1 |
| apollo-ios-cli install fails | brew error output + hint | 1 |
| Unknown ENV arg | "Unknown environment: <arg>. Use: local, stage, prod" | 1 |
| Schema download fails | "Schema fetch failed from <URL> — is the server running?" | 1 |
| Codegen fails | "Apollo codegen failed — schema.graphql left at <path> for debugging" | 1 |
| Build fails | build-macos.sh exits non-zero, propagated | 1 |

`set -euo pipefail` active throughout.

---

## Future Extension

Adding iOS build: add `Scripts/build-ios.sh` call after macOS build step in `codegen.sh`. No structural changes needed.
