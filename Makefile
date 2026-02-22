# Colors
GREEN := \033[32m
CYAN := \033[36m
YELLOW := \033[33m
GRAY := \033[90m
BOLD := \033[1m
RESET := \033[0m

.DEFAULT_GOAL := help
.PHONY: build test clean help

# ============================================================
# Build
# ============================================================
build:
	@echo "Building CLICore..."
	@swift build -c release
	@echo "$(GREEN)Build complete!$(RESET)"

# ============================================================
# Test
# ============================================================
test:
	@swift test

# ============================================================
# Clean
# ============================================================
clean:
	@echo "Cleaning build artifacts..."
	@swift package clean
	@rm -rf .build
	@echo "$(GREEN)Done!$(RESET)"

# ============================================================
# Help
# ============================================================
help:
	@echo ""
	@echo "$(BOLD)Usage:$(RESET) make $(CYAN)[target]$(RESET)"
	@echo ""
	@echo "$(YELLOW)Targets:$(RESET)"
	@echo "  $(CYAN)build$(RESET) $(GRAY)-$(RESET) $(GREEN)Build the library$(RESET)"
	@echo "  $(CYAN)test$(RESET)  $(GRAY)-$(RESET) $(GREEN)Run tests$(RESET)"
	@echo "  $(CYAN)clean$(RESET) $(GRAY)-$(RESET) $(GREEN)Remove build artifacts$(RESET)"
	@echo "  $(CYAN)help$(RESET)  $(GRAY)-$(RESET) $(GREEN)Show this help message (default)$(RESET)"
	@echo ""
