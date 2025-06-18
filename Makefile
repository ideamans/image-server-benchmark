.PHONY: all build clean install start stop test

all: install build

install:
	@echo "Installing all dependencies..."
	$(MAKE) -C servers install

build:
	@echo "Building all servers..."
	$(MAKE) -C servers build

build-release:
	@echo "Building all servers in release mode..."
	$(MAKE) -C servers build-release

clean:
	@echo "Cleaning all build artifacts..."
	$(MAKE) -C servers clean

start: build-release
	@echo "Starting all servers..."
	./start-servers.sh

stop:
	@echo "Stopping all servers..."
	./stop-servers.sh

test:
	@echo "Testing all servers..."
	./test-all-servers.sh

# Convenience targets
setup-server:
	./scripts/setup-server.sh

setup-client:
	./scripts/setup-client.sh

run-benchmark:
	./scripts/run-benchmark.sh

# Docker targets
docker-run:
	./run-amazon-linux.sh

docker-compose-up:
	docker-compose up -d

docker-compose-down:
	docker-compose down