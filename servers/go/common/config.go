package common

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"

	"github.com/joho/godotenv"
)

type ServerConfig struct {
	OriginURLBase    string
	ServerStartPort  int
	WorkerThreads    int
	ImagesPath       string
}

var Config *ServerConfig

func init() {
	// Get the executable directory
	execPath, err := os.Executable()
	if err != nil {
		log.Printf("Warning: Could not determine executable path: %v", err)
		execPath = os.Args[0]
	}
	
	// Navigate from servers/go/{framework} to project root
	execDir := filepath.Dir(execPath)
	projectRoot := filepath.Join(execDir, "..", "..", "..")
	projectRoot, _ = filepath.Abs(projectRoot)
	
	// Try alternative paths if the first one doesn't work
	envPaths := []string{
		filepath.Join(projectRoot, ".env"),
		filepath.Join(execDir, "../../../.env"),
		".env",
	}
	
	for _, envPath := range envPaths {
		if err := godotenv.Load(envPath); err == nil {
			log.Printf("Loaded .env from: %s", envPath)
			break
		}
	}
	
	// Initialize configuration
	Config = &ServerConfig{
		OriginURLBase:   getEnvOrDefault("ORIGIN_URL_BASE", "http://localhost:8080/"),
		ServerStartPort: getEnvAsInt("SERVER_START_PORT", 3001),
		WorkerThreads:   getEnvAsInt("SERVER_WORKER_THREADS", 0),
		ImagesPath:      filepath.Join(projectRoot, "images"),
	}
	
	// Ensure images path exists
	if _, err := os.Stat(Config.ImagesPath); os.IsNotExist(err) {
		// Try alternative image paths
		altPaths := []string{
			filepath.Join(execDir, "../../../images"),
			filepath.Join(execDir, "../../images"),
			"images",
		}
		for _, altPath := range altPaths {
			absPath, _ := filepath.Abs(altPath)
			if _, err := os.Stat(absPath); err == nil {
				Config.ImagesPath = absPath
				break
			}
		}
	}
	
	log.Printf("Configuration loaded: ImagesPath=%s, OriginURL=%s, StartPort=%d", 
		Config.ImagesPath, Config.OriginURLBase, Config.ServerStartPort)
}

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
		log.Printf("Warning: Invalid integer value for %s: %s", key, value)
	}
	return defaultValue
}

// GetServerPort returns the port for a server based on its offset
func GetServerPort(offset int) int {
	return Config.ServerStartPort + offset
}

// GetProxyURL returns the full URL for a proxy image
func GetProxyURL(imageName string) string {
	return fmt.Sprintf("%s%s", Config.OriginURLBase, imageName)
}