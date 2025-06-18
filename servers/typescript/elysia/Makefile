.PHONY: all build install clean run check-bun

all: check-bun install

check-bun:
	@command -v bun >/dev/null 2>&1 || { echo "Bun is not installed. Please install from https://bun.sh"; exit 1; }

install: check-bun
	bun install

build: install
	@echo "Elysia is interpreted, no build step needed"

clean:
	rm -rf node_modules bun.lockb

run: check-bun install
	bun start