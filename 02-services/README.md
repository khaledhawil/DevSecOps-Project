# Microservices - Service Implementations

This directory contains all microservice implementations for the DevSecOps platform.

## Overview

The platform consists of 5 microservices and 1 frontend application:

```
┌─────────────────────────────────────────────────────────────┐
│                     Load Balancer (ALB)                      │
└────────────┬────────────────────────────────────────────────┘
             │
    ┌────────┴────────┐
    │                 │
┌───▼────┐      ┌────▼─────────────────────────────────┐
│ React  │      │         API Gateway/Backend          │
│Frontend│      └──┬───┬───┬────────┬────────────┬─────┘
│(Nginx) │         │   │   │        │            │
└────────┘         │   │   │        │            │
              ┌────▼┐ ┌▼───▼┐  ┌───▼──────┐ ┌───▼───────┐
              │User │ │Auth │  │Notif.    │ │Analytics  │
              │Svc  │ │Svc  │  │Service   │ │Service    │
              │(Go) │ │(Node)│  │(Python)  │ │(Java)     │
              └──┬──┘ └──┬──┘  └────┬─────┘ └─────┬─────┘
                 │       │          │             │
            ┌────▼───────▼──────────▼─────────────▼────┐
            │         PostgreSQL RDS + Redis           │
            └──────────────────────────────────────────┘
```

## Services Architecture

### 1. Frontend (React + Nginx)
- **Technology**: React 18, TypeScript, TailwindCSS
- **Port**: 3000 (dev), 80 (prod)
- **Purpose**: User interface for the platform
- **Features**:
  - User authentication UI
  - Dashboard with analytics
  - Profile management
  - Notification center

### 2. User Service (Go + Gin)
- **Technology**: Go 1.21, Gin framework
- **Port**: 8081
- **Purpose**: User profile and account management
- **Endpoints**:
  - `GET /api/v1/users` - List users
  - `GET /api/v1/users/:id` - Get user details
  - `POST /api/v1/users` - Create user
  - `PUT /api/v1/users/:id` - Update user
  - `DELETE /api/v1/users/:id` - Delete user
- **Database**: PostgreSQL

### 3. Auth Service (Node.js + Express)
- **Technology**: Node.js 18, Express, JWT
- **Port**: 8082
- **Purpose**: Authentication and authorization
- **Endpoints**:
  - `POST /api/v1/auth/register` - Register new user
  - `POST /api/v1/auth/login` - Login user
  - `POST /api/v1/auth/refresh` - Refresh token
  - `POST /api/v1/auth/logout` - Logout user
  - `GET /api/v1/auth/verify` - Verify token
- **Database**: PostgreSQL, Redis (sessions)

### 4. Notification Service (Python + Flask)
- **Technology**: Python 3.11, Flask, Celery
- **Port**: 8083
- **Purpose**: Send notifications (email, SMS, push)
- **Endpoints**:
  - `POST /api/v1/notifications/send` - Send notification
  - `GET /api/v1/notifications/:id` - Get notification status
  - `GET /api/v1/notifications/user/:userId` - Get user notifications
- **Database**: PostgreSQL
- **Queue**: Redis (Celery)

### 5. Analytics Service (Java + Spring Boot)
- **Technology**: Java 17, Spring Boot 3
- **Port**: 8084
- **Purpose**: User analytics and reporting
- **Endpoints**:
  - `GET /api/v1/analytics/users` - User statistics
  - `GET /api/v1/analytics/events` - Event tracking
  - `POST /api/v1/analytics/track` - Track event
  - `GET /api/v1/analytics/reports` - Generate reports
- **Database**: PostgreSQL
- **Cache**: Redis

## Technology Stack

| Service | Language | Framework | Database | Port |
|---------|----------|-----------|----------|------|
| Frontend | TypeScript | React 18 | N/A | 3000 |
| User Service | Go 1.21 | Gin | PostgreSQL | 8081 |
| Auth Service | Node.js 18 | Express | PostgreSQL + Redis | 8082 |
| Notification Service | Python 3.11 | Flask | PostgreSQL + Redis | 8083 |
| Analytics Service | Java 17 | Spring Boot | PostgreSQL + Redis | 8084 |

## Directory Structure

```
02-services/
├── README.md (this file)
├── frontend/                    # React application
│   ├── src/
│   │   ├── components/         # React components
│   │   ├── pages/              # Page components
│   │   ├── services/           # API services
│   │   ├── utils/              # Utility functions
│   │   └── App.tsx             # Main app component
│   ├── public/                 # Static assets
│   ├── package.json
│   ├── tsconfig.json
│   ├── Dockerfile              # Production build
│   ├── Dockerfile.dev          # Development build
│   └── README.md
├── user-service/               # Go microservice
│   ├── cmd/
│   │   └── main.go            # Entry point
│   ├── internal/
│   │   ├── handlers/          # HTTP handlers
│   │   ├── models/            # Data models
│   │   ├── repository/        # Database layer
│   │   └── middleware/        # Middleware
│   ├── pkg/
│   │   └── database/          # DB utilities
│   ├── go.mod
│   ├── Dockerfile
│   └── README.md
├── auth-service/               # Node.js microservice
│   ├── src/
│   │   ├── controllers/       # Controllers
│   │   ├── models/            # Sequelize models
│   │   ├── middleware/        # Middleware
│   │   ├── routes/            # Express routes
│   │   ├── utils/             # Utilities
│   │   └── server.js          # Entry point
│   ├── package.json
│   ├── Dockerfile
│   └── README.md
├── notification-service/       # Python microservice
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py            # Flask app
│   │   ├── models.py          # SQLAlchemy models
│   │   ├── routes.py          # Flask routes
│   │   ├── tasks.py           # Celery tasks
│   │   └── utils.py           # Utilities
│   ├── requirements.txt
│   ├── Dockerfile
│   └── README.md
└── analytics-service/          # Java microservice
    ├── src/
    │   └── main/
    │       ├── java/
    │       │   └── com/devsecops/analytics/
    │       │       ├── AnalyticsApplication.java
    │       │       ├── controller/
    │       │       ├── service/
    │       │       ├── repository/
    │       │       └── model/
    │       └── resources/
    │           └── application.yml
    ├── pom.xml
    ├── Dockerfile
    └── README.md
```

## Development Workflow

### 1. Local Development with Docker Compose

Run all services locally:

```bash
# From this directory
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### 2. Individual Service Development

Each service can be run independently:

```bash
# Frontend
cd frontend
npm install
npm run dev

# User Service (Go)
cd user-service
go mod download
go run cmd/main.go

# Auth Service (Node.js)
cd auth-service
npm install
npm run dev

# Notification Service (Python)
cd notification-service
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app/main.py

# Analytics Service (Java)
cd analytics-service
./mvnw spring-boot:run
```

### 3. Building Docker Images

Each service has a Dockerfile:

```bash
# Build all images
docker-compose build

# Build individual service
cd <service-directory>
docker build -t <service-name>:latest .
```

## API Documentation

All services follow REST API conventions:

- **Base URL Pattern**: `/api/v1/<resource>`
- **Authentication**: JWT tokens (Bearer)
- **Content-Type**: `application/json`
- **Error Format**: Standard JSON error response

Example error response:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": ["Email is required", "Password must be at least 8 characters"]
  }
}
```

## Health Checks

All services expose health check endpoints:

- `GET /health` - Basic health check
- `GET /health/ready` - Readiness check (DB connection)
- `GET /health/live` - Liveness check

## Environment Variables

Common environment variables across services:

```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=devsecops
DB_USER=postgres
DB_PASSWORD=secret

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Service Configuration
PORT=8080
LOG_LEVEL=info
ENVIRONMENT=development

# Security
JWT_SECRET=your-secret-key
JWT_EXPIRATION=3600
```

## Testing

Each service includes tests:

```bash
# Frontend
cd frontend
npm test

# User Service
cd user-service
go test ./...

# Auth Service
cd auth-service
npm test

# Notification Service
cd notification-service
pytest

# Analytics Service
cd analytics-service
./mvnw test
```

## Security Features

All services implement:

1. **Input Validation**: Request validation middleware
2. **Authentication**: JWT-based authentication
3. **Authorization**: Role-based access control (RBAC)
4. **Rate Limiting**: API rate limiting
5. **CORS**: Configured CORS policies
6. **Security Headers**: Helmet.js, secure headers
7. **SQL Injection Prevention**: Parameterized queries
8. **XSS Prevention**: Input sanitization
9. **Secret Management**: Environment-based secrets

## Monitoring & Observability

Each service provides:

- **Metrics**: Prometheus metrics endpoint `/metrics`
- **Logging**: Structured JSON logging
- **Tracing**: OpenTelemetry integration
- **Health**: Kubernetes-compatible health checks

## Next Steps

1. **Implement Services**: Build each service following the structure above
2. **Configure Infrastructure**: Set up databases and caching (03-infrastructure)
3. **Deploy to Kubernetes**: Create K8s manifests (04-kubernetes)
4. **Set Up CI/CD**: Configure pipelines (05-cicd)

## Getting Started

To start building:

1. Choose a service directory (e.g., `cd user-service`)
2. Review the service-specific README.md
3. Follow the implementation guide
4. Test locally with Docker Compose
5. Push to feature branch for CI/CD pipeline

---

**Ready to build?** Start with any service or use the docker-compose for local development.
