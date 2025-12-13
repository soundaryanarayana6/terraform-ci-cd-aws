package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {

	log.SetOutput(os.Stdout)
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	log.Println("Starting application...")

	// Configure Gin to write to stdout
	gin.DefaultWriter = os.Stdout
	gin.DefaultErrorWriter = os.Stdout

	// Use custom logger middleware instead of Default()
	r := gin.New()
	r.Use(gin.LoggerWithWriter(os.Stdout))
	r.Use(gin.Recovery())

	r.GET("/health", healthCheck)

	log.Println("Server listening on :8080")
	r.Run(":8080")
}

func healthCheck(c *gin.Context) {
	log.Println("Health check request received")

	if os.Getenv("SKIP_DB_CHECK") == "true" {
		log.Println("Skipping DB check (SKIP_DB_CHECK=true)")
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
		return
	}

	rdsEndpoint := os.Getenv("RDS_ENDPOINT")
	if rdsEndpoint == "" {
		log.Println("ERROR: RDS_ENDPOINT not configured")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "RDS_ENDPOINT not configured"})
		return
	}
	log.Printf("RDS_ENDPOINT: %s", rdsEndpoint)

	username := os.Getenv("DB_USERNAME")
	if username == "" {
		log.Println("ERROR: DB_USERNAME not configured")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "DB_USERNAME not configured"})
		return
	}
	log.Printf("DB_USERNAME: %s", username)

	password := os.Getenv("DB_PASSWORD")
	if password == "" {
		log.Println("ERROR: DB_PASSWORD not configured")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "DB_PASSWORD not configured"})
		return
	}
	log.Println("DB_PASSWORD: [REDACTED]")

	dbName := os.Getenv("DB_NAME")
	if dbName == "" {
		dbName = "postgres" 
		log.Println("DB_NAME not set, using default: postgres")
	} else {
		log.Printf("Using database: %s", dbName)
	}
	dbPort := "5432"


	hostname := rdsEndpoint
	if strings.Contains(rdsEndpoint, ":") {
		parts := strings.Split(rdsEndpoint, ":")
		hostname = parts[0]
		if len(parts) > 1 {
			dbPort = parts[1]
			log.Printf("Extracted port from RDS_ENDPOINT: %s", dbPort)
		}
	}
	log.Printf("Database hostname: %s, port: %s, database: %s", hostname, dbPort, dbName)

	dbURL := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?connect_timeout=10", 
		username, password, hostname, dbPort, dbName)

	safeURL := fmt.Sprintf("postgres://%s:****@%s:%s/%s?connect_timeout=10", 
		username, hostname, dbPort, dbName)
	log.Printf("Connecting to database: %s", safeURL)

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		errMsg := fmt.Sprintf("Failed to create connection pool: %v", err)
		log.Printf("ERROR: %s", errMsg)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to connect to DB",
			"details": errMsg,
		})
		return
	}
	defer pool.Close()
	log.Println("Connection pool created successfully")

	// Test the connection
	log.Println("Testing database connection...")
	var version string
	err = pool.QueryRow(ctx, "SELECT version()").Scan(&version)
	if err != nil {
		errMsg := fmt.Sprintf("Failed to query database: %v", err)
		log.Printf("ERROR: %s", errMsg)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to query DB",
			"details": errMsg,
		})
		return
	}

	log.Printf("Database connection successful! PostgreSQL version: %s", version)
	c.JSON(http.StatusOK, gin.H{
		"status": "ok",
		"database": "connected",
		"version": version,
	})
}