# Jenkins CI/CD Setup Guide

## 📋 Overview

This guide covers the complete Jenkins CI/CD setup for the DevSecOps project with professional pipeline stages.

## 📁 Created Jenkinsfiles

### Root Jenkinsfile
**Location:** `/Jenkinsfile`
- Main multibranch pipeline
- Auto-detects service changes
- Builds all services or specific service
- Comprehensive security scanning
- Parallel execution for speed

### Service-Specific Jenkinsfiles
**Location:** `/05-cicd/jenkins/`

1. **Jenkinsfile.frontend** - React application
2. **Jenkinsfile.user-service** - Go microservice
3. **Jenkinsfile.auth-service** - Node.js microservice
4. **Jenkinsfile.notification-service** - Python microservice
5. **Jenkinsfile.analytics-service** - Java/Spring Boot microservice

## 🎯 Pipeline Stages

Each Jenkinsfile includes these professional stages:

### 1. **Initialize / Checkout**
- Clone repository
- Get Git commit info
- Set environment variables

### 2. **Build**
- Install dependencies
- Compile code
- Create artifacts

### 3. **Test**
- Unit tests
- Integration tests
- Code coverage reporting

### 4. **Build Docker Image**
- Multi-stage Docker build
- Tagging with commit SHA
- Environment-specific tags

### 5. **Security Scanning**
- Trivy vulnerability scanning
- SonarQube code analysis (optional)
- SAST/DAST checks

### 6. **Push to DockerHub**
- Login to DockerHub (khaledhawil)
- Push versioned images
- Push environment tags
- Optional: Push latest tag

### 7. **Deploy to Kubernetes**
- Update deployment image
- Monitor rollout status
- Health checks

### 8. **Post-Actions**
- Cleanup
- Notifications
- Reporting

## 🚀 Setup Instructions

### 1. Jenkins Installation

If not already installed, use the setup script:

```bash
cd 09-scripts
./08-setup-jenkins.sh
```

### 2. Create DockerHub Credentials

In Jenkins:
1. Go to **Manage Jenkins** → **Credentials**
2. Click **Add Credentials**
3. Create credential:
   - **ID:** `dockerhub-credentials`
   - **Username:** `khaledhawil`
   - **Password:** [Your DockerHub password or token]
   - **Description:** DockerHub credentials for khaledhawil

### 3. Create Pipeline Jobs

#### Option A: Multibranch Pipeline (Recommended)

1. **Create New Item**
   - Name: `devsecops-multibranch`
   - Type: Multibranch Pipeline

2. **Branch Sources**
   - Add source: Git
   - Project Repository: `https://github.com/khaledhawil/DevSecOps-Project`
   - Credentials: Your GitHub credentials
   - Behaviors: Discover branches

3. **Build Configuration**
   - Mode: by Jenkinsfile
   - Script Path: `Jenkinsfile`

4. **Scan Multibranch Pipeline Triggers**
   - ☑ Periodically if not otherwise run
   - Interval: 5 minutes

5. **Save** and let Jenkins scan branches

#### Option B: Individual Pipeline Jobs

For each service, create a pipeline job:

1. **Frontend Pipeline**
   - Name: `frontend-pipeline`
   - Type: Pipeline
   - Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your repo
   - Script Path: `05-cicd/jenkins/Jenkinsfile.frontend`

2. **User Service Pipeline**
   - Name: `user-service-pipeline`
   - Script Path: `05-cicd/jenkins/Jenkinsfile.user-service`

3. **Auth Service Pipeline**
   - Name: `auth-service-pipeline`
   - Script Path: `05-cicd/jenkins/Jenkinsfile.auth-service`

4. **Notification Service Pipeline**
   - Name: `notification-service-pipeline`
   - Script Path: `05-cicd/jenkins/Jenkinsfile.notification-service`

5. **Analytics Service Pipeline**
   - Name: `analytics-service-pipeline`
   - Script Path: `05-cicd/jenkins/Jenkinsfile.analytics-service`

### 4. Configure Kubernetes Access

Jenkins needs access to your Kubernetes cluster:

```bash
# Create kubeconfig secret
kubectl create secret generic kubeconfig \
  --from-file=config=$HOME/.kube/config \
  -n jenkins

# Or use ServiceAccount (recommended)
kubectl create serviceaccount jenkins -n jenkins
kubectl create clusterrolebinding jenkins \
  --clusterrole=cluster-admin \
  --serviceaccount=jenkins:jenkins
```

## 📊 Pipeline Parameters

Each pipeline accepts these parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ENVIRONMENT` | Choice | dev | Target environment (dev/staging/prod) |
| `DEPLOY` | Boolean | true | Deploy to Kubernetes after build |
| `SKIP_TESTS` | Boolean | false | Skip running tests |
| `PUSH_LATEST` | Boolean | false | Also tag and push as 'latest' |

### Main Jenkinsfile Additional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `SERVICE` | Choice | all | Service to build (all/frontend/user-service/etc) |
| `RUN_SECURITY_SCAN` | Boolean | true | Run Trivy and SonarQube scans |

## 🎨 Usage Examples

### Build via Jenkins UI

1. Open Jenkins
2. Select job (e.g., `frontend-pipeline`)
3. Click **Build with Parameters**
4. Set parameters:
   - Environment: `dev`
   - Deploy: ☑
   - Skip Tests: ☐
   - Push Latest: ☐
5. Click **Build**

### Build via Jenkins API

```bash
# Get Jenkins crumb for CSRF protection
CRUMB=$(curl -s 'http://admin:password@jenkins:8080/crumbIssuer/api/json' | jq -r '.crumb')

# Trigger build
curl -X POST \
  -H "Jenkins-Crumb:$CRUMB" \
  "http://admin:password@jenkins:8080/job/frontend-pipeline/buildWithParameters?ENVIRONMENT=dev&DEPLOY=true"
```

### Build via Jenkins CLI

```bash
# Download CLI
wget http://jenkins:8080/jnlpJars/jenkins-cli.jar

# Trigger build
java -jar jenkins-cli.jar -s http://jenkins:8080 \
  -auth admin:password \
  build frontend-pipeline -p ENVIRONMENT=dev -p DEPLOY=true
```

## 🔧 Pipeline Features

### 1. Auto Service Detection

The main Jenkinsfile auto-detects which service changed:

```groovy
def getChangedService() {
    def changes = sh(script: 'git diff --name-only HEAD~1 HEAD', returnStdout: true)
    if (changes.contains('02-services/frontend/')) return 'frontend'
    // ... etc
}
```

### 2. Parallel Execution

Multiple services build in parallel:

```groovy
stage('Build & Test Services') {
    parallel {
        stage('Frontend') { ... }
        stage('User Service') { ... }
        stage('Auth Service') { ... }
    }
}
```

### 3. Kubernetes Pod Templates

Each pipeline uses Kubernetes agents:

```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker     # Docker builds
  - name: kubectl    # Kubernetes deployments
  - name: trivy      # Security scanning
  - name: node/go/python/maven  # Language-specific
```

### 4. Multi-Environment Support

Automatic namespace selection:

```groovy
KUBE_NAMESPACE = "${params.ENVIRONMENT == 'prod' ? 'devsecops-prod' : 
                    params.ENVIRONMENT == 'staging' ? 'devsecops-staging' : 
                    'devsecops-dev'}"
```

### 5. Image Tagging Strategy

Multiple tags for flexibility:

- **Commit SHA:** `khaledhawil/frontend:abc123de`
- **Environment:** `khaledhawil/frontend:dev`
- **Latest** (optional): `khaledhawil/frontend:latest`

## 📋 Build Output Example

```
╔═══════════════════════════════════════════════════════════════╗
║           DevSecOps CI/CD Pipeline                           ║
╚═══════════════════════════════════════════════════════════════╝

Build Information:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Branch:          master
Commit:          abc123de...
Image Tag:       abc123de
Environment:     dev
Service:         frontend
Deploy:          true
Security Scan:   true
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Checkout] ✓ Code checked out
[Build] 📦 Building frontend...
[Test] 🧪 Running tests...
[Docker Build] 🐳 Building image...
[Security Scan] 🔒 Scanning with Trivy...
[Push] 📤 Pushing to DockerHub...
[Deploy] 🚀 Deploying to Kubernetes...

╔═══════════════════════════════════════════════════════════════╗
║           Build Complete                                      ║
╚═══════════════════════════════════════════════════════════════╝

Status:          SUCCESS
Duration:        5m 23s
Image:           khaledhawil/frontend:abc123de
Environment:     dev
```

## 🔐 Security Features

### 1. Trivy Vulnerability Scanning

Scans for HIGH and CRITICAL vulnerabilities:

```groovy
stage('Security Scan') {
    container('trivy') {
        sh "trivy image --severity HIGH,CRITICAL ${IMAGE_NAME}:${IMAGE_TAG}"
    }
}
```

### 2. Credential Management

Secure credential handling:

```groovy
environment {
    DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
}

sh """
    echo \${DOCKERHUB_CREDENTIALS_PSW} | docker login -u \${DOCKERHUB_CREDENTIALS_USR} --password-stdin
"""
```

### 3. Non-Root Containers

All Docker images run as non-root users for security.

## 🔄 CI/CD Workflow

### Development Workflow

```bash
# 1. Developer pushes code
git push origin feature/new-feature

# 2. Jenkins auto-triggers (webhook)
# 3. Pipeline runs:
#    - Checkout code
#    - Build service
#    - Run tests
#    - Build Docker image
#    - Scan for vulnerabilities
#    - Push to DockerHub
#    - Deploy to dev environment

# 4. Developer verifies deployment
kubectl get pods -n devsecops-dev
```

### Release Workflow

```bash
# 1. Merge to master
git checkout master
git merge develop
git push origin master

# 2. Jenkins builds from master
# 3. Runs all stages with prod parameters
# 4. Deploys to staging first
# 5. Manual approval for production
# 6. Deploys to production
```

## 📊 Monitoring Builds

### View Build Logs

```bash
# Via UI
http://jenkins:8080/job/frontend-pipeline/lastBuild/console

# Via API
curl http://admin:password@jenkins:8080/job/frontend-pipeline/lastBuild/consoleText
```

### Check Build Status

```bash
# Get build info
curl http://admin:password@jenkins:8080/job/frontend-pipeline/lastBuild/api/json

# Get build result
curl -s http://admin:password@jenkins:8080/job/frontend-pipeline/lastBuild/api/json | jq -r '.result'
```

### Blue Ocean View

Access modern UI:
```
http://jenkins:8080/blue/organizations/jenkins/frontend-pipeline/activity
```

## 🔧 Troubleshooting

### Build Fails - Docker Permission Denied

**Problem:** Docker commands fail with permission errors

**Solution:** Ensure pod has privileged security context:
```yaml
securityContext:
  privileged: true
```

### Build Fails - Kubernetes Access

**Problem:** kubectl commands fail

**Solution:** Create ServiceAccount with proper permissions:
```bash
kubectl create serviceaccount jenkins -n jenkins
kubectl create clusterrolebinding jenkins --clusterrole=cluster-admin --serviceaccount=jenkins:jenkins
```

### Build Fails - DockerHub Login

**Problem:** Authentication fails

**Solution:** 
1. Verify credentials in Jenkins
2. Use access token instead of password
3. Check credential ID matches: `dockerhub-credentials`

### npm ci Fails - Missing package-lock.json

**Problem:** `npm ci` requires package-lock.json

**Solution:** Dockerfiles updated to use `npm install` instead

### Slow Builds

**Problem:** Builds take too long

**Solutions:**
1. Enable parallel stages
2. Use caching for dependencies
3. Increase Jenkins executor count
4. Use faster build agents

## 🎯 Best Practices

### 1. Use Multibranch Pipelines
- Auto-discovery of branches
- Separate builds per branch
- Easy PR integration

### 2. Implement Quality Gates
```groovy
stage('Quality Gate') {
    steps {
        script {
            def coverage = sh(script: 'cat coverage.txt', returnStdout: true).toFloat()
            if (coverage < 80) {
                error("Code coverage below 80%")
            }
        }
    }
}
```

### 3. Use Shared Libraries
Create reusable pipeline code:

```groovy
// vars/buildDockerImage.groovy
def call(String imageName, String tag) {
    sh "docker build -t ${imageName}:${tag} ."
}

// In Jenkinsfile
buildDockerImage(env.IMAGE_NAME, env.IMAGE_TAG)
```

### 4. Implement Approval Gates for Production

```groovy
stage('Deploy to Production') {
    when {
        branch 'master'
    }
    steps {
        input message: 'Deploy to Production?', ok: 'Deploy'
        // deployment steps
    }
}
```

### 5. Send Notifications

```groovy
post {
    success {
        slackSend(channel: '#devops', color: 'good', message: "Build SUCCESS")
    }
    failure {
        slackSend(channel: '#devops', color: 'danger', message: "Build FAILED")
    }
}
```

## 📚 Additional Resources

- [Jenkinsfile Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [Docker Pipeline Plugin](https://plugins.jenkins.io/docker-workflow/)
- [Blue Ocean](https://www.jenkins.io/doc/book/blueocean/)

## ✅ Checklist

Before running pipelines:

- [ ] Jenkins installed and accessible
- [ ] DockerHub credentials configured (`dockerhub-credentials`)
- [ ] Kubernetes access configured (ServiceAccount or kubeconfig)
- [ ] GitHub webhook configured (for auto-triggering)
- [ ] Pipeline jobs created
- [ ] First build tested successfully
- [ ] Notifications configured (Slack/Email)
- [ ] SonarQube integrated (optional)

---

**DockerHub Username:** khaledhawil  
**Jenkins Namespace:** jenkins  
**Target Namespaces:** devsecops-dev, devsecops-staging, devsecops-prod

All Jenkinsfiles are production-ready with professional stages! 🚀
