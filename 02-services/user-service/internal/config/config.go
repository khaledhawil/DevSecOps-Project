package config

import (
	"os"
	"strconv"
)

// Config holds all configuration for the application
type Config struct {
	// Service configuration
	Port        string
	ServiceName string
	Environment string
	LogLevel    string

	// Database configuration
	DBHost           string
	DBPort           string
	DBName           string
	DBUser           string
	DBPassword       string
	DBSSLMode        string
	DBMaxConnections int
	DBMaxIdleConns   int

	// Redis configuration
	RedisHost     string
	RedisPort     string
	RedisPassword string
	RedisDB       int
	CacheTTL      int

	// JWT configuration
	JWTSecret     string
	JWTExpiration int

	// Rate limiting
	RateLimitRequests int
	RateLimitWindow   int
}

// LoadConfig loads configuration from environment variables
func LoadConfig() *Config {
	return &Config{
		// Service configuration
		Port:        getEnv("PORT", "8081"),
		ServiceName: getEnv("SERVICE_NAME", "user-service"),
		Environment: getEnv("ENVIRONMENT", "development"),
		LogLevel:    getEnv("LOG_LEVEL", "info"),

		// Database configuration
		DBHost:           getEnv("DB_HOST", "localhost"),
		DBPort:           getEnv("DB_PORT", "5432"),
		DBName:           getEnv("DB_NAME", "devsecops"),
		DBUser:           getEnv("DB_USER", "postgres"),
		DBPassword:       getEnv("DB_PASSWORD", "postgres123"),
		DBSSLMode:        getEnv("DB_SSL_MODE", "disable"),
		DBMaxConnections: getEnvInt("DB_MAX_CONNECTIONS", 25),
		DBMaxIdleConns:   getEnvInt("DB_MAX_IDLE_CONNECTIONS", 5),

		// Redis configuration
		RedisHost:     getEnv("REDIS_HOST", "localhost"),
		RedisPort:     getEnv("REDIS_PORT", "6379"),
		RedisPassword: getEnv("REDIS_PASSWORD", ""),
		RedisDB:       getEnvInt("REDIS_DB", 0),
		CacheTTL:      getEnvInt("CACHE_TTL", 300),

		// JWT configuration
		JWTSecret:     getEnv("JWT_SECRET", "your-secret-key-change-in-production"),
		JWTExpiration: getEnvInt("JWT_EXPIRATION", 3600),

		// Rate limiting
		RateLimitRequests: getEnvInt("RATE_LIMIT_REQUESTS", 100),
		RateLimitWindow:   getEnvInt("RATE_LIMIT_WINDOW", 60),
	}
}

// getEnv retrieves an environment variable with a fallback default value
func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

// getEnvInt retrieves an integer environment variable with a fallback default value
func getEnvInt(key string, defaultValue int) int {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}

	intValue, err := strconv.Atoi(value)
	if err != nil {
		return defaultValue
	}

	return intValue
}
