package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/devsecops/user-service/internal/config"
	"github.com/devsecops/user-service/internal/routes"
	"github.com/devsecops/user-service/pkg/database"
	"github.com/devsecops/user-service/pkg/logger"
	"github.com/devsecops/user-service/pkg/redis"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables from .env file (if exists)
	_ = godotenv.Load()

	// Initialize logger
	log := logger.NewLogger()
	log.Info("Starting User Service...")

	// Load configuration
	cfg := config.LoadConfig()
	log.Infof("Environment: %s", cfg.Environment)

	// Set Gin mode based on environment
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Initialize database connection
	db, err := database.NewPostgresDB(cfg)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	log.Info("Database connection established")

	// Auto-migrate database models
	if err := database.AutoMigrate(db); err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}
	log.Info("Database migration completed")

	// Initialize Redis client
	redisClient, err := redis.NewRedisClient(cfg)
	if err != nil {
		log.Warnf("Failed to connect to Redis: %v", err)
		log.Warn("Continuing without Redis cache")
	} else {
		log.Info("Redis connection established")
	}

	// Create Gin router
	router := gin.New()

	// Setup routes with dependencies
	routes.SetupRoutes(router, db, redisClient, cfg, log)

	// Create HTTP server
	srv := &http.Server{
		Addr:           fmt.Sprintf(":%s", cfg.Port),
		Handler:        router,
		ReadTimeout:    15 * time.Second,
		WriteTimeout:   15 * time.Second,
		IdleTimeout:    60 * time.Second,
		MaxHeaderBytes: 1 << 20, // 1 MB
	}

	// Start server in a goroutine
	go func() {
		log.Infof("Server listening on port %s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info("Shutting down server...")

	// Graceful shutdown with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Shutdown HTTP server
	if err := srv.Shutdown(ctx); err != nil {
		log.Errorf("Server forced to shutdown: %v", err)
	}

	// Close database connection
	sqlDB, _ := db.DB()
	if sqlDB != nil {
		sqlDB.Close()
		log.Info("Database connection closed")
	}

	// Close Redis connection
	if redisClient != nil {
		redisClient.Close()
		log.Info("Redis connection closed")
	}

	log.Info("Server exited")
}
