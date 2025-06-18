.PHONY: all build clean deps run-fiber run-gin run-echo

all: deps build

deps:
	@echo "Installing dependencies for common..."
	cd common && go mod tidy
	@echo "Installing dependencies for fiber..."
	cd fiber && go mod tidy
	@echo "Installing dependencies for gin..."
	cd gin && go mod tidy
	@echo "Installing dependencies for echo..."
	cd echo && go mod tidy

build: deps
	@echo "Building fiber server..."
	cd fiber && go build -o fiber-server
	@echo "Building gin server..."
	cd gin && go build -o gin-server
	@echo "Building echo server..."
	cd echo && go build -o echo-server

clean:
	@echo "Cleaning build artifacts..."
	rm -f fiber/fiber-server
	rm -f gin/gin-server
	rm -f echo/echo-server

run-fiber: build
	cd fiber && ./fiber-server

run-gin: build
	cd gin && ./gin-server

run-echo: build
	cd echo && ./echo-server