use actix_files::NamedFile;
use actix_web::{middleware, web, App, HttpResponse, HttpServer, Result};
use bytes::Bytes;
use dotenv::dotenv;
use futures::StreamExt;
use std::env;
use std::path::PathBuf;

#[derive(Clone)]
struct AppState {
    origin_url_base: String,
}

async fn serve_local_image(size: web::Path<String>) -> Result<NamedFile> {
    let filename = format!("{}.jpg", size.as_str());
    let path: PathBuf = ["../../../images", &filename].iter().collect();
    
    NamedFile::open(path).map_err(|e| {
        log::error!("Failed to open local image: {}", e);
        actix_web::error::ErrorNotFound("Image not found")
    })
}

async fn proxy_image(
    size: web::Path<String>,
    data: web::Data<AppState>,
) -> Result<HttpResponse> {
    let url = format!("{}{}.jpg", data.origin_url_base, size.as_str());
    
    let client = reqwest::Client::new();
    let response = client
        .get(&url)
        .send()
        .await
        .map_err(|e| {
            log::error!("Failed to fetch image from origin: {}", e);
            actix_web::error::ErrorBadGateway("Failed to fetch image")
        })?;
    
    if !response.status().is_success() {
        return Err(actix_web::error::ErrorBadGateway("Origin returned error"));
    }
    
    let content_type = response
        .headers()
        .get("content-type")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("image/jpeg");
    
    let mut body = Vec::new();
    let mut stream = response.bytes_stream();
    
    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|e| {
            log::error!("Failed to read response body: {}", e);
            actix_web::error::ErrorBadGateway("Failed to read response")
        })?;
        body.extend_from_slice(&chunk);
    }
    
    Ok(HttpResponse::Ok()
        .content_type(content_type)
        .body(Bytes::from(body)))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Load .env file
    dotenv().ok();
    env_logger::init();
    
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
    
    // Calculate port for Actix (offset 6)
    let port = server_start_port + 6;
    let bind_addr = format!("0.0.0.0:{}", port);
    
    log::info!("Starting Actix-web server on {}", bind_addr);
    log::info!("Origin URL base: {}", origin_url_base);
    
    let app_state = web::Data::new(AppState { origin_url_base });
    
    let mut server = HttpServer::new(move || {
        App::new()
            .app_data(app_state.clone())
            .wrap(middleware::Logger::default())
            .service(
                web::resource("/local/{size}")
                    .route(web::get().to(serve_local_image))
            )
            .service(
                web::resource("/proxy/{size}")
                    .route(web::get().to(proxy_image))
            )
    });
    
    // Configure worker threads
    if worker_threads > 0 {
        server = server.workers(worker_threads);
    }
    
    server.bind(&bind_addr)?.run().await
}