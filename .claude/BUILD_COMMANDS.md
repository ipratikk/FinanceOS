# FinanceOS Build Commands

Predefined build scripts to minimize token usage in Claude Code builds.

## Quick Start

All scripts can be run from repo root:

```bash
./Scripts/build-macos.sh    # Build macOS app
./Scripts/build-ios.sh      # Build iOS app
./Scripts/test.sh           # Run tests
./Scripts/clean.sh          # Clean all artifacts
```

## Available Commands

### macOS Build
```bash
./Scripts/build-macos.sh
```
Builds FinanceOSMac scheme for macOS platform. Uses `-quiet` flag to suppress noise. Pipes through xcbeautify if installed, otherwise shows raw output.

**Time**: ~2-3 min (full), ~30-60s (incremental)
**Output**: ~5-20 lines (with xcbeautify), more with raw

### iOS Simulator Build
```bash
./Scripts/build-ios.sh
```
Builds FinanceOSiOS scheme for iPhone 16 simulator. Same xcbeautify fallback.

**Time**: ~2-3 min (full), ~30-60s (incremental)
**Output**: ~5-20 lines (with xcbeautify), more with raw

### Run Tests
```bash
./Scripts/test.sh
```
Runs test suite on macOS scheme. No `-quiet` flag to see test results.

**Time**: Depends on test count (usually 1-2 min)
**Output**: Test summary with pass/fail counts

### Clean
```bash
./Scripts/clean.sh
```
Cleans build artifacts for both schemes and removes derived data.

**Time**: ~10-30s
**Output**: Cleanup confirmations

## Direct Command Reference

If you need to run raw xcodebuild without scripts:

**macOS**:
```bash
xcodebuild -workspace FinanceOS.xcworkspace -scheme FinanceOSMac -destination 'platform=macOS' -quiet build
```

**iOS**:
```bash
xcodebuild -workspace FinanceOS.xcworkspace -scheme FinanceOSiOS -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

**Tests**:
```bash
xcodebuild test -workspace FinanceOS.xcworkspace -scheme FinanceOSMac -destination 'platform=macOS'
```

**Clean**:
```bash
xcodebuild clean -workspace FinanceOS.xcworkspace -scheme FinanceOSMac
xcodebuild clean -workspace FinanceOS.xcworkspace -scheme FinanceOSiOS
```

## Token Efficiency Tips

1. **Use `-quiet` flag** for builds (reduces output by ~70%)
2. **Run incremental builds** after changes (scripts auto-detect)
3. **xcbeautify reduces output** by 80% vs raw xcodebuild
4. **Keep derived data clean** via `./Scripts/clean.sh` regularly
5. **Only build needed scheme** (macOS or iOS, not both)

## Installing xcbeautify

To enable prettier output (recommended):

```bash
brew install xcbeautify
```

Scripts auto-detect and use it if available.

## Common Workflows

### Fix compile errors iteratively
```bash
./Scripts/build-macos.sh   # Try build
# Fix errors in code
./Scripts/build-macos.sh   # Retry (incremental, fast)
```

### Run before commit
```bash
./Scripts/clean.sh
./Scripts/build-macos.sh
./Scripts/test.sh
```

### Debug specific target
```bash
# Build with verbose output (ignore -quiet)
xcodebuild -workspace FinanceOS.xcworkspace -scheme FinanceOSMac build
```

## Expected Token Usage

Typical compile error fix cycle:

- Initial build output: 1000-1500 tokens
- Incremental rebuild: 300-500 tokens
- Test output: 500-1000 tokens
- With scripts + xcbeautify: **50% reduction** vs raw xcodebuild

Total for error-fix cycle: ~800-1500 tokens vs 2000-3000 raw.
