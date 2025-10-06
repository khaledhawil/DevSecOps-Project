package routes

import (
	"time"

	"github.com/devsecops/user-service/internal/config"
	"github.com/devsecops/user-service/internal/handlers"
	"github.com/devsecops/user-service/internal/middleware"
	"github.com/devsecops/user-service/internal/repository"
	pkgRedis "github.com/devsecops/user-service/pkg/redis"
	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/sirupsen/logrus"
	"gorm.io/gorm"
)

// SetupRoutes configures all routes for the application
func SetupRoutes(router *gin.Engine, db *gorm.DB, redisClient *pkgRedis.RedisClient, cfg *config.Config, log *logrus.Logger) {
	// Global middleware
	router.Use(gin.Recovery())
	router.Use(middleware.LoggingMiddleware(log))
	router.Use(middleware.CORSMiddleware())

	// Rate limiting (100 requests per minute)
	router.Use(middleware.RateLimitMiddleware(int64(cfg.RateLimitRequests), time.Duration(cfg.RateLimitWindow)*time.Second))

	// Initialize repositories
	userRepo := repository.NewUserRepository(db, redisClient, log)

	// Initialize handlers
	healthHandler := handlers.NewHealthHandler(db)
	userHandler := handlers.NewUserHandler(userRepo, log)

	// Health check routes (no auth required)
	router.GET("/health", healthHandler.Health)
	router.GET("/health/ready", healthHandler.ReadinessCheck)
	router.GET("/health/live", healthHandler.LivenessCheck)

	// Prometheus metrics (no auth required)
	router.GET("/metrics", gin.WrapH(promhttp.Handler()))

	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		// User routes (protected by auth middleware)
		users := v1.Group("/users")
		users.Use(middleware.AuthMiddleware(cfg))
		{
			users.GET("", userHandler.ListUsers)
			users.GET("/:id", userHandler.GetUser)
			users.POST("", userHandler.CreateUser)
			users.PUT("/:id", userHandler.UpdateUser)
			users.DELETE("/:id", userHandler.DeleteUser)

			// Profile routes
			users.GET("/:id/profile", userHandler.GetProfile)
			users.PUT("/:id/profile", userHandler.UpdateProfile)
		}
	}
}
