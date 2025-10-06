package middleware

import (
	"net/http"
	"time"

	"github.com/devsecops/user-service/internal/models"
	"github.com/gin-gonic/gin"
	"github.com/ulule/limiter/v3"
	"github.com/ulule/limiter/v3/drivers/store/memory"
)

// RateLimitMiddleware limits the rate of requests
func RateLimitMiddleware(requests int64, window time.Duration) gin.HandlerFunc {
	rate := limiter.Rate{
		Period: window,
		Limit:  requests,
	}

	store := memory.NewStore()
	instance := limiter.New(store, rate)

	return func(c *gin.Context) {
		context := limiter.Context{
			Limit:      rate.Limit,
			Remaining:  0,
			Reset:      0,
			Reached:    false,
		}

		// Get client IP
		clientIP := c.ClientIP()

		// Check rate limit
		ctx, err := instance.Get(c.Request.Context(), clientIP)
		if err != nil {
			c.JSON(http.StatusInternalServerError, models.ErrorResponse{
				Error: models.ErrorDetail{
					Code:    "INTERNAL_ERROR",
					Message: "Rate limit check failed",
				},
			})
			c.Abort()
			return
		}

		context = ctx

		// Set rate limit headers
		c.Header("X-RateLimit-Limit", string(context.Limit))
		c.Header("X-RateLimit-Remaining", string(context.Remaining))
		c.Header("X-RateLimit-Reset", string(context.Reset))

		if context.Reached {
			c.JSON(http.StatusTooManyRequests, models.ErrorResponse{
				Error: models.ErrorDetail{
					Code:    "RATE_LIMIT_EXCEEDED",
					Message: "Too many requests. Please try again later.",
				},
			})
			c.Abort()
			return
		}

		c.Next()
	}
}
