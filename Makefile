.PHONY: parser-build parser-test parser-clean parser-parse \
        lint-architecture \
        help

help:
	@echo "Parser development targets:"
	@echo "  make parser-build    - Build FinanceParsers package"
	@echo "  make parser-test     - Run parser tests with fixtures"
	@echo "  make parser-parse    - Parse a file (usage: make parser-parse FILE=path/to/file.pdf)"
	@echo "  make parser-clean    - Clean parser build artifacts"

# Architecture lint: enforces package boundary invariants
# Invariants:
#   1. FinanceCore production sources: zero import SwiftUI
#   2. FinanceParsers production sources: zero import SwiftUI
#   3. FinanceCLI production sources: zero import SwiftUI (when package exists)
#   4. FinanceTesting must not appear in any production target
#   5. FinanceParsers must have zero external dependencies
lint-architecture:
	@echo "=== Architecture Lint ==="
	@PACKAGES="FinanceCore FinanceParsers"; \
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

parser-build:
	cd Packages/FinanceParsers && swift build

parser-test:
	cd Packages/FinanceParsers && swift test -v

parser-clean:
	cd Packages/FinanceParsers && swift package clean

parser-parse:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make parser-parse FILE=path/to/file.pdf"; \
		exit 1; \
	fi
	cd Packages/FinanceParsers && swift run FinanceParserCLI parse "$(FILE)"

parser-parse-debug:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make parser-parse-debug FILE=path/to/file.pdf"; \
		exit 1; \
	fi
	cd Packages/FinanceParsers && swift run FinanceParserCLI parse "$(FILE)" --debug
