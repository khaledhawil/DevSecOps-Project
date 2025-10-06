# Notification Service (Python + Flask)

A notification microservice built with Flask and Celery for sending emails, SMS, and push notifications.

## Overview

The Notification Service handles all notification operations including email delivery, SMS messaging, push notifications, and template management.

## Technology Stack

- **Language**: Python 3.11
- **Framework**: Flask
- **Task Queue**: Celery with Redis
- **Database**: PostgreSQL 15
- **ORM**: SQLAlchemy
- **Email**: SMTP (Nodemailer)
- **Logging**: Python logging

## Features

- Email notifications
- SMS notifications (Twilio integration ready)
- Push notifications (FCM ready)
- Notification templates
- User preferences management
- Asynchronous processing with Celery
- Retry logic for failed notifications
- Notification history
- Rate limiting
- Health checks

## API Endpoints

### Notifications
- `POST /api/v1/notifications/send` - Send notification
- `GET /api/v1/notifications/:id` - Get notification status
- `GET /api/v1/notifications/user/:userId` - Get user notifications
- `GET /api/v1/notifications` - List notifications (paginated)

### Templates
- `GET /api/v1/templates` - List templates
- `GET /api/v1/templates/:id` - Get template
- `POST /api/v1/templates` - Create template
- `PUT /api/v1/templates/:id` - Update template

### Preferences
- `GET /api/v1/preferences/:userId` - Get user preferences
- `PUT /api/v1/preferences/:userId` - Update preferences

### Health Checks
- `GET /health` - Basic health check
- `GET /health/ready` - Readiness check
- `GET /health/live` - Liveness check

## Environment Variables

```bash
# Service Configuration
PORT=8083
SERVICE_NAME=notification-service
FLASK_ENV=development
FLASK_DEBUG=1
LOG_LEVEL=DEBUG

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=devsecops
DB_USER=postgres
DB_PASSWORD=postgres123

# Redis/Celery Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis123
CELERY_BROKER_URL=redis://:redis123@localhost:6379/0
CELERY_RESULT_BACKEND=redis://:redis123@localhost:6379/0

# Email Configuration
SMTP_HOST=mailhog
SMTP_PORT=1025
SMTP_USER=
SMTP_PASSWORD=
SMTP_FROM=noreply@devsecops.local

# SMS Configuration (Twilio)
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_FROM_NUMBER=+1234567890

# Push Notifications (FCM)
FCM_SERVER_KEY=your_fcm_server_key
```

## Local Development

### Prerequisites
- Python 3.11 or later
- PostgreSQL 15
- Redis 7
- Docker (optional)

### Setup

1. **Create virtual environment**:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. **Install dependencies**:
```bash
pip install -r requirements.txt
```

3. **Set environment variables**:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. **Run the service**:
```bash
# Start Flask server
python app/main.py

# Start Celery worker (in another terminal)
celery -A app.tasks worker --loglevel=info
```

### Testing

```bash
pytest
pytest --cov=app tests/
```

## Docker

### Development

```bash
docker build -f Dockerfile.dev -t notification-service:dev .
docker run -p 8083:8083 notification-service:dev
```

### Production

```bash
docker build -t notification-service:latest .
docker run -p 8083:8083 notification-service:latest
```

## API Examples

### Send Email Notification

```bash
curl -X POST http://localhost:8083/api/v1/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "uuid-here",
    "type": "email",
    "channel": "email",
    "subject": "Welcome!",
    "message": "Welcome to our platform",
    "template": "welcome_email"
  }'
```

### Get Notification Status

```bash
curl http://localhost:8083/api/v1/notifications/NOTIFICATION_ID
```

### Get User Notifications

```bash
curl http://localhost:8083/api/v1/notifications/user/USER_ID?limit=10
```

## Notification Types

- **email**: Email notifications
- **sms**: SMS text messages
- **push**: Push notifications
- **in-app**: In-app notifications

## Security Features

- Input validation
- Rate limiting
- SQL injection prevention
- Template sanitization
- Secure credentials handling

## License

MIT License
