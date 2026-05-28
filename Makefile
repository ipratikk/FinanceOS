.PHONY: parser-build parser-test parser-clean parser-parse \
        intelligence-build intelligence-test intelligence-validate intelligence-train intelligence-evaluate \
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
	@echo "  make intelligence-train    - Train Core ML model on fixture data"
	@echo "  make intelligence-evaluate - Evaluate trained model against fixture data"

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
