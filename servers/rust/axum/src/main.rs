use axum::{
    extract::{Path, State},
    http::{header, StatusCode},
    response::{IntoResponse, Response},
    routing::get,
    Json,
    Router,
};
use bytes::Bytes;
use dotenv::dotenv;
use futures::StreamExt;
use serde::{Deserialize, Serialize};
use std::env;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::fs::File;
use tokio::io::AsyncReadExt;
use tower_http::trace::TraceLayer;
use tracing::info;

#[derive(Clone)]
struct AppState {
    origin_url_base: String,
}

#[derive(Serialize, Deserialize)]
struct HealthResponse {
    status: String,
}

async fn serve_local_image(Path(size): Path<String>) -> Result<impl IntoResponse, StatusCode> {
    let filename = format!("{}.jpg", size);
    let path: PathBuf = ["../../../images", &filename].iter().collect();
    
    let mut file = File::open(&path).await.map_err(|e| {
        tracing::error!("Failed to open local image: {}", e);
        StatusCode::NOT_FOUND
    })?;
    
    let mut contents = Vec::new();
    file.read_to_end(&mut contents).await.map_err(|e| {
        tracing::error!("Failed to read local image: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    
    Ok((
        [(header::CONTENT_TYPE, "image/jpeg")],
        Bytes::from(contents),
    ))
}

async fn proxy_image(
    Path(size): Path<String>,
    State(state): State<Arc<AppState>>,
) -> Result<Response, StatusCode> {
    let url = format!("{}{}.jpg", state.origin_url_base, size);
    
    let client = reqwest::Client::new();
    let response = client
        .get(&url)
        .send()
        .await
        .map_err(|e| {
            tracing::error!("Failed to fetch image from origin: {}", e);
            StatusCode::BAD_GATEWAY
        })?;
    
    if !response.status().is_success() {
        return Err(StatusCode::BAD_GATEWAY);
    }
    
    let content_type = response
        .headers()
        .get("content-type")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("image/jpeg")
        .to_string();
    
    let mut body = Vec::new();
    let mut stream = response.bytes_stream();
    
    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|e| {
            tracing::error!("Failed to read response body: {}", e);
            StatusCode::BAD_GATEWAY
        })?;
        body.extend_from_slice(&chunk);
    }
    
    Ok((
        [(header::CONTENT_TYPE, content_type)],
        Bytes::from(body),
    ).into_response())
}

async fn health() -> impl IntoResponse {
    let response = HealthResponse {
        status: "ok".to_string(),
    };
    Json(response)
}

#[tokio::main]
async fn main() {
    // Load .env file
    dotenv().ok();
    
    // Initialize tracing
    tracing_subscriber::fmt::init();
    
    // Read configuration
    let origin_url_base = env::var("ORIGIN_URL_BASE")
        .unwrap_or_else(|_| "http://localhost:8080/".to_string());
    let server_start_port: u16 = env::var("SERVER_START_PORT")
        .unwrap_or_else(|_| "3001".to_string())
        .parse()
        .unwrap_or(3001);
    let worker_threads: usize = env::var("SERVER_WORKER_THREADS")
        .unwrap_or_else(|_| "0".to_string())
        .parse()
        .unwrap_or(0);
    
    // Calculate port for Axum (offset 7)
    let port = server_start_port + 7;
    let bind_addr = format!("0.0.0.0:{}", port);
    
    info!("Starting Axum server on {}", bind_addr);
    info!("Origin URL base: {}", origin_url_base);
    
    // Configure runtime
    if worker_threads > 0 {
        std::env::set_var("TOKIO_WORKER_THREADS", worker_threads.to_string());
    }
    
    let state = Arc::new(AppState { origin_url_base });
    
    // Build our application with routes
    let app = Router::new()
        .route("/health", get(health))
        .route("/local/:size", get(serve_local_image))
        .route("/proxy/:size", get(proxy_image))
        .layer(TraceLayer::new_for_http())
        .with_state(state);
    
    // Run the server
    let listener = tokio::net::TcpListener::bind(&bind_addr)
        .await
        .expect("Failed to bind");
    
    axum::serve(listener, app)
        .await
        .expect("Server failed");
}