.PHONY: all build clean install

SERVERS = fastify hono elysia

all: install

install:
	@echo "Installing TypeScript servers dependencies..."
	@for server in $(SERVERS); do \
		if [ -d "$$server" ]; then \
			echo "Installing $$server..."; \
			$(MAKE) -C $$server install || true; \
		fi \
	done

build: install
	@echo "TypeScript servers are interpreted, no build step needed"

clean:
	@echo "Cleaning TypeScript servers..."
	@for server in $(SERVERS); do \
		if [ -d "$$server" ]; then \
			echo "Cleaning $$server..."; \
			$(MAKE) -C $$server clean; \
		fi \
	done