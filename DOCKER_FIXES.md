# Docker Build Fixes - Quick Reference

## Issues Fixed

### 1. User/Group ID Conflicts ✅

**Problem:**
```
ERROR: addgroup: gid '1000' in use
ERROR: useradd: UID 1000 is not unique
```

**Root Cause:**
- UID/GID 1000 often used by first regular user on Linux
- Docker may inherit host user IDs
- Causes conflicts during image build

**Solution:**
Changed all services from UID/GID 1000 → 10001

**Files Updated:**
- `02-services/frontend/Dockerfile`
- `02-services/user-service/Dockerfile`
- `02-services/auth-service/Dockerfile`
- `02-services/notification-service/Dockerfile`
- `02-services/analytics-service/Dockerfile`

**Changes:**
```dockerfile
# OLD (caused conflicts)
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

# NEW (no conflicts)
RUN addgroup -g 10001 appuser && \
    adduser -D -u 10001 -G appuser appuser
```

### 2. Invalid Python Package ✅

**Problem:**
```
ERROR: Could not find a version that satisfies the requirement python-smtplib==0.1.1
ERROR: No matching distribution found for python-smtplib==0.1.1
```

**Root Cause:**
- Package `python-smtplib` doesn't exist in PyPI
- Python has built-in `smtplib` module
- No external package needed

**Solution:**
Removed `python-smtplib==0.1.1` from requirements.txt

**File Updated:**
- `02-services/notification-service/requirements.txt`

**Changes:**
```python
# REMOVED (doesn't exist)
python-smtplib==0.1.1

# NOT NEEDED - Python has built-in smtplib
# Just use: import smtplib
```

## Using SMTP in Python

SMTP is built into Python - no package installation needed!

```python
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def send_email(to, subject, body):
    """Send email using Python's built-in smtplib"""
    msg = MIMEMultipart()
    msg['From'] = 'noreply@example.com'
    msg['To'] = to
    msg['Subject'] = subject
    msg.attach(MIMEText(body, 'plain'))
    
    # Using Gmail SMTP
    with smtplib.SMTP('smtp.gmail.com', 587) as server:
        server.starttls()
        server.login('your-email@gmail.com', 'your-app-password')
        server.send_message(msg)
        
    print(f"Email sent to {to}")

# Usage
send_email(
    to='user@example.com',
    subject='Notification from DevSecOps',
    body='Your notification message here'
)
```

## Build Services Now

All issues are fixed! You can now build successfully:

```bash
# Build all services
cd 02-services/scripts
./build-and-push.sh

# Build specific service
./build-and-push.sh --service auth-service
./build-and-push.sh --service notification-service

# Build locally (no push)
./quick-build.sh

# Build with custom tag
./build-and-push.sh --tag v1.0.0
```

## Service Status

| Service | UID/GID | Status | Notes |
|---------|---------|--------|-------|
| frontend | 10001 | ✅ Fixed | npm install instead of npm ci |
| user-service | 10001 | ✅ Fixed | Go build works |
| auth-service | 10001 | ✅ Fixed | npm install + UID fix |
| notification-service | 10001 | ✅ Fixed | Removed invalid package + UID fix |
| analytics-service | 10001 | ✅ Fixed | Maven build works |

## Why UID/GID 10001?

### Benefits:
- ✅ Avoids conflicts with host system users (usually 1000-9999)
- ✅ Non-root user (security best practice)
- ✅ Isolated from system service users (usually < 1000)
- ✅ Consistent across all microservices
- ✅ No privilege escalation risks
- ✅ Works across different Linux distributions

### Range Guidelines:
- 0: root user
- 1-999: System service users
- 1000-9999: Regular user accounts
- **10000+: Application users (our choice)**

## Verification

After building, verify user inside container:

```bash
# Build image
docker build -t test-image .

# Check user
docker run --rm test-image id

# Expected output:
uid=10001(appuser) gid=10001(appuser) groups=10001(appuser)
```

## Common Build Options

```bash
# Build all services
./build-and-push.sh

# Build without pushing
./build-and-push.sh --no-push

# Build with version tag
./build-and-push.sh --tag v1.0.0

# Build without cache (clean build)
./build-and-push.sh --no-cache

# Build and tag as latest too
./build-and-push.sh --tag v1.0.0 --latest

# Dry run (preview)
./build-and-push.sh --dry-run

# Build specific service
./build-and-push.sh --service notification-service
```

## Troubleshooting

### If build still fails:

1. **Clear Docker cache:**
   ```bash
   docker system prune -a
   ```

2. **Check Docker space:**
   ```bash
   df -h
   docker system df
   ```

3. **Build with no cache:**
   ```bash
   ./build-and-push.sh --no-cache
   ```

4. **Check Dockerfile syntax:**
   ```bash
   docker build --check 02-services/auth-service/
   ```

5. **View build details:**
   ```bash
   docker build --progress=plain -t test 02-services/auth-service/
   ```

## Additional Python Packages

If you need email templates or advanced features:

```python
# requirements.txt
Flask==3.0.0
Flask-CORS==4.0.0
Flask-Mail==0.9.1        # Flask email extension (optional)
jinja2==3.1.2            # For email templates
```

Example with Flask-Mail:

```python
from flask_mail import Mail, Message

app = Flask(__name__)
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = 'your-email@gmail.com'
app.config['MAIL_PASSWORD'] = 'your-app-password'

mail = Mail(app)

def send_notification(recipient, subject, body):
    msg = Message(subject, 
                  sender='noreply@example.com',
                  recipients=[recipient])
    msg.body = body
    mail.send(msg)
```

## Summary

✅ **5 Dockerfiles updated** - UID/GID changed to 10001  
✅ **1 requirements.txt fixed** - Removed invalid package  
✅ **Ready to build** - All conflicts resolved  
✅ **Security improved** - Non-root users with safe UIDs  
✅ **No external dependencies** - Using Python built-in SMTP  

**Next step:** Run `./build-and-push.sh` and watch it succeed! 🚀

---

**Last Updated:** October 8, 2025  
**Docker Username:** khaledhawil  
**UID/GID:** 10001 (all services)
