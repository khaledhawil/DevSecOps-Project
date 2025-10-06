require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const routes = require('./routes');
const { logger } = require('./utils/logger');
const { sequelize } = require('./models');
const redis = require('./utils/redis');

const app = express();
const PORT = process.env.PORT || 8082;

// Security middleware
app.use(helmet());
app.use(cors());

// Request logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/v1', routes);

// Health check routes
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'auth-service',
    version: '1.0.0'
  });
});

app.get('/health/ready', async (req, res) => {
  try {
    // Check database connection
    await sequelize.authenticate();
    
    // Check Redis connection
    await redis.ping();
    
    res.json({
      status: 'healthy',
      service: 'auth-service',
      version: '1.0.0',
      checks: {
        database: 'healthy',
        redis: 'healthy'
      }
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      service: 'auth-service',
      version: '1.0.0',
      checks: {
        database: 'unhealthy',
        redis: 'unhealthy'
      }
    });
  }
});

app.get('/health/live', (req, res) => {
  res.json({
    status: 'alive',
    service: 'auth-service',
    version: '1.0.0'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err);
  res.status(err.status || 500).json({
    error: {
      code: err.code || 'INTERNAL_ERROR',
      message: err.message || 'Internal server error'
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: {
      code: 'NOT_FOUND',
      message: 'Route not found'
    }
  });
});

// Start server
const startServer = async () => {
  try {
    // Test database connection
    await sequelize.authenticate();
    logger.info('Database connection established');

    // Sync database models
    if (process.env.NODE_ENV === 'development') {
      await sequelize.sync({ alter: false });
      logger.info('Database models synchronized');
    }

    // Test Redis connection
    try {
      await redis.ping();
      logger.info('Redis connection established');
    } catch (error) {
      logger.warn('Redis connection failed, continuing without cache');
    }

    // Start listening
    app.listen(PORT, () => {
      logger.info(`Auth service listening on port ${PORT}`);
      logger.info(`Environment: ${process.env.NODE_ENV}`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, shutting down gracefully');
  await sequelize.close();
  await redis.quit();
  process.exit(0);
});

process.on('SIGINT', async () => {
  logger.info('SIGINT received, shutting down gracefully');
  await sequelize.close();
  await redis.quit();
  process.exit(0);
});

startServer();

module.exports = app;
