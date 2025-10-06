package handlers

import (
	"net/http"

	"github.com/devsecops/user-service/internal/models"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// HealthHandler handles health check requests
type HealthHandler struct {
	db *gorm.DB
}

// NewHealthHandler creates a new health handler
func NewHealthHandler(db *gorm.DB) *HealthHandler {
	return &HealthHandler{
		db: db,
	}
}

// Health returns basic health status
func (h *HealthHandler) Health(c *gin.Context) {
	c.JSON(http.StatusOK, models.HealthResponse{
		Status:  "healthy",
		Service: "user-service",
		Version: "1.0.0",
	})
}

// ReadinessCheck checks if service is ready (includes DB check)
func (h *HealthHandler) ReadinessCheck(c *gin.Context) {
	checks := make(map[string]string)

	// Check database connection
	sqlDB, err := h.db.DB()
	if err != nil {
		checks["database"] = "unhealthy"
		c.JSON(http.StatusServiceUnavailable, models.HealthResponse{
			Status:  "unhealthy",
			Service: "user-service",
			Version: "1.0.0",
			Checks:  checks,
		})
		return
	}

	if err := sqlDB.Ping(); err != nil {
		checks["database"] = "unhealthy"
		c.JSON(http.StatusServiceUnavailable, models.HealthResponse{
			Status:  "unhealthy",
			Service: "user-service",
			Version: "1.0.0",
			Checks:  checks,
		})
		return
	}

	checks["database"] = "healthy"

	c.JSON(http.StatusOK, models.HealthResponse{
		Status:  "healthy",
		Service: "user-service",
		Version: "1.0.0",
		Checks:  checks,
	})
}

// LivenessCheck checks if service is alive
func (h *HealthHandler) LivenessCheck(c *gin.Context) {
	c.JSON(http.StatusOK, models.HealthResponse{
		Status:  "alive",
		Service: "user-service",
		Version: "1.0.0",
	})
}
