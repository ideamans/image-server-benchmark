# Go Image Servers

This directory contains three high-performance Go web servers using different frameworks:

- **Fiber** - Express-inspired web framework built on top of Fasthttp
- **Gin** - HTTP web framework with a martini-like API
- **Echo** - High performance, minimalist Go web framework

## Configuration

All servers read configuration from the `.env` file in the project root:

- `ORIGIN_URL` or `ORIGIN_URL_BASE` - Base URL for proxy endpoints
- `SERVER_START_PORT` - Base port number (default: 3001)
- `SERVER_WORKER_THREADS` - Number of worker threads (0 = auto)

## Port Assignment

- Fiber: Port 3004 (offset 3)
- Gin: Port 3005 (offset 4)
- Echo: Port 3006 (offset 5)

## Building

```bash
# Build all servers
make build

# Or build individually
cd fiber && go build
cd gin && go build
cd echo && go build
```

## Running

```bash
# Run all servers (in separate terminals)
make run-fiber
make run-gin
make run-echo

# Or run directly
cd fiber && ./fiber-server
cd gin && ./gin-server
cd echo && ./echo-server
```

## Endpoints

Each server implements the following endpoints:

- `GET /local/20k` - Serve 20KB local image
- `GET /local/50k` - Serve 50KB local image
- `GET /local/100k` - Serve 100KB local image
- `GET /proxy/20k` - Proxy 20KB image from origin
- `GET /proxy/50k` - Proxy 50KB image from origin
- `GET /proxy/100k` - Proxy 100KB image from origin
- `GET /health` - Health check endpoint

## Performance Optimizations

- Disabled unnecessary middleware
- Optimized HTTP client settings for proxy requests
- Efficient file serving for local images
- Streaming response bodies for proxy requests
- Configurable worker threads via GOMAXPROCS