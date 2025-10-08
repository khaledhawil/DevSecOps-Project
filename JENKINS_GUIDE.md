# Jenkins CI/CD Pipeline Guide

## Overview

Comprehensive Jenkins pipeline for the DevSecOps project with professional CI/CD stages including build, test, security scanning, and deployment.

## 📁 Jenkins Files

- **`Jenkinsfile`** - Main multibranch pipeline (detects changes automatically)
- **`05-cicd/jenkins/`** - Jenkins-specific configurations and pipelines

## 🚀 Pipeline Features

### ✅ Comprehensive Stages

1. **Initialize** - Setup build environment and display configuration
2. **Checkout** - Clone repository and get commit info
3. **Build & Test Services** - Parallel build of all microservices
4. **Security Scanning** - Trivy vulnerability scan + SonarQube analysis
5. **Push Images** - Push to DockerHub (khaledhawil)
6. **Deploy to Kubernetes** - Rolling deployment to K8s
7. **Smoke Tests** - Post-deployment validation
8. **Infrastructure Validation** - Terraform validation (if infrastructure changes)

### 🎯 Smart Change Detection

The pipeline automatically detects which service changed:
- Analyzes git diff to find modified files
- Builds only affected services (or all if requested)
- Reduces build time significantly

### 🔒 Security Features

- **Trivy Scanning** - Container vulnerability scanning
- **SonarQube Analysis** - Code quality and security analysis
- **Image Signing** - (Ready for Cosign integration)
- **Secrets Management** - Jenkins credentials for sensitive data

### 🐳 Docker Integration

- Multi-stage builds for optimized images
- Automatic tagging (commit SHA + branch name)
- DockerHub push with khaledhawil username
- Optional 'latest' tag for master branch

### ☸️ Kubernetes Deployment

- Automatic deployment to target environment
- Rolling updates with health checks
- Namespace based on branch (dev/staging/prod)
- Rollback capability

## 📊 Build Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ENVIRONMENT` | Choice | dev | Target environment (dev/staging/prod) |
| `SERVICE` | Choice | all | Service to build (auto-detected or manual) |
| `DEPLOY` | Boolean | true | Deploy to Kubernetes after build |
| `RUN_SECURITY_SCAN` | Boolean | true | Run security scans (Trivy, SonarQube) |
| `SKIP_TESTS` | Boolean | false | Skip running tests |
| `PUSH_LATEST` | Boolean | false | Also tag as 'latest' |

## 🛠️ Prerequisites

### 1. Jenkins Installation

```bash
# Using Helm
helm repo add jenkins https://charts.jenkins.io
helm repo update
helm install jenkins jenkins/jenkins \
  --namespace jenkins \
  --create-namespace \
  -f 05-cicd/jenkins/values.yaml
```

Or use the setup script:
```bash
cd 09-scripts
./08-setup-jenkins.sh
```

### 2. Required Jenkins Plugins

- Kubernetes Plugin
- Docker Plugin
- Pipeline Plugin
- Git Plugin
- Blue Ocean
- Credentials Binding
- AnsiColor
- Timestamper

### 3. Configure Credentials

Add these credentials in Jenkins:

#### DockerHub Credentials
- **ID**: `dockerhub-credentials`
- **Type**: Username with password
- **Username**: `khaledhawil`
- **Password**: [Your DockerHub token]

#### SonarQube Token
- **ID**: `sonarqube-token`
- **Type**: Secret text
- **Secret**: [Your SonarQube token]

#### Kubernetes Config (if not using in-cluster)
- **ID**: `kubeconfig`
- **Type**: Secret file
- **File**: Your kubeconfig file

#### Slack/Email (Optional)
- **ID**: `slack-token`
- **Type**: Secret text
- **Secret**: [Your Slack webhook URL]

### 4. Configure Jenkins Service Account

```bash
# Create service account with necessary permissions
kubectl create serviceaccount jenkins -n jenkins
kubectl create clusterrolebinding jenkins-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=jenkins:jenkins
```

## 🚦 Usage

### Method 1: GitHub Webhook (Automatic)

1. Configure webhook in GitHub:
   ```
   URL: https://your-jenkins.com/github-webhook/
   Content type: application/json
   Events: Push, Pull Request
   ```

2. Push to repository:
   ```bash
   git add .
   git commit -m "Update user-service"
   git push
   ```

3. Jenkins automatically triggers build

### Method 2: Manual Trigger

1. Access Jenkins UI:
   ```bash
   kubectl port-forward svc/jenkins -n jenkins 8080:8080
   ```

2. Open http://localhost:8080

3. Navigate to job and click "Build with Parameters"

4. Select options and click "Build"

### Method 3: Jenkins CLI

```bash
# Download CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Trigger build
java -jar jenkins-cli.jar -s http://localhost:8080 \
  -auth admin:password \
  build DevSecOps-Pipeline \
  -p ENVIRONMENT=dev \
  -p SERVICE=user-service \
  -p DEPLOY=true
```

### Method 4: REST API

```bash
# Get crumb for CSRF protection
CRUMB=$(curl -s 'http://admin:password@localhost:8080/crumbIssuer/api/json' | jq -r '.crumb')

# Trigger build
curl -X POST \
  -H "Jenkins-Crumb:$CRUMB" \
  "http://admin:password@localhost:8080/job/DevSecOps-Pipeline/buildWithParameters?ENVIRONMENT=dev&SERVICE=user-service"
```

## 📝 Pipeline Configuration

### Environment Variables

The pipeline uses these environment variables:

```groovy
DOCKERHUB_USERNAME = 'khaledhawil'         // DockerHub account
IMAGE_TAG = "${env.GIT_COMMIT.take(8)}"    // Short commit SHA
BUILD_DATE = "2025-10-08T12:00:00Z"        // ISO 8601 timestamp
KUBE_NAMESPACE = "devsecops-dev"           // K8s namespace based on branch
SONAR_HOST_URL = 'http://sonarqube:9000'   // SonarQube server
```

### Branch to Namespace Mapping

| Branch | Namespace |
|--------|-----------|
| master | devsecops-prod |
| staging | devsecops-staging |
| develop | devsecops-dev |
| feature/* | devsecops-dev |

### Kubernetes Pod Template

The pipeline uses a Kubernetes pod with these containers:

- **docker** - Docker-in-Docker for building images
- **kubectl** - Kubernetes CLI for deployments
- **trivy** - Security vulnerability scanner
- **sonar** - SonarQube code analysis
- **go** - Go language builds
- **node** - Node.js builds
- **python** - Python builds
- **maven** - Java/Maven builds

## 🔄 Pipeline Workflow

### 1. Code Push
```
Developer → Git Push → GitHub → Webhook → Jenkins
```

### 2. Build Process
```
Initialize → Checkout → Build (parallel) → Test → Docker Build
```

### 3. Security
```
Trivy Scan → SonarQube → Quality Gates → Approve/Reject
```

### 4. Deployment
```
Push to DockerHub → kubectl set image → Rollout → Verify
```

### 5. Notification
```
Build Status → Slack/Email → Team Notification
```

## 📈 Build Stages Detail

### Stage 1: Initialize
- Display build configuration
- Set environment variables
- Determine which service changed
- Print build information banner

### Stage 2: Checkout
- Clone repository
- Get commit SHA and message
- Detect changed files
- Set service to build

### Stage 3: Build & Test Services (Parallel)

#### Frontend (React + TypeScript)
```bash
npm ci
npm run build
npm run test
docker build -t khaledhawil/frontend:$TAG .
```

#### User Service (Go)
```bash
go mod download
go build -o user-service ./cmd/main.go
go test -v -race -coverprofile=coverage.out ./...
docker build -t khaledhawil/user-service:$TAG .
```

#### Auth Service (Node.js)
```bash
npm ci
npm run test
docker build -t khaledhawil/auth-service:$TAG .
```

#### Notification Service (Python)
```bash
pip install -r requirements.txt
pytest --cov=app
docker build -t khaledhawil/notification-service:$TAG .
```

#### Analytics Service (Java/Spring Boot)
```bash
mvn clean package -DskipTests
mvn test
docker build -t khaledhawil/analytics-service:$TAG .
```

### Stage 4: Security Scanning

#### Trivy Scan
```bash
trivy image --severity HIGH,CRITICAL khaledhawil/service:$TAG
```

#### SonarQube Analysis
```bash
sonar-scanner \
  -Dsonar.projectKey=service-name \
  -Dsonar.host.url=$SONAR_HOST \
  -Dsonar.login=$SONAR_TOKEN
```

### Stage 5: Push Images
```bash
docker login -u khaledhawil
docker push khaledhawil/service:$TAG
docker push khaledhawil/service:$BRANCH
docker push khaledhawil/service:latest  # if PUSH_LATEST=true
```

### Stage 6: Deploy to Kubernetes
```bash
kubectl set image deployment/service \
  service=khaledhawil/service:$TAG \
  -n $NAMESPACE

kubectl rollout status deployment/service -n $NAMESPACE
```

### Stage 7: Smoke Tests
```bash
kubectl get pods -n $NAMESPACE
# Check health endpoints
# Verify deployment
```

### Stage 8: Infrastructure Validation (if applicable)
```bash
cd 03-infrastructure/terraform
terraform init -backend=false
terraform validate
terraform fmt -check
```

## 🎨 Pipeline Visualization

```
┌─────────────────────────────────────────────────────────────┐
│                     Initialize                              │
│  • Print configuration                                      │
│  • Detect changed service                                   │
└────────────────────────┬────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                     Checkout                                │
│  • Clone repository                                         │
│  • Get commit info                                          │
└────────────────────────┬────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Build & Test (Parallel)                        │
├──────────┬──────────┬──────────┬──────────┬─────────────────┤
│ Frontend │ User     │ Auth     │ Notif.   │ Analytics       │
│ • Build  │ • Build  │ • Build  │ • Build  │ • Build         │
│ • Test   │ • Test   │ • Test   │ • Test   │ • Test          │
│ • Docker │ • Docker │ • Docker │ • Docker │ • Docker        │
└──────────┴──────────┴──────────┴──────────┴─────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Security Scanning (Parallel)                   │
├───────────────────────────┬─────────────────────────────────┤
│ Trivy Scan                │ SonarQube Analysis              │
│ • Vulnerability check     │ • Code quality                  │
│ • HIGH & CRITICAL only    │ • Security hotspots             │
└───────────────────────────┴─────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  Push to DockerHub                          │
│  • Login to khaledhawil account                             │
│  • Push with commit SHA tag                                 │
│  • Push with branch tag                                     │
│  • Push 'latest' tag (if enabled)                           │
└────────────────────────┬────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Deploy to Kubernetes                           │
│  • Update deployment image                                  │
│  • Rolling update                                           │
│  • Wait for rollout                                         │
└────────────────────────┬────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  Smoke Tests                                │
│  • Check pod status                                         │
│  • Health check endpoints                                   │
│  • Verify deployment                                        │
└────────────────────────┬────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Notifications & Cleanup                        │
│  • Send success/failure notification                        │
│  • Clean up Docker images                                   │
│  • Archive artifacts                                        │
└─────────────────────────────────────────────────────────────┘
```

## 📊 Build Times

Approximate build times for each stage:

| Stage | Time | Parallel | Notes |
|-------|------|----------|-------|
| Initialize | 5s | No | Quick setup |
| Checkout | 10s | No | Depends on repo size |
| Build Frontend | 60-90s | Yes | npm build |
| Build User Service | 45-60s | Yes | Go build |
| Build Auth Service | 30-45s | Yes | npm install |
| Build Notification | 40-60s | Yes | pip install |
| Build Analytics | 90-120s | Yes | Maven build |
| Security Scan | 30-60s | Yes | Trivy + SonarQube |
| Push Images | 60-120s | No | Network dependent |
| Deploy K8s | 30-60s | No | Rollout time |
| Smoke Tests | 15-30s | No | Health checks |

**Total Time:**
- Single service: 5-8 minutes
- All services: 8-12 minutes (with parallelization)

## 🔍 Monitoring & Logs

### View Build Logs

```bash
# Via UI
http://jenkins-url/job/DevSecOps-Pipeline/lastBuild/console

# Via kubectl
kubectl logs -f -l app.kubernetes.io/component=jenkins-controller -n jenkins

# Via API
curl http://admin:password@jenkins-url/job/DevSecOps-Pipeline/lastBuild/consoleText
```

### Build Status

```bash
# Get build status
curl http://admin:password@jenkins-url/job/DevSecOps-Pipeline/lastBuild/api/json | jq '.result'

# Get build number
curl http://admin:password@jenkins-url/job/DevSecOps-Pipeline/lastBuild/api/json | jq '.number'
```

### Blue Ocean View

Access: http://jenkins-url/blue/organizations/jenkins/DevSecOps-Pipeline/activity

## 🔧 Troubleshooting

### Build Fails: Docker Permission Denied

**Problem:**
```
permission denied while trying to connect to the Docker daemon socket
```

**Solution:**
Ensure Jenkins pod has privileged security context:
```yaml
securityContext:
  privileged: true
```

### Build Fails: Kubernetes Deployment

**Problem:**
```
Error from server (Forbidden): deployments.apps "service" is forbidden
```

**Solution:**
Check service account permissions:
```bash
kubectl describe clusterrolebinding jenkins-admin
```

### Build Fails: npm ci Error

**Problem:**
```
npm ci can only install with an existing package-lock.json
```

**Solution:**
Generate package-lock.json:
```bash
cd 02-services/auth-service
npm install --package-lock-only
git add package-lock.json
git commit -m "Add package-lock.json"
git push
```

### Build Fails: Trivy Scan

**Problem:**
```
Trivy scan failed with HIGH/CRITICAL vulnerabilities
```

**Solution:**
1. Review vulnerabilities in logs
2. Update base images
3. Update dependencies
4. Or set `exit-code 0` to warn only

### Slow Builds

**Problem:** Builds taking too long

**Solutions:**
1. Enable Docker layer caching
2. Use smaller base images
3. Optimize Dockerfile multi-stage builds
4. Run tests in parallel
5. Skip tests for feature branches: `SKIP_TESTS=true`

## 🎯 Best Practices

### 1. Use Feature Branches

```bash
git checkout -b feature/new-feature
# Make changes
git commit -m "Add new feature"
git push origin feature/new-feature
# Jenkins builds automatically
```

### 2. Tag Releases

```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
# Trigger release pipeline
```

### 3. Use Pull Requests

- Create PR for code review
- Jenkins runs build on PR
- Merge only if build passes
- Automatic deployment after merge

### 4. Environment-Specific Builds

```bash
# Development
git push origin develop
# → Deploys to devsecops-dev

# Staging
git push origin staging
# → Deploys to devsecops-staging

# Production
git push origin master
# → Deploys to devsecops-prod
```

### 5. Rollback Strategy

```bash
# Rollback deployment
kubectl rollout undo deployment/service -n namespace

# Rollback to specific revision
kubectl rollout undo deployment/service --to-revision=2 -n namespace
```

## 📚 Integration Examples

### Slack Notifications

Uncomment in Jenkinsfile post section:
```groovy
post {
    success {
        slackSend(
            channel: '#devops-alerts',
            color: 'good',
            message: "✅ Build SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        )
    }
}
```

### Email Notifications

```groovy
post {
    failure {
        emailext(
            subject: "Build Failed: ${env.JOB_NAME}",
            body: "Build #${env.BUILD_NUMBER} failed. Check: ${env.BUILD_URL}",
            to: 'team@example.com'
        )
    }
}
```

### Jira Integration

```groovy
stage('Update Jira') {
    steps {
        jiraComment(
            issueKey: 'PROJ-123',
            comment: "Build completed: ${env.BUILD_URL}"
        )
    }
}
```

## 🔗 Related Documentation

- [Main README](README.md)
- [CI/CD README](05-cicd/README.md)
- [Jenkins README](05-cicd/jenkins/README.md)
- [Build & Push Guide](02-services/scripts/BUILD_PUSH_GUIDE.md)
- [Kubernetes Deployment](04-kubernetes/README.md)
- [Infrastructure Setup](03-infrastructure/README.md)

## 🆘 Support

### Jenkins Documentation
- Official Docs: https://www.jenkins.io/doc/
- Pipeline Syntax: https://www.jenkins.io/doc/book/pipeline/syntax/
- Kubernetes Plugin: https://plugins.jenkins.io/kubernetes/

### Community
- Jenkins IRC: #jenkins on Freenode
- Stack Overflow: https://stackoverflow.com/questions/tagged/jenkins

### Project Support
- GitHub Issues: https://github.com/khaledhawil/DevSecOps-Project/issues
- Project Wiki: https://github.com/khaledhawil/DevSecOps-Project/wiki

---

**Quick Start:**
1. Push code to repository
2. Jenkins automatically builds
3. Images pushed to DockerHub (khaledhawil)
4. Deployed to Kubernetes
5. Team notified of results

**Jenkins Pipeline Ready!** 🚀
