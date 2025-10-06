# User Service (Go + Gin)

A RESTful microservice for user management built with Go and the Gin framework.

## Overview

The User Service handles all user-related operations including user CRUD operations, profile management, and user data retrieval.

## Technology Stack

- **Language**: Go 1.21
- **Framework**: Gin Web Framework
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **ORM**: GORM
- **Authentication**: JWT tokens
- **Logging**: Logrus
- **Metrics**: Prometheus

## Features

- ✅ User CRUD operations
- ✅ User profile management
- ✅ Input validation
- ✅ JWT authentication middleware
- ✅ Rate limiting
- ✅ Health checks
- ✅ Prometheus metrics
- ✅ Structured logging
- ✅ Redis caching
- ✅ Database migrations
- ✅ Error handling
- ✅ API versioning

## Project Structure

```
user-service/
├── cmd/
│   └── main.go                 # Application entry point
├── internal/
│   ├── config/                 # Configuration
│   │   └── config.go
│   ├── handlers/               # HTTP request handlers
│   │   ├── health.go
│   │   └── user.go
│   ├── middleware/             # HTTP middleware
│   │   ├── auth.go
│   │   ├── cors.go
│   │   ├── logging.go
│   │   └── ratelimit.go
│   ├── models/                 # Data models
│   │   ├── user.go
│   │   └── response.go
│   ├── repository/             # Database layer
│   │   ├── user_repo.go
│   │   └── cache.go
│   └── routes/                 # Route definitions
│       └── routes.go
├── pkg/
│   ├── database/               # Database utilities
│   │   └── postgres.go
│   ├── redis/                  # Redis utilities
│   │   └── redis.go
│   └── logger/                 # Logging utilities
│       └── logger.go
├── Dockerfile                  # Production Dockerfile
├── Dockerfile.dev              # Development Dockerfile
├── go.mod                      # Go dependencies
├── go.sum                      # Go dependency checksums
└── README.md                   # This file
```

## API Endpoints

### Health Checks
- `GET /health` - Basic health check
- `GET /health/ready` - Readiness check (includes DB)
- `GET /health/live` - Liveness check

### User Management
- `GET /api/v1/users` - List all users (with pagination)
- `GET /api/v1/users/:id` - Get user by ID
- `POST /api/v1/users` - Create new user
- `PUT /api/v1/users/:id` - Update user
- `DELETE /api/v1/users/:id` - Delete user (soft delete)

### User Profile
- `GET /api/v1/users/:id/profile` - Get user profile
- `PUT /api/v1/users/:id/profile` - Update user profile

### Metrics
- `GET /metrics` - Prometheus metrics

## Environment Variables

```bash
# Service Configuration
PORT=8081
SERVICE_NAME=user-service
ENVIRONMENT=development
LOG_LEVEL=debug

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=devsecops
DB_USER=postgres
DB_PASSWORD=postgres123
DB_SSL_MODE=disable
DB_MAX_CONNECTIONS=25
DB_MAX_IDLE_CONNECTIONS=5

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis123
REDIS_DB=0
CACHE_TTL=300

# JWT Configuration
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRATION=3600

# Rate Limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60
```

## Local Development

### Prerequisites
- Go 1.21 or later
- PostgreSQL 15
- Redis 7
- Docker (optional)

### Setup

1. **Install dependencies**:
```bash
go mod download
```

2. **Set environment variables**:
```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=devsecops
export DB_USER=postgres
export DB_PASSWORD=postgres123
export REDIS_HOST=localhost
export REDIS_PORT=6379
export JWT_SECRET=dev-secret-key
```

3. **Run the service**:
```bash
go run cmd/main.go
```

4. **Run with hot reload** (using air):
```bash
# Install air
go install github.com/cosmtrek/air@latest

# Run with hot reload
air
```

### Testing

```bash
# Run all tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run tests with coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

### Building

```bash
# Build binary
go build -o bin/user-service cmd/main.go

# Run binary
./bin/user-service
```

## Docker

### Development

```bash
# Build development image
docker build -f Dockerfile.dev -t user-service:dev .

# Run container
docker run -d \
  --name user-service \
  -p 8081:8081 \
  -e DB_HOST=postgres \
  -e REDIS_HOST=redis \
  user-service:dev
```

### Production

```bash
# Build production image
docker build -t user-service:latest .

# Run container
docker run -d \
  --name user-service \
  -p 8081:8081 \
  -e DB_HOST=postgres \
  -e REDIS_HOST=redis \
  user-service:latest
```

## API Examples

### Create User

```bash
curl -X POST http://localhost:8081/api/v1/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "email": "user@example.com",
    "username": "johndoe",
    "first_name": "John",
    "last_name": "Doe",
    "password": "SecurePassword123!"
  }'
```

### Get User

```bash
curl -X GET http://localhost:8081/api/v1/users/USER_ID \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Update User

```bash
curl -X PUT http://localhost:8081/api/v1/users/USER_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "first_name": "Jane",
    "last_name": "Smith"
  }'
```

### List Users (with pagination)

```bash
curl -X GET "http://localhost:8081/api/v1/users?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Security

- **Input Validation**: All inputs are validated before processing
- **SQL Injection Prevention**: Using GORM parameterized queries
- **Password Hashing**: Passwords are never stored in plain text
- **JWT Authentication**: Bearer token authentication
- **Rate Limiting**: API rate limiting to prevent abuse
- **CORS**: Configured CORS policies
- **Secure Headers**: Security headers added to all responses

## Performance

- **Connection Pooling**: Database connection pooling configured
- **Redis Caching**: Frequently accessed data cached in Redis
- **Pagination**: Large result sets paginated
- **Indexes**: Database indexes on frequently queried fields
- **Graceful Shutdown**: Proper cleanup on service shutdown

## Monitoring

- **Prometheus Metrics**: Available at `/metrics`
- **Health Checks**: Multiple health check endpoints
- **Structured Logging**: JSON-formatted logs
- **Request Logging**: All requests logged with details

## Troubleshooting

### Cannot connect to database
- Verify PostgreSQL is running: `pg_isready`
- Check connection details in environment variables
- Ensure database exists: `psql -U postgres -l`

### Cannot connect to Redis
- Verify Redis is running: `redis-cli ping`
- Check Redis connection details
- Verify Redis password if set

### Port already in use
```bash
# Find process using port 8081
lsof -i :8081

# Kill process
kill -9 <PID>
```

## Contributing

1. Follow Go best practices and idioms
2. Write tests for new features
3. Use `gofmt` to format code
4. Run linters: `golangci-lint run`
5. Update documentation

## License

MIT License
