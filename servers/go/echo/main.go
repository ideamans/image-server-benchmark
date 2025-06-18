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

	"github.com/ideamans/image-server-benchmark/servers/go/common"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func main() {
	// Set GOMAXPROCS based on worker threads config
	if common.Config.WorkerThreads > 0 {
		runtime.GOMAXPROCS(common.Config.WorkerThreads)
	}

	// Create Echo instance with optimized settings
	e := echo.New()
	e.HideBanner = true
	e.HidePort = false
	
	// Use only essential middleware
	e.Use(middleware.Recover())
	
	// Disable debug mode
	e.Debug = false

	// Local image endpoints
	e.GET("/local/20k", func(c echo.Context) error {
		return serveLocalImage(c, "20k.jpg")
	})

	e.GET("/local/50k", func(c echo.Context) error {
		return serveLocalImage(c, "50k.jpg")
	})

	e.GET("/local/100k", func(c echo.Context) error {
		return serveLocalImage(c, "100k.jpg")
	})

	// Proxy image endpoints
	e.GET("/proxy/20k", func(c echo.Context) error {
		return proxyImage(c, "20k.jpg")
	})

	e.GET("/proxy/50k", func(c echo.Context) error {
		return proxyImage(c, "50k.jpg")
	})

	e.GET("/proxy/100k", func(c echo.Context) error {
		return proxyImage(c, "100k.jpg")
	})

	// Health check endpoint
	e.GET("/health", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{
			"status": "ok",
			"server": "echo",
		})
	})

	// Start server
	port := common.GetServerPort(5) // Echo uses offset 5 (port 3006)
	
	// Configure server
	e.Server = &http.Server{
		Addr:         fmt.Sprintf("0.0.0.0:%d", port),
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  120 * time.Second,
	}
	
	log.Printf("Echo server listening on 0.0.0.0:%d", port)
	if err := e.Start(fmt.Sprintf("0.0.0.0:%d", port)); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Error starting server: %v", err)
	}
}

func serveLocalImage(c echo.Context, filename string) error {
	imagePath := filepath.Join(common.Config.ImagesPath, filename)
	
	// Check if file exists
	if _, err := os.Stat(imagePath); os.IsNotExist(err) {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": "Image not found",
		})
	}
	
	// Serve the file
	c.Response().Header().Set("Content-Type", "image/jpeg")
	c.Response().Header().Set("Cache-Control", "no-cache")
	return c.File(imagePath)
}

func proxyImage(c echo.Context, imageName string) error {
	url := common.GetProxyURL(imageName)
	
	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: 30 * time.Second,
	}
	
	// Make request
	resp, err := client.Get(url)
	if err != nil {
		log.Printf("Proxy error: %v", err)
		return c.JSON(http.StatusBadGateway, map[string]string{
			"error": "Bad gateway",
		})
	}
	defer resp.Body.Close()
	
	// Check response status
	if resp.StatusCode != http.StatusOK {
		return c.JSON(resp.StatusCode, map[string]string{
			"error": fmt.Sprintf("Upstream error: %s", resp.Status),
		})
	}
	
	// Forward content-type header
	if contentType := resp.Header.Get("Content-Type"); contentType != "" {
		c.Response().Header().Set("Content-Type", contentType)
	}
	
	// Forward content-length header
	if contentLength := resp.Header.Get("Content-Length"); contentLength != "" {
		c.Response().Header().Set("Content-Length", contentLength)
	}
	
	// Set status code
	c.Response().WriteHeader(http.StatusOK)
	
	// Stream the response
	_, err = io.Copy(c.Response().Writer, resp.Body)
	if err != nil {
		log.Printf("Error streaming response: %v", err)
		return err
	}
	
	return nil
}