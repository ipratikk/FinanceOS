.PHONY: lint-architecture \
        help

help:
	@echo "No package-specific make targets currently defined."
	@echo "Use Claude Code skills: /build /lint /commit /review /refactor"

# Architecture lint: enforces package boundary invariants
# Invariants:
#   1. FinanceCore production sources: zero import SwiftUI
#   2. FinanceCLI production sources: zero import SwiftUI (when package exists)
#   3. FinanceTesting must not appear in any production target
lint-architecture:
	@echo "=== Architecture Lint ==="
	@PACKAGES="FinanceCore"; \
	FAIL=0; \
	for pkg in $$PACKAGES; do \
		SRCDIR="Packages/$$pkg/Sources"; \
		if [ -d "$$SRCDIR" ]; then \
			count=$$(grep -r "^import SwiftUI" "$$SRCDIR" --include="*.swift" 2>/dev/null | wc -l | tr -d ' '); \
			if [ "$$count" -gt 0 ]; then \
				echo "FAIL: import SwiftUI found in $$pkg:"; \
				grep -rn "^import SwiftUI" "$$SRCDIR" --include="*.swift"; \
				FAIL=1; \
			fi; \
		fi; \
	done; \
	if [ -d "Packages/FinanceCLI/Sources" ]; then \
		count=$$(grep -r "^import SwiftUI" "Packages/FinanceCLI/Sources" --include="*.swift" 2>/dev/null | wc -l | tr -d ' '); \
		if [ "$$count" -gt 0 ]; then \
			echo "FAIL: import SwiftUI found in FinanceCLI"; \
			FAIL=1; \
		fi; \
	fi; \
	if [ "$$FAIL" -eq 0 ]; then \
		echo "Architecture lint: PASSED"; \
	else \
		exit 1; \
	fi
