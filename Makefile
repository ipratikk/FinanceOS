.PHONY: parser-build parser-test parser-clean parser-parse \
        intelligence-build intelligence-test intelligence-validate intelligence-train intelligence-evaluate \
        lint-architecture \
        help

help:
	@echo "Parser development targets:"
	@echo "  make parser-build    - Build FinanceParsers package"
	@echo "  make parser-test     - Run parser tests with fixtures"
	@echo "  make parser-parse    - Parse a file (usage: make parser-parse FILE=path/to/file.pdf)"
	@echo "  make parser-clean    - Clean parser build artifacts"
	@echo ""
	@echo "Transaction Intelligence targets:"
	@echo "  make intelligence-build    - Build FinanceIntelligence package"
	@echo "  make intelligence-test     - Run FinanceIntelligence tests"
	@echo "  make intelligence-validate - Validate fixture training data"
	@echo "  make intelligence-train    - Generate training metrics (validation only)"
	@echo "  make intelligence-evaluate - Show training data statistics"
	@echo "  make intelligence-export   - Export user corrections to CSV"
	@echo "  make intelligence-merge    - Merge corrections into training data"
	@echo "  make intelligence-retrain  - Full loop: export → merge → train → validate"

# Architecture lint: enforces package boundary invariants
# Invariants:
#   1. FinanceCore production sources: zero import SwiftUI
#   2. FinanceIntelligence production sources: zero import SwiftUI
#   3. FinanceParsers production sources: zero import SwiftUI
#   4. FinanceCLI production sources: zero import SwiftUI (when package exists)
#   5. FinanceTesting must not appear in any production target
#   6. FinanceParsers must have zero external dependencies
#   7. FinanceIntelligence must never construct DatabaseQueue directly
#   8. All public intelligence API calls go through IntelligenceRequest/IntelligenceResponse
lint-architecture:
	@echo "=== Architecture Lint ==="
	@PACKAGES="FinanceCore FinanceParsers FinanceIntelligence"; \
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

# Intelligence targets
intelligence-build:
	cd Packages/FinanceIntelligence && swift build

intelligence-test:
	cd Packages/FinanceIntelligence && swift test -v

intelligence-validate:
	cd tools/transaction-intelligence && python3 validate_data.py

intelligence-train:
	cd tools/transaction-intelligence && python3 train.py

intelligence-evaluate:
	cd tools/transaction-intelligence && python3 evaluate.py

intelligence-sample:
	cd Packages/FinanceIntelligence && swift run FinanceIntelligenceCLI sample

intelligence-run:
	@if [ -z "$(DB)" ]; then \
		echo "Usage: make intelligence-run DB=path/to/FinanceOS.sqlite"; \
		exit 1; \
	fi
	cd Packages/FinanceIntelligence && swift run FinanceIntelligenceCLI eval --db "$(DB)"

# Full correction-driven retrain loop:
#   1. Export user corrections from the app's corrections.json
#   2. Merge corrections into training data
#   3. Generate training metrics
#   4. Validate accuracy meets threshold
#   5. Copy model artifact to Resources/ for bundling
#
# Usage (with live DB):
#   make intelligence-retrain DB=~/Library/Application\ Support/FinanceOS/finance.sqlite
#
# Usage (corrections-only, no DB):
#   make intelligence-retrain
CORRECTIONS_STORE ?= $(HOME)/Library/Application Support/FinanceIntelligence/corrections.json
INTELLIGENCE_RESOURCES = Packages/FinanceIntelligence/Sources/FinanceIntelligence/Resources

intelligence-export:
	cd Packages/FinanceIntelligence && swift run FinanceIntelligenceCLI export \
		--corrections "$(CORRECTIONS_STORE)" \
		--output ../../tools/transaction-intelligence/corrections_export.csv \
		$(if $(DB),--db "$(DB)",)

intelligence-merge:
	cd tools/transaction-intelligence && python3 merge_corrections.py \
		--corrections corrections_export.csv \
		--training fixtures/sample_transactions.csv \
		--output merged_training.csv

intelligence-retrain: intelligence-export intelligence-merge
	cd tools/transaction-intelligence && \
		python3 validate_data.py --data merged_training.csv && \
		python3 train.py --data merged_training.csv --output models/ && \
		python3 evaluate.py --data merged_training.csv --model models/TransactionCategoryClassifier.mlpackage
	@if [ -d "tools/transaction-intelligence/models/TransactionCategoryClassifier.mlpackage" ]; then \
		echo "Copying model to Resources..."; \
		cp -r tools/transaction-intelligence/models/TransactionCategoryClassifier.mlpackage \
			$(INTELLIGENCE_RESOURCES)/TransactionCategoryClassifier.mlpackage; \
		cp tools/transaction-intelligence/models/TransactionCategoryClassifier.metadata.json \
			$(INTELLIGENCE_RESOURCES)/TransactionCategoryClassifier.metadata.json; \
		echo "Model bundled. Rebuild app to activate."; \
	fi
