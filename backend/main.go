package main

import (
	"context"
	"context" 
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	r := gin.Default()

	r.GET("/health", healthCheck)

	r.Run(":8080")
}

func healthCheck(c *gin.Context) {
	if os.Getenv("SKIP_DB_CHECK") == "true" {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
		return
	}

	rdsEndpoint := os.Getenv("RDS_ENDPOINT")
	if rdsEndpoint == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "RDS_ENDPOINT not configured"})
		return
	}

	username := os.Getenv("DB_USERNAME")
	if username == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "DB_USERNAME not configured"})
		return
	}

	password := os.Getenv("DB_PASSWORD")
	if password == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "DB_PASSWORD not configured"})
		return
	}

	dbName := "mydb"
	dbPort := "5432"

	dbURL := "postgres://" + username + ":" + password + "@" + rdsEndpoint + ":" + dbPort + "/" + dbName

	pool, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to DB"})
		return
	}
	defer pool.Close()

	var version string
	err = pool.QueryRow(context.Background(), "SELECT version()").Scan(&version)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to query DB"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}