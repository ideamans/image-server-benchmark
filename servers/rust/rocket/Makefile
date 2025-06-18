.PHONY: all build clean run release

all: build

build:
	cargo build

release:
	cargo build --release

clean:
	cargo clean

run: build
	cargo run

run-release: release
	cargo run --release