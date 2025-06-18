.PHONY: all build clean release

SERVERS = actix axum rocket

all: build

build:
	@echo "Building Rust servers (debug mode)..."
	@for server in $(SERVERS); do \
		if [ -d "$$server" ]; then \
			echo "Building $$server..."; \
			$(MAKE) -C $$server build; \
		fi \
	done

release:
	@echo "Building Rust servers (release mode)..."
	@for server in $(SERVERS); do \
		if [ -d "$$server" ]; then \
			echo "Building $$server (release)..."; \
			$(MAKE) -C $$server release; \
		fi \
	done

clean:
	@echo "Cleaning Rust servers..."
	@for server in $(SERVERS); do \
		if [ -d "$$server" ]; then \
			echo "Cleaning $$server..."; \
			$(MAKE) -C $$server clean; \
		fi \
	done