.PHONY: help
help: ## Lists the available commands. Add a comment with '##' to describe a command.
	@grep -E '^[a-zA-Z_-].+:.*?## .*$$' $(MAKEFILE_LIST)\
		| sort\
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: test
test: ## Run unit tests with busted
	busted tests/

.PHONY: lint
lint: ## Run linter
	luacheck lua/

.PHONY: check
check: lint test ## Run all checks (lint + test)

.PHONY: clean
clean: ## Clean any build artifacts
	rm -rf luacov.* doc/tags

.PHONY: helptags
helptags: ## Generate helptags for documentation
	nvim --headless --noplugin -u NONE -c "helptags doc" -c "quit"

.PHONY: install
install: ## Install dependencies (if using luarocks)
	@echo "Installing dependencies..."
	@echo "Run 'nix develop' to enter development environment"

.PHONY: test-integration
test-integration: ## Run integration tests
	./nvim-test.sh

.PHONY: test-all
test-all: check test-integration ## Full test suite
