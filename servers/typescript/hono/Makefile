.PHONY: all build install clean run

all: install

install:
	npm install

build: install
	@echo "Hono is interpreted, no build step needed"

clean:
	rm -rf node_modules package-lock.json

run: install
	npm start