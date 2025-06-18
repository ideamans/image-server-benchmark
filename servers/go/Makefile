.PHONY: all build clean deps

SERVERS = fiber gin echo

all: deps build

deps:
	@echo "Installing dependencies for common..."
	cd common && go mod tidy

build:
	@echo "Building Go servers..."
	@for server in $(SERVERS); do \
		if [ -d "$$server" ]; then \
			echo "Building $$server..."; \
			$(MAKE) -C $$server build; \
		fi \
	done

clean:
	@echo "Cleaning Go servers..."
	@for server in $(SERVERS); do \
		if [ -d "$$server" ]; then \
			echo "Cleaning $$server..."; \
			$(MAKE) -C $$server clean; \
		fi \
	done