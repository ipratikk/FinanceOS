#!/bin/bash
# Toggle snapshot test record mode for all FinanceOSMacSnapshotTests files.
#
# Usage:
#   ./Scripts/snapshot-record.sh on    # record = true (capture mode)
#   ./Scripts/snapshot-record.sh off   # record = false (verify mode)
#   ./Scripts/snapshot-record.sh       # show current state
#
# Targets `override var record: Bool { ... }` in SnapshotTestable subclasses.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_DIR="$REPO_ROOT/Apps/FinanceOSMac/FinanceOSMacSnapshotTests"

if [ ! -d "$TESTS_DIR" ]; then
    echo "Tests directory not found: $TESTS_DIR"
    exit 1
fi

mode="${1:-status}"

case "$mode" in
    on|true|record)
        echo "Setting record = true in all snapshot tests..."
        find "$TESTS_DIR" -name "*.swift" -exec \
            sed -i '' '/override var record: Bool {/{N;s/        false/        true/;}' {} \;
        count_on=$(grep -rA 1 "override var record" "$TESTS_DIR" 2>/dev/null | grep -c "true" || true)
        echo "Done. $count_on test classes set to record = true"
        echo ""
        echo "Run tests: xcodebuild -workspace FinanceOS.xcworkspace -scheme FinanceOSMac test"
        echo "After capture: ./Scripts/snapshot-record.sh off"
        ;;
    off|false|verify)
        echo "Setting record = false in all snapshot tests..."
        find "$TESTS_DIR" -name "*.swift" -exec \
            sed -i '' '/override var record: Bool {/{N;s/        true/        false/;}' {} \;
        count_off=$(grep -rA 1 "override var record" "$TESTS_DIR" 2>/dev/null | grep -c "false" || true)
        echo "Done. $count_off test classes set to record = false (verify mode)"
        ;;
    status|"")
        count_on=$(grep -rA 1 "override var record" "$TESTS_DIR" 2>/dev/null | grep -c "true" || true)
        count_off=$(grep -rA 1 "override var record" "$TESTS_DIR" 2>/dev/null | grep -c "false" || true)
        echo "Snapshot record mode:"
        echo "  record = true  : $count_on classes"
        echo "  record = false : $count_off classes"
        if [ "$count_on" -gt 0 ] && [ "$count_off" -gt 0 ]; then
            echo ""
            echo "Mixed mode — files set to true:"
            grep -rA 1 "override var record" "$TESTS_DIR" 2>/dev/null | grep -B 1 "true" | grep ".swift" | sed 's|.*/FinanceOSMacSnapshotTests/||' | sed 's|-$||'
        fi
        ;;
    *)
        echo "Usage: $0 [on|off|status]"
        echo "  on     - set record = true (capture mode)"
        echo "  off    - set record = false (verify mode)"
        echo "  status - show current state (default)"
        exit 1
        ;;
esac
