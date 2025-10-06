# Analytics Service (Java + Spring Boot)

An analytics microservice built with Spring Boot for tracking events, user statistics, and generating reports.

## Overview

The Analytics Service handles event tracking, user activity analysis, statistics generation, and reporting capabilities for the platform.

## Technology Stack

- **Language**: Java 17
- **Framework**: Spring Boot 3.2
- **Database**: PostgreSQL 15
- **Caching**: Redis 7
- **Build Tool**: Maven
- **Logging**: SLF4J + Logback

## Features

- ✅ Event tracking
- ✅ User activity monitoring
- ✅ Statistics generation
- ✅ Daily/weekly/monthly reports
- ✅ Real-time analytics
- ✅ Data aggregation
- ✅ REST API
- ✅ Health checks
- ✅ Metrics exposure

## API Endpoints

### Events
- `POST /api/v1/events` - Track new event
- `GET /api/v1/events/:id` - Get event details
- `GET /api/v1/events/user/:userId` - Get user events
- `GET /api/v1/events` - List events (paginated)

### Statistics
- `GET /api/v1/statistics/user/:userId` - Get user statistics
- `GET /api/v1/statistics/daily` - Get daily statistics
- `GET /api/v1/statistics/summary` - Get summary statistics

### Reports
- `GET /api/v1/reports/users` - User activity report
- `GET /api/v1/reports/events` - Event summary report
- `GET /api/v1/reports/export` - Export report (CSV/JSON)

### Health Checks
- `GET /actuator/health` - Basic health check
- `GET /actuator/health/readiness` - Readiness check
- `GET /actuator/health/liveness` - Liveness check
- `GET /actuator/metrics` - Prometheus metrics

## Environment Variables

```bash
# Service Configuration
SERVER_PORT=8084
SERVICE_NAME=analytics-service
SPRING_PROFILES_ACTIVE=development

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=devsecops
DB_USER=postgres
DB_PASSWORD=postgres123

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis123

# Logging
LOG_LEVEL=DEBUG
```

## Local Development

### Prerequisites
- Java 17 or later
- Maven 3.8+
- PostgreSQL 15
- Redis 7
- Docker (optional)

### Setup

1. **Build the project**:
```bash
mvn clean install
```

2. **Set environment variables**:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Run the service**:
```bash
mvn spring-boot:run
```

### Testing

```bash
mvn test
mvn test -Dtest=AnalyticsServiceTest
```

## Docker

### Development

```bash
docker build -f Dockerfile.dev -t analytics-service:dev .
docker run -p 8084:8084 analytics-service:dev
```

### Production

```bash
docker build -t analytics-service:latest .
docker run -p 8084:8084 analytics-service:latest
```

## API Examples

### Track Event

```bash
curl -X POST http://localhost:8084/api/v1/events \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "uuid-here",
    "event_type": "page_view",
    "event_name": "dashboard_viewed",
    "properties": {
      "page": "/dashboard",
      "referrer": "/login"
    }
  }'
```

### Get User Statistics

```bash
curl http://localhost:8084/api/v1/statistics/user/USER_ID
```

### Get Daily Statistics

```bash
curl "http://localhost:8084/api/v1/statistics/daily?date=2024-01-01"
```

## Event Types

- **page_view**: Page view tracking
- **button_click**: Button click tracking
- **form_submit**: Form submission tracking
- **api_call**: API call tracking
- **error**: Error tracking
- **custom**: Custom event tracking

## Security Features

- Input validation
- SQL injection prevention
- Rate limiting
- Request authentication
- Data sanitization

## License

MIT License
