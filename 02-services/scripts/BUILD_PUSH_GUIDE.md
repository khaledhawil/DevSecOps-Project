# Docker Build and Push Guide

## Overview

Scripts for building all microservices and pushing them to DockerHub under the `khaledhawil` account.

## 📦 Available Scripts

### 1. `build-and-push.sh` - Main Build Script
Comprehensive script with full control over build and push process.

**Features:**
- Build all services or specific service
- Push to DockerHub (khaledhawil)
- Custom tagging support
- Dry-run mode
- No-cache builds
- Dual tagging (version + latest)

### 2. `quick-build.sh` - Quick Local Build
Fast local build without pushing to DockerHub.

**Use Case:** Testing changes locally

## 🚀 Quick Start

### Build and Push All Services

```bash
cd 02-services/scripts

# Build all and push with 'latest' tag
./build-and-push.sh

# Build all and push with version tag
./build-and-push.sh --tag v1.0.0

# Build all with version + latest tags
./build-and-push.sh --tag v1.0.0 --latest
```

### Build Locally Only (No Push)

```bash
# Build all services locally
./quick-build.sh

# Build with custom tag
./quick-build.sh v1.0.0

# Or using main script
./build-and-push.sh --no-push
```

### Build Specific Service

```bash
# Build only user-service
./build-and-push.sh --service user-service

# Build and push specific service with version
./build-and-push.sh --service auth-service --tag v1.0.0
```

## 📋 Services Built

The script builds all 5 microservices:

| Service | Technology | Port | Image Name |
|---------|-----------|------|------------|
| frontend | React + Nginx | 80 | khaledhawil/frontend |
| user-service | Go | 8081 | khaledhawil/user-service |
| auth-service | Node.js | 3001 | khaledhawil/auth-service |
| notification-service | Python | 5000 | khaledhawil/notification-service |
| analytics-service | Java/Spring Boot | 8081 | khaledhawil/analytics-service |

## 🎯 Usage Examples

### Development Workflow

```bash
# 1. Make code changes to a service
vim 02-services/user-service/src/...

# 2. Build and test locally
./scripts/quick-build.sh dev

# 3. Test with docker-compose
cd ..
docker-compose up user-service

# 4. Build and push to DockerHub when ready
cd scripts
./build-and-push.sh --tag v1.0.1 --latest
```

### Release Workflow

```bash
# Clean build with version tag and latest
./build-and-push.sh --tag v1.2.0 --latest --no-cache

# This will:
# - Build all services without cache
# - Tag as khaledhawil/service:v1.2.0
# - Also tag as khaledhawil/service:latest
# - Push both tags to DockerHub
```

### Testing Specific Service

```bash
# Build specific service locally
./build-and-push.sh --service frontend --no-push

# Build and push specific service
./build-and-push.sh --service auth-service --tag v1.0.0
```

### Dry Run (Preview)

```bash
# See what would be built without building
./build-and-push.sh --tag v1.0.0 --latest --dry-run

# Output shows what would happen:
# [DRY-RUN] Would build: khaledhawil/frontend:v1.0.0
# [DRY-RUN] Would also tag as: khaledhawil/frontend:latest
# [DRY-RUN] Would push to DockerHub
```

## 🔧 Command Options

### Main Script Options

```bash
./build-and-push.sh [options]
```

| Option | Description | Example |
|--------|-------------|---------|
| `--tag <tag>` | Specify image tag | `--tag v1.0.0` |
| `--service <name>` | Build specific service only | `--service user-service` |
| `--no-push` | Build only, don't push | `--no-push` |
| `--no-cache` | Build without cache | `--no-cache` |
| `--latest` | Also tag as 'latest' | `--latest` |
| `--dry-run` | Preview without building | `--dry-run` |
| `-h, --help` | Show help message | `-h` |

### Combined Options

```bash
# Version + latest, no cache
./build-and-push.sh --tag v1.0.0 --latest --no-cache

# Build specific service, no push
./build-and-push.sh --service frontend --no-push --no-cache

# Dry run with all options
./build-and-push.sh --tag v1.0.0 --latest --no-cache --dry-run
```

## 🔐 DockerHub Authentication

### First Time Setup

```bash
# Login to DockerHub
docker login

# Enter credentials:
# Username: khaledhawil
# Password: [your-token-or-password]
```

### Check Login Status

```bash
# Verify you're logged in
docker info | grep Username

# Should show: Username: khaledhawil
```

### Using Access Token (Recommended)

1. Go to DockerHub Settings → Security
2. Create new Access Token
3. Use token instead of password:
```bash
docker login -u khaledhawil
# Password: [paste-your-token]
```

## 📊 Build Process

### What Happens During Build

1. **Prerequisites Check**
   - Verifies Docker is installed
   - Checks Docker daemon is running
   - Validates DockerHub login (if pushing)

2. **Service Build**
   - Navigates to service directory
   - Executes multi-stage Docker build
   - Adds build labels (version, date, git info)
   - Tags with specified version

3. **Optional Latest Tag**
   - If `--latest` flag used
   - Tags image as 'latest' in addition to version

4. **Push to DockerHub**
   - Pushes version tag
   - Pushes latest tag (if applicable)
   - Shows progress and timing

5. **Summary Report**
   - Shows successful/failed builds
   - Displays total time
   - Lists available pull commands

### Build Output Example

```
========================================
Building Services
========================================

----------------------------------------
[INFO] Building user-service...
[INFO] Image: khaledhawil/user-service:v1.0.0
[INFO] Directory: /path/to/user-service
[INFO] Executing: docker build -t khaledhawil/user-service:v1.0.0 ...

[SUCCESS] Built user-service in 45s
[INFO] Tagging as latest...
[SUCCESS] Tagged as khaledhawil/user-service:latest

----------------------------------------
[INFO] Pushing user-service to DockerHub...
[INFO] Pushing: khaledhawil/user-service:v1.0.0
[SUCCESS] Pushed khaledhawil/user-service:v1.0.0 in 23s
[INFO] Pushing: khaledhawil/user-service:latest
[SUCCESS] Pushed khaledhawil/user-service:latest

========================================
Build Summary
========================================

Total Services: 5
Successful: 5
Failed: 0

Docker Hub: khaledhawil
Image Tag: v1.0.0
Also Tagged: latest
Push: Enabled

[SUCCESS] All services built successfully! ✅

[INFO] Images available on DockerHub:
  • docker pull khaledhawil/frontend:v1.0.0
  • docker pull khaledhawil/user-service:v1.0.0
  • docker pull khaledhawil/auth-service:v1.0.0
  • docker pull khaledhawil/notification-service:v1.0.0
  • docker pull khaledhawil/analytics-service:v1.0.0

Total Time: 312s
```

## ⏱️ Build Times

Typical build times (approximate):

| Service | Build Time | Size |
|---------|-----------|------|
| frontend | 60-90s | ~50MB |
| user-service | 45-60s | ~25MB |
| auth-service | 30-45s | ~180MB |
| notification-service | 40-60s | ~200MB |
| analytics-service | 90-120s | ~250MB |

**Total Time (all services):** 5-8 minutes

**With --no-cache:** 8-12 minutes

## 🐳 Using Built Images

### Pull from DockerHub

```bash
# Pull specific version
docker pull khaledhawil/user-service:v1.0.0

# Pull latest
docker pull khaledhawil/frontend:latest

# Pull all services
docker pull khaledhawil/frontend:latest
docker pull khaledhawil/user-service:latest
docker pull khaledhawil/auth-service:latest
docker pull khaledhawil/notification-service:latest
docker pull khaledhawil/analytics-service:latest
```

### Run Locally

```bash
# Run user-service
docker run -d -p 8081:8081 \
  -e DB_HOST=localhost \
  -e DB_PORT=5432 \
  khaledhawil/user-service:latest

# Run frontend
docker run -d -p 80:80 khaledhawil/frontend:latest
```

### Update docker-compose.yml

```yaml
services:
  user-service:
    image: khaledhawil/user-service:v1.0.0
    # ... other config
  
  auth-service:
    image: khaledhawil/auth-service:v1.0.0
    # ... other config
```

### Update Kubernetes

```yaml
# Update deployment image
spec:
  containers:
  - name: user-service
    image: khaledhawil/user-service:v1.0.0
```

## 🔍 Troubleshooting

### Build Fails

**Problem:** Build fails with error
```
[ERROR] Failed to build user-service
```

**Solutions:**
1. Check Dockerfile exists: `ls 02-services/user-service/Dockerfile`
2. Try clean build: `./build-and-push.sh --no-cache --service user-service`
3. Check Docker daemon: `docker info`
4. Check disk space: `df -h`

### Push Fails

**Problem:** Push fails with authentication error
```
[ERROR] Failed to push user-service
unauthorized: authentication required
```

**Solutions:**
1. Login to DockerHub: `docker login`
2. Verify username: `docker info | grep Username`
3. Use access token instead of password
4. Check network connection

### Out of Disk Space

**Problem:** No space left on device
```
Error: no space left on device
```

**Solutions:**
```bash
# Remove unused images
docker image prune -a

# Remove unused containers
docker container prune

# Remove unused volumes
docker volume prune

# Full cleanup
docker system prune -a --volumes
```

### Service Directory Not Found

**Problem:** Service directory not found
```
[ERROR] Service directory not found
```

**Solutions:**
1. Run from correct directory: `cd 02-services/scripts`
2. Check service name: `./build-and-push.sh --service user-service`
3. List available services: `ls -la ../`

### Docker Daemon Not Running

**Problem:** Docker daemon not running
```
[ERROR] Docker daemon is not running
```

**Solutions:**
```bash
# Start Docker (Ubuntu/Debian)
sudo systemctl start docker

# Start Docker (macOS)
open -a Docker

# Check status
docker info
```

## 🎯 Best Practices

### Version Tags

```bash
# Use semantic versioning
./build-and-push.sh --tag v1.0.0
./build-and-push.sh --tag v1.0.1
./build-and-push.sh --tag v1.1.0
./build-and-push.sh --tag v2.0.0

# Or use git tags
GIT_TAG=$(git describe --tags --abbrev=0)
./build-and-push.sh --tag ${GIT_TAG}

# Or use commit SHA
GIT_SHA=$(git rev-parse --short HEAD)
./build-and-push.sh --tag ${GIT_SHA}
```

### Development vs Production

```bash
# Development builds (fast iteration)
./quick-build.sh dev-$(git rev-parse --short HEAD)

# Staging builds
./build-and-push.sh --tag staging-v1.0.0

# Production builds (clean, with latest)
./build-and-push.sh --tag v1.0.0 --latest --no-cache
```

### CI/CD Integration

```bash
# In GitHub Actions / Jenkins
export IMAGE_TAG="v${VERSION}"
./build-and-push.sh --tag ${IMAGE_TAG} --latest --no-cache
```

### Multi-Architecture Builds

```bash
# For ARM64 support (Apple Silicon, ARM servers)
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 \
  -t khaledhawil/user-service:v1.0.0 --push .
```

## 📦 Image Labels

Each image includes metadata labels:

```bash
# View image labels
docker inspect khaledhawil/user-service:v1.0.0

# Labels include:
# - version: Image tag version
# - service: Service name
# - build.date: Build timestamp
# - build.commit: Git commit SHA
# - build.branch: Git branch name
```

Query labels:

```bash
# Get version
docker inspect --format='{{.Config.Labels.version}}' \
  khaledhawil/user-service:latest

# Get build date
docker inspect --format='{{.Config.Labels.build.date}}' \
  khaledhawil/user-service:latest
```

## 🔄 Update Workflow

### Complete Update Process

```bash
# 1. Make code changes
vim 02-services/user-service/src/...

# 2. Test locally
cd 02-services/scripts
./quick-build.sh
cd ..
docker-compose up user-service

# 3. Run tests
docker-compose exec user-service go test ./...

# 4. Build and push new version
cd scripts
./build-and-push.sh --tag v1.0.1 --latest

# 5. Update Kubernetes
kubectl set image deployment/user-service \
  user-service=khaledhawil/user-service:v1.0.1 \
  -n devsecops

# 6. Verify deployment
kubectl rollout status deployment/user-service -n devsecops
```

## 📚 Related Documentation

- Main Project README: `../../README.md`
- Service-specific READMEs: `../[service]/README.md`
- Kubernetes Deployment: `../../04-kubernetes/README.md`
- CI/CD Pipeline: `../../05-cicd/README.md`

## 🆘 Getting Help

```bash
# Show script help
./build-and-push.sh --help

# Check service logs
docker-compose logs -f [service-name]

# Inspect image
docker inspect khaledhawil/[service]:latest

# List all images
docker images khaledhawil/*
```

---

**DockerHub Repository:** https://hub.docker.com/u/khaledhawil

**Quick Commands:**
- Build all: `./build-and-push.sh`
- Build locally: `./quick-build.sh`
- Build one service: `./build-and-push.sh --service user-service`
- Release version: `./build-and-push.sh --tag v1.0.0 --latest`
