package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ideamans/image-server-benchmark/servers/go/common"
)

func main() {
	// Set GOMAXPROCS based on worker threads config
	if common.Config.WorkerThreads > 0 {
		runtime.GOMAXPROCS(common.Config.WorkerThreads)
	}

	// Set Gin to release mode for better performance
	gin.SetMode(gin.ReleaseMode)

	// Create Gin router with optimized settings
	router := gin.New()
	router.Use(gin.Recovery())

	// Local image endpoints
	router.GET("/local/20k", func(c *gin.Context) {
		serveLocalImage(c, "20k.jpg")
	})

	router.GET("/local/50k", func(c *gin.Context) {
		serveLocalImage(c, "50k.jpg")
	})

	router.GET("/local/100k", func(c *gin.Context) {
		serveLocalImage(c, "100k.jpg")
	})

	// Proxy image endpoints
	router.GET("/proxy/20k", func(c *gin.Context) {
		proxyImage(c, "20k.jpg")
	})

	router.GET("/proxy/50k", func(c *gin.Context) {
		proxyImage(c, "50k.jpg")
	})

	router.GET("/proxy/100k", func(c *gin.Context) {
		proxyImage(c, "100k.jpg")
	})

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "ok",
			"server": "gin",
		})
	})

	// Start server
	port := common.GetServerPort(4) // Gin uses offset 4 (port 3005)
	log.Printf("Gin server listening on 0.0.0.0:%d", port)
	
	server := &http.Server{
		Addr:         fmt.Sprintf("0.0.0.0:%d", port),
		Handler:      router,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  120 * time.Second,
	}
	
	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("Error starting server: %v", err)
	}
}

func serveLocalImage(c *gin.Context, filename string) {
	imagePath := filepath.Join(common.Config.ImagesPath, filename)
	
	// Check if file exists
	if _, err := os.Stat(imagePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "Image not found",
		})
		return
	}
	
	// Serve the file
	c.Header("Content-Type", "image/jpeg")
	c.Header("Cache-Control", "no-cache")
	c.File(imagePath)
}

func proxyImage(c *gin.Context, imageName string) {
	url := common.GetProxyURL(imageName)
	
	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: 30 * time.Second,
	}
	
	// Make request
	resp, err := client.Get(url)
	if err != nil {
		log.Printf("Proxy error: %v", err)
		c.JSON(http.StatusBadGateway, gin.H{
			"error": "Bad gateway",
		})
		return
	}
	defer resp.Body.Close()
	
	// Check response status
	if resp.StatusCode != http.StatusOK {
		c.JSON(resp.StatusCode, gin.H{
			"error": fmt.Sprintf("Upstream error: %s", resp.Status),
		})
		return
	}
	
	// Forward content-type header
	if contentType := resp.Header.Get("Content-Type"); contentType != "" {
		c.Header("Content-Type", contentType)
	}
	
	// Forward content-length header
	if contentLength := resp.Header.Get("Content-Length"); contentLength != "" {
		c.Header("Content-Length", contentLength)
	}
	
	// Stream the response
	c.Status(http.StatusOK)
	
	// Copy response body to client
	_, err = io.Copy(c.Writer, resp.Body)
	if err != nil {
		log.Printf("Error streaming response: %v", err)
	}
}