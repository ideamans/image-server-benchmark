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

	"github.com/gofiber/fiber/v2"
	"github.com/ideamans/image-server-benchmark/servers/go/common"
)

func main() {
	// Set GOMAXPROCS based on worker threads config
	if common.Config.WorkerThreads > 0 {
		runtime.GOMAXPROCS(common.Config.WorkerThreads)
	}

	// Create Fiber app with optimized settings
	app := fiber.New(fiber.Config{
		Prefork:               false,
		ServerHeader:          "Fiber",
		DisableStartupMessage: false,
		ReduceMemoryUsage:     true,
		DisableKeepalive:      false,
		ReadTimeout:           10 * time.Second,
		WriteTimeout:          10 * time.Second,
		IdleTimeout:           120 * time.Second,
	})

	// Local image endpoints
	app.Get("/local/20k", func(c *fiber.Ctx) error {
		return serveLocalImage(c, "20k.jpg")
	})

	app.Get("/local/50k", func(c *fiber.Ctx) error {
		return serveLocalImage(c, "50k.jpg")
	})

	app.Get("/local/100k", func(c *fiber.Ctx) error {
		return serveLocalImage(c, "100k.jpg")
	})

	// Proxy image endpoints
	app.Get("/proxy/20k", func(c *fiber.Ctx) error {
		return proxyImage(c, "20k.jpg")
	})

	app.Get("/proxy/50k", func(c *fiber.Ctx) error {
		return proxyImage(c, "50k.jpg")
	})

	app.Get("/proxy/100k", func(c *fiber.Ctx) error {
		return proxyImage(c, "100k.jpg")
	})

	// Health check endpoint
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "ok",
			"server": "fiber",
		})
	})

	// Start server
	port := common.GetServerPort(3) // Fiber uses offset 3 (port 3004)
	log.Printf("Fiber server listening on 0.0.0.0:%d", port)
	if err := app.Listen(fmt.Sprintf("0.0.0.0:%d", port)); err != nil {
		log.Fatalf("Error starting server: %v", err)
	}
}

func serveLocalImage(c *fiber.Ctx, filename string) error {
	imagePath := filepath.Join(common.Config.ImagesPath, filename)
	
	// Check if file exists
	if _, err := os.Stat(imagePath); os.IsNotExist(err) {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Image not found",
		})
	}
	
	// Serve the file
	c.Set("Content-Type", "image/jpeg")
	c.Set("Cache-Control", "no-cache")
	return c.SendFile(imagePath)
}

func proxyImage(c *fiber.Ctx, imageName string) error {
	url := common.GetProxyURL(imageName)
	
	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: 30 * time.Second,
	}
	
	// Make request
	resp, err := client.Get(url)
	if err != nil {
		log.Printf("Proxy error: %v", err)
		return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{
			"error": "Bad gateway",
		})
	}
	defer resp.Body.Close()
	
	// Check response status
	if resp.StatusCode != http.StatusOK {
		return c.Status(resp.StatusCode).JSON(fiber.Map{
			"error": fmt.Sprintf("Upstream error: %s", resp.Status),
		})
	}
	
	// Forward content-type header
	if contentType := resp.Header.Get("Content-Type"); contentType != "" {
		c.Set("Content-Type", contentType)
	}
	
	// Stream the response
	c.Set("Content-Length", resp.Header.Get("Content-Length"))
	c.Status(fiber.StatusOK)
	
	// Copy response body to client
	_, err = io.Copy(c.Response().BodyWriter(), resp.Body)
	if err != nil {
		log.Printf("Error streaming response: %v", err)
		return err
	}
	
	return nil
}