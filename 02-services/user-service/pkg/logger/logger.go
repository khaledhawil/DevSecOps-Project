package logger

import (
	"os"

	"github.com/sirupsen/logrus"
)

// NewLogger creates a new logger instance
func NewLogger() *logrus.Logger {
	log := logrus.New()

	// Set output to stdout
	log.SetOutput(os.Stdout)

	// Set log format to JSON for production
	log.SetFormatter(&logrus.JSONFormatter{
		TimestampFormat: "2006-01-02 15:04:05",
	})

	// Set log level from environment or default to Info
	logLevel := os.Getenv("LOG_LEVEL")
	switch logLevel {
	case "debug":
		log.SetLevel(logrus.DebugLevel)
	case "info":
		log.SetLevel(logrus.InfoLevel)
	case "warn":
		log.SetLevel(logrus.WarnLevel)
	case "error":
		log.SetLevel(logrus.ErrorLevel)
	default:
		log.SetLevel(logrus.InfoLevel)
	}

	return log
}
