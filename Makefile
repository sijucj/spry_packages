.PHONY: help build-all build-deb build-windows clean test download-import-map

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

build-all: compile-local build-deb build-windows ## Build packages for all platforms

build-deb: build-jammy build-bookworm ## Build all DEB packages

build-jammy: compile-local prepare-src ## Build DEB package for Ubuntu Jammy
	@echo "Building DEB package for Ubuntu Jammy..."
	docker buildx build \
		--target jammy \
		--output type=local,dest=./output/jammy \
		-f dalec-spry-sqlpage.yaml \
		.

build-bookworm: compile-local prepare-src ## Build DEB package for Debian Bookworm
	@echo "Building DEB package for Debian Bookworm..."
	docker buildx build \
		--target bookworm \
		--output type=local,dest=./output/bookworm \
		-f dalec-spry-sqlpage.yaml \
		.

download-deps: ## Download import_map.json and deno.jsonc from Spry repository
	@if [ ! -f import_map.json ]; then \
		echo "Downloading import_map.json..."; \
		curl -o import_map.json https://raw.githubusercontent.com/programmablemd/spry/refs/heads/main/import_map.json; \
		echo "✅ import_map.json downloaded"; \
	else \
		echo "✅ import_map.json already exists"; \
	fi
	@if [ ! -f deno.jsonc ]; then \
		echo "Downloading deno.jsonc..."; \
		curl -o deno.jsonc https://raw.githubusercontent.com/programmablemd/spry/refs/heads/main/deno.jsonc; \
		echo "✅ deno.jsonc downloaded"; \
	else \
		echo "✅ deno.jsonc already exists"; \
	fi

build-windows: download-deps ## Build Windows packages (native Deno compilation)
	@echo "Compiling spry_sqlpage for Windows..."
	deno compile \
		--allow-all \
		--import-map=import_map.json \
		--target x86_64-pc-windows-msvc \
		--output=spry-sqlpage.exe \
		spry_sqlpage.ts
	@echo "Compiling spry_runbook for Windows..."
	deno compile \
		--allow-all \
		--import-map=import_map.json \
		--target x86_64-pc-windows-msvc \
		--output=spry-runbook.exe \
		spry_runbook.ts
	@echo "Packaging Windows binaries..."
	mkdir -p output
	zip output/spry-sqlpage-windows.zip spry-sqlpage.exe
	zip output/spry-runbook-windows.zip spry-runbook.exe
	@echo "✅ Windows packages created: output/spry-sqlpage-windows.zip, output/spry-runbook-windows.zip"

compile-local: download-deps ## Compile spry_sqlpage and spry_runbook locally with Deno
	@if [ ! -f spry-sqlpage ]; then \
		echo "Compiling spry_sqlpage..."; \
		deno compile \
			--allow-all \
			--import-map=import_map.json \
			--output=spry-sqlpage \
			spry_sqlpage.ts; \
		echo "✅ Done! Binary created: ./spry-sqlpage"; \
	else \
		echo "✅ Binary already exists: ./spry-sqlpage"; \
	fi
	@if [ ! -f spry-runbook ]; then \
		echo "Compiling spry_runbook..."; \
		deno compile \
			--allow-all \
			--import-map=import_map.json \
			--output=spry-runbook \
			spry_runbook.ts; \
		echo "✅ Done! Binary created: ./spry-runbook"; \
	else \
		echo "✅ Binary already exists: ./spry-runbook"; \
	fi

prepare-src: compile-local ## Prepare src directory for DALEC
	@echo "Preparing src directory for DALEC..."
	@mkdir -p src/src
	@cp spry-sqlpage src/src/spry-sqlpage
	@cp spry-runbook src/src/spry-runbook
	@chmod +x src/src/spry-sqlpage src/src/spry-runbook
	@echo "✅ Binaries prepared in src/src/ directory"

test: ## Test the compiled binaries
	@echo "Testing spry-sqlpage binary..."
	./spry-sqlpage --help || echo "Binary not found. Run 'make compile-local' first."
	@echo "Testing spry-runbook binary..."
	./spry-runbook --help || echo "Binary not found. Run 'make compile-local' first."

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	rm -rf output/
	rm -rf src/
	rm -f spry-sqlpage
	rm -f spry-sqlpage-*
	rm -f spry-runbook
	rm -f spry-runbook-*
	@echo "✅ Clean complete."

install: ## Install spry-sqlpage and spry-runbook locally (requires sudo)
	@echo "Installing spry-sqlpage and spry-runbook to /usr/local/bin..."
	sudo cp spry-sqlpage /usr/local/bin/spry-sqlpage
	sudo cp spry-runbook /usr/local/bin/spry-runbook
	sudo chmod +x /usr/local/bin/spry-sqlpage /usr/local/bin/spry-runbook
	@echo "Installation complete. Run 'spry-sqlpage --help' and 'spry-runbook --help' to verify."

uninstall: ## Uninstall spry-sqlpage and spry-runbook from system
	@echo "Uninstalling spry-sqlpage and spry-runbook..."
	sudo rm -f /usr/local/bin/spry-sqlpage /usr/local/bin/spry-runbook
	@echo "Uninstall complete."

