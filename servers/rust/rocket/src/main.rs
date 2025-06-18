use bytes::Bytes;
use dotenv::dotenv;
use futures::StreamExt;
use rocket::fs::NamedFile;
use rocket::http::{ContentType, Status};
use rocket::response::content::RawHtml;
use rocket::{routes, State};
use std::env;
use std::path::{Path, PathBuf};

struct AppConfig {
    origin_url_base: String,
}

#[rocket::get("/local/<size>")]
async fn serve_local_image(size: &str) -> Result<NamedFile, Status> {
    let filename = format!("{}.jpg", size);
    let path: PathBuf = ["../../../images", &filename].iter().collect();
    
    NamedFile::open(&path).await.map_err(|e| {
        rocket::error!("Failed to open local image: {}", e);
        Status::NotFound
    })
}

#[rocket::get("/proxy/<size>")]
async fn proxy_image(
    size: &str,
    config: &State<AppConfig>,
) -> Result<(ContentType, Vec<u8>), Status> {
    let url = format!("{}{}.jpg", config.origin_url_base, size);
    
    let client = reqwest::Client::new();
    let response = client
        .get(&url)
        .send()
        .await
        .map_err(|e| {
            rocket::error!("Failed to fetch image from origin: {}", e);
            Status::BadGateway
        })?;
    
    if !response.status().is_success() {
        return Err(Status::BadGateway);
    }
    
    let content_type = response
        .headers()
        .get("content-type")
        .and_then(|v| v.to_str().ok())
        .and_then(|ct| ContentType::parse_flexible(ct))
        .unwrap_or(ContentType::JPEG);
    
    let mut body = Vec::new();
    let mut stream = response.bytes_stream();
    
    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|e| {
            rocket::error!("Failed to read response body: {}", e);
            Status::BadGateway
        })?;
        body.extend_from_slice(&chunk);
    }
    
    Ok((content_type, body))
}

#[rocket::main]
async fn main() -> Result<(), rocket::Error> {
    // Load .env file
    dotenv().ok();
    
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
    
    // Calculate port for Rocket (offset 8)
    let port = server_start_port + 8;
    
    rocket::info!("Starting Rocket server on 0.0.0.0:{}", port);
    rocket::info!("Origin URL base: {}", origin_url_base);
    
    let config = AppConfig { origin_url_base };
    
    let mut rocket_config = rocket::Config::default();
    rocket_config.port = port;
    rocket_config.address = std::net::Ipv4Addr::new(0, 0, 0, 0).into();
    
    if worker_threads > 0 {
        rocket_config.workers = worker_threads;
    }
    
    let _rocket = rocket::custom(rocket_config)
        .manage(config)
        .mount("/", routes![serve_local_image, proxy_image])
        .launch()
        .await?;
    
    Ok(())
}