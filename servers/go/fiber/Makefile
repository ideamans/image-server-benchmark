.PHONY: all build deps clean run

BINARY_NAME=fiber-server

all: build

deps:
	go mod download
	go mod tidy

build: deps
	go build -o $(BINARY_NAME) .

clean:
	go clean
	rm -f $(BINARY_NAME)

run: build
	./$(BINARY_NAME)