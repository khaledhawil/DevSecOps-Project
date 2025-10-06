# Auth Service (Node.js + Express)

A RESTful authentication microservice built with Node.js, Express, and JWT.

## Overview

The Auth Service handles all authentication and authorization operations including user registration, login, token management, and password reset.

## Technology Stack

- **Language**: Node.js 18
- **Framework**: Express.js
- **Database**: PostgreSQL 15 + Redis
- **ORM**: Sequelize
- **Authentication**: JWT (Access + Refresh tokens)
- **Password Hashing**: bcrypt
- **Validation**: Joi
- **Logging**: Winston

## Features

- ✅ User registration with email verification
- ✅ User login with JWT tokens
- ✅ Access and refresh token management
- ✅ Password reset flow
- ✅ Email verification
- ✅ Rate limiting
- ✅ Login audit logging
- ✅ Session management with Redis
- ✅ Password strength validation
- ✅ CORS configuration
- ✅ Security headers (Helmet)

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login user
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/logout` - Logout user
- `GET /api/v1/auth/verify` - Verify JWT token

### Password Management
- `POST /api/v1/auth/forgot-password` - Request password reset
- `POST /api/v1/auth/reset-password` - Reset password with token

### Email Verification
- `POST /api/v1/auth/verify-email` - Verify email with token
- `POST /api/v1/auth/resend-verification` - Resend verification email

### Health Checks
- `GET /health` - Basic health check
- `GET /health/ready` - Readiness check
- `GET /health/live` - Liveness check

## Environment Variables

```bash
# Service Configuration
PORT=8082
SERVICE_NAME=auth-service
NODE_ENV=development
LOG_LEVEL=debug

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=devsecops
DB_USER=postgres
DB_PASSWORD=postgres123
DB_SSL=false

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis123

# JWT Configuration
JWT_SECRET=your-secret-key-change-in-production
JWT_ACCESS_EXPIRATION=900
JWT_REFRESH_EXPIRATION=86400

# Security
BCRYPT_ROUNDS=10
RATE_LIMIT_WINDOW=900000
RATE_LIMIT_MAX=100

# Email Configuration
SMTP_HOST=mailhog
SMTP_PORT=1025
SMTP_USER=
SMTP_PASSWORD=
SMTP_FROM=noreply@devsecops.local
```

## Local Development

### Prerequisites
- Node.js 18 or later
- PostgreSQL 15
- Redis 7
- Docker (optional)

### Setup

1. **Install dependencies**:
```bash
npm install
```

2. **Set environment variables**:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Run the service**:
```bash
# Development with hot reload
npm run dev

# Production
npm start
```

### Testing

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:coverage

# Run tests in watch mode
npm run test:watch
```

## Docker

### Development

```bash
docker build -f Dockerfile.dev -t auth-service:dev .
docker run -p 8082:8082 auth-service:dev
```

### Production

```bash
docker build -t auth-service:latest .
docker run -p 8082:8082 auth-service:latest
```

## API Examples

### Register

```bash
curl -X POST http://localhost:8082/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "username": "johndoe",
    "password": "SecurePassword123!",
    "first_name": "John",
    "last_name": "Doe"
  }'
```

### Login

```bash
curl -X POST http://localhost:8082/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePassword123!"
  }'
```

### Refresh Token

```bash
curl -X POST http://localhost:8082/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "YOUR_REFRESH_TOKEN"
  }'
```

## Security Features

- **Password Hashing**: bcrypt with configurable rounds
- **JWT Tokens**: Separate access and refresh tokens
- **Token Rotation**: Refresh token rotation on use
- **Rate Limiting**: IP-based rate limiting
- **Session Management**: Redis-based session storage
- **Audit Logging**: All login attempts logged
- **Security Headers**: Helmet.js middleware
- **Input Validation**: Joi schema validation
- **SQL Injection Prevention**: Sequelize parameterized queries

## License

MIT License
