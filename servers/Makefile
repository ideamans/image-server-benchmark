.PHONY: all build clean install common

LANGUAGES = typescript go rust

all: common install build

common:
	@echo "Installing common module dependencies..."
	cd common && npm install

install:
	@echo "Installing dependencies for all servers..."
	@for lang in $(LANGUAGES); do \
		if [ -d "$$lang" ]; then \
			echo ""; \
			echo "=== Installing $$lang servers ==="; \
			$(MAKE) -C $$lang install 2>/dev/null || $(MAKE) -C $$lang deps 2>/dev/null || true; \
		fi \
	done

build:
	@echo "Building all servers..."
	@for lang in $(LANGUAGES); do \
		if [ -d "$$lang" ]; then \
			echo ""; \
			echo "=== Building $$lang servers ==="; \
			$(MAKE) -C $$lang build; \
		fi \
	done

build-release:
	@echo "Building all servers in release mode..."
	$(MAKE) -C typescript build
	$(MAKE) -C go build
	$(MAKE) -C rust release

clean:
	@echo "Cleaning all servers..."
	@for lang in $(LANGUAGES); do \
		if [ -d "$$lang" ]; then \
			echo ""; \
			echo "=== Cleaning $$lang servers ==="; \
			$(MAKE) -C $$lang clean; \
		fi \
	done