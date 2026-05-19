.PHONY: parser-build parser-test parser-clean parser-parse help

help:
	@echo "Parser development targets:"
	@echo "  make parser-build    - Build FinanceParsers package"
	@echo "  make parser-test     - Run parser tests with fixtures"
	@echo "  make parser-parse    - Parse a file (usage: make parser-parse FILE=path/to/file.pdf)"
	@echo "  make parser-clean    - Clean parser build artifacts"

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
