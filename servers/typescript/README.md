# TypeScript Benchmark Servers

This directory contains three TypeScript-based web servers for benchmarking image delivery performance:

- **Fastify** - High-performance Node.js web framework
- **Hono** - Ultrafast web framework for the Edge
- **Elysia** - Fast and friendly Bun web framework

## Server Details

### Fastify (Port 3001)
- Uses native Fastify static file serving for local images
- Implements streaming proxy for remote images
- Optimized for high throughput with minimal overhead

### Hono (Port 3002)
- Runs on Node.js with @hono/node-server adapter
- Uses fs.promises for local file serving
- Lightweight implementation with minimal dependencies

### Elysia (Port 3003)
- Requires Bun runtime for optimal performance
- Uses native Bun file APIs for maximum speed
- TypeScript-first design with type safety

## Endpoints

Each server implements the following endpoints:

- `GET /local/20k` - Serves 20KB image from local disk
- `GET /local/50k` - Serves 50KB image from local disk
- `GET /local/100k` - Serves 100KB image from local disk
- `GET /proxy/20k` - Proxies 20KB image from origin URL
- `GET /proxy/50k` - Proxies 50KB image from origin URL
- `GET /proxy/100k` - Proxies 100KB image from origin URL
- `GET /health` - Health check endpoint

## Installation

### Prerequisites
- Node.js 18+ for Fastify and Hono
- Bun runtime for Elysia
- Generated test images in the `images` directory

### Install dependencies for all servers:
```bash
cd fastify && npm install
cd ../hono && npm install
cd ../elysia && bun install
```

## Running Servers

### Individual servers:
```bash
# Fastify
cd fastify && npm start

# Hono
cd hono && npm start

# Elysia (requires Bun)
cd elysia && bun start
```

### Test all servers:
```bash
./test-servers.sh
```

## Configuration

Servers use environment variables from the project root `.env` file:

- `ORIGIN_URL_BASE` - Base URL for proxy endpoints
- `SERVER_START_PORT` - Base port number (default: 3001)
- `SERVER_WORKER_THREADS` - Number of worker threads (0 = auto)

## Performance Optimizations

### Fastify
- Disabled request logging
- Disabled duplicate slash normalization
- Static file serving with caching disabled for benchmarking
- Stream-based proxy implementation

### Hono
- Minimal middleware stack
- Direct buffer handling for images
- Efficient routing with radix tree

### Elysia
- Leverages Bun's native performance
- Zero-copy file serving
- Built-in response optimization

## Troubleshooting

1. **Port already in use**: Check if another server is running on ports 3001-3003
2. **Images not found**: Ensure test images are generated in the `images` directory
3. **Bun not found**: Install Bun for Elysia server: `curl -fsSL https://bun.sh/install | bash`
4. **Proxy errors**: Verify `ORIGIN_URL_BASE` is set correctly in `.env`