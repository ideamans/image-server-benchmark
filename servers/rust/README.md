# Rust Image Servers

This directory contains three Rust-based image servers using different web frameworks:

- **Actix-web**: Actor-based, high-performance web framework
- **Axum**: Modern, tokio-based web framework from the Tokio team
- **Rocket**: Developer-friendly web framework with a focus on ergonomics

## Building

To build all servers:

```bash
./build.sh
```

Or build individually:

```bash
cd actix && cargo build --release
cd axum && cargo build --release
cd rocket && cargo build --release
```

## Running

Each server reads configuration from the project root `.env` file:

- `ORIGIN_URL_BASE`: Base URL for proxy endpoints
- `SERVER_START_PORT`: Base port number (default: 3001)
- `SERVER_WORKER_THREADS`: Number of worker threads (0 = auto)

Port assignments:
- Actix-web: `SERVER_START_PORT + 6` (default: 3007)
- Axum: `SERVER_START_PORT + 7` (default: 3008)
- Rocket: `SERVER_START_PORT + 8` (default: 3009)

To run servers:

```bash
# Run individually
./actix/start.sh
./axum/start.sh
./rocket/start.sh

# Or run directly with cargo
cd actix && cargo run --release
cd axum && cargo run --release
cd rocket && cargo run --release
```

## Endpoints

All servers implement the same endpoints:

- `GET /local/20k` - Serve 20KB local image
- `GET /local/50k` - Serve 50KB local image
- `GET /local/100k` - Serve 100KB local image
- `GET /proxy/20k` - Proxy 20KB image from origin
- `GET /proxy/50k` - Proxy 50KB image from origin
- `GET /proxy/100k` - Proxy 100KB image from origin

## Performance Optimizations

1. **Actix-web**:
   - Uses async file serving with `actix-files`
   - Configurable worker threads
   - Efficient streaming for proxy responses

2. **Axum**:
   - Built on Tokio async runtime
   - Zero-copy response handling where possible
   - Tower middleware for performance monitoring

3. **Rocket**:
   - Async handlers for all endpoints
   - Efficient file serving with `NamedFile`
   - Configurable worker count

## Dependencies

All servers use:
- `dotenv`: Environment variable loading
- `reqwest`: HTTP client for proxy functionality
- `tokio`: Async runtime
- `bytes`: Efficient byte buffer handling