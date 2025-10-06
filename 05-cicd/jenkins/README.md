# Jenkins CI/CD Configuration

This directory contains Jenkins pipelines and configurations for the DevSecOps project.

## Directory Structure

```
jenkins/
├── README.md                    # This file
├── values.yaml                  # Helm values for Jenkins deployment
├── pipelines/                   # Pipeline definitions
│   ├── Jenkinsfile.frontend
│   ├── Jenkinsfile.auth-service
│   ├── Jenkinsfile.user-service
│   ├── Jenkinsfile.analytics-service
│   ├── Jenkinsfile.notification-service
│   └── Jenkinsfile.infrastructure
├── shared-libraries/            # Shared pipeline libraries
│   └── vars/
│       ├── buildDockerImage.groovy
│       ├── deployToKubernetes.groovy
│       └── securityScan.groovy
└── job-dsl/                     # Job DSL scripts
    └── seed-job.groovy
```

## Setup Jenkins

Use the setup script in the 09-scripts directory:

```bash
cd 09-scripts
./08-setup-jenkins.sh
```

## Pipeline Features

All Jenkins pipelines include:

- [✓] Code checkout from Git
- [✓] Unit and integration tests
- [✓] Docker image building
- [✓] Security scanning with Trivy
- [✓] Image push to Docker Hub
- [✓] Kubernetes deployment
- [✓] Smoke tests
- [✓] Notifications (Slack/Email)

## Deploy with Jenkins

Use the deployment script:

```bash
cd 09-scripts
./deploy-with-jenkins.sh <environment>
```

## Jenkins Configuration

### Installed Plugins

- Kubernetes
- Docker
- Git
- Pipeline
- Blue Ocean
- SonarQube
- Trivy
- Slack/Email notifications
- Credentials binding
- AWS

### Pod Templates

Jenkins uses Kubernetes pod templates for:

- Docker builds (docker-in-docker)
- kubectl commands
- Maven builds
- Node.js builds
- Python builds
- Go builds

### Credentials

Required credentials in Jenkins:

- `dockerhub-creds`: Docker Hub username/password
- `github-creds`: GitHub username/token
- `aws-creds`: AWS access key/secret
- `kubernetes-creds`: Kubernetes config

## Usage

### Trigger Build via UI

1. Access Jenkins: `kubectl port-forward svc/jenkins -n jenkins 8080:8080`
2. Login with admin credentials
3. Select job
4. Click "Build with Parameters"
5. Choose environment and trigger

### Trigger Build via API

```bash
# Get crumb
CRUMB=$(curl -s 'http://admin:password@localhost:8080/crumbIssuer/api/json' | jq -r '.crumb')

# Trigger build
curl -X POST \
  -H "Jenkins-Crumb:$CRUMB" \
  "http://admin:password@localhost:8080/job/frontend-dev/buildWithParameters?ENVIRONMENT=dev"
```

### Trigger Build via CLI

```bash
# Download Jenkins CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Trigger build
java -jar jenkins-cli.jar -s http://localhost:8080 \
  -auth admin:password \
  build frontend-dev -p ENVIRONMENT=dev
```

## Pipeline Structure

Example Jenkinsfile structure:

```groovy
pipeline {
    agent {
        kubernetes {
            label 'docker'
        }
    }
    
    environment {
        DOCKER_REGISTRY = 'khaledhawil'
        IMAGE_NAME = "${DOCKER_REGISTRY}/${JOB_NAME}"
    }
    
    stages {
        stage('Checkout') { }
        stage('Build') { }
        stage('Test') { }
        stage('Security Scan') { }
        stage('Push Image') { }
        stage('Deploy') { }
    }
    
    post {
        always { }
        success { }
        failure { }
    }
}
```

## Monitoring

### View Build Logs

```bash
# Via UI
http://localhost:8080/job/<job-name>/lastBuild/console

# Via API
curl http://admin:password@localhost:8080/job/<job-name>/lastBuild/consoleText
```

### Build Status

```bash
# Get last build status
curl http://admin:password@localhost:8080/job/<job-name>/lastBuild/api/json
```

## Webhooks

Configure GitHub webhooks to trigger builds automatically:

1. Go to GitHub repository settings
2. Add webhook: `http://<jenkins-url>/github-webhook/`
3. Select events: Push, Pull Request
4. Save webhook

## Best Practices

1. Use parameterized builds for flexibility
2. Implement parallel stages for speed
3. Use shared libraries for reusable code
4. Configure proper timeout values
5. Implement proper error handling
6. Use declarative pipelines when possible
7. Store credentials securely
8. Enable build artifacts archiving
9. Configure proper notifications
10. Implement approval gates for production

## Troubleshooting

### Build Fails

Check logs:
```bash
kubectl logs -f -l app.kubernetes.io/component=jenkins-controller -n jenkins
```

### Agent Connection Issues

Check agent pods:
```bash
kubectl get pods -n jenkins -l jenkins=agent
```

### Permission Issues

Check service account:
```bash
kubectl get serviceaccount jenkins -n jenkins
kubectl describe clusterrolebinding jenkins
```

## Integration with Other Tools

### SonarQube

Configure in Jenkins:
- Manage Jenkins → Configure System
- Add SonarQube server
- Configure quality gates

### Trivy

Already included in pipelines:
```groovy
stage('Security Scan') {
    sh 'trivy image --severity HIGH,CRITICAL ${IMAGE_NAME}'
}
```

### ArgoCD

Deploy to ArgoCD after Jenkins build:
```groovy
stage('Update GitOps') {
    sh '''
        git clone <gitops-repo>
        cd gitops-repo
        kustomize edit set image ${IMAGE_NAME}:${IMAGE_TAG}
        git commit -am "Update image to ${IMAGE_TAG}"
        git push
    '''
}
```

## Related Documentation

- [Main CI/CD README](../README.md)
- [ArgoCD Configuration](../argocd/README.md)
- [Flux Configuration](../flux/README.md)
- [GitHub Actions](../github-actions/README.md)
- [Setup Script](../../09-scripts/08-setup-jenkins.sh)
- [Deployment Script](../../09-scripts/deploy-with-jenkins.sh)

## Support

For Jenkins-specific issues:
- Jenkins Documentation: https://www.jenkins.io/doc/
- Kubernetes Plugin: https://plugins.jenkins.io/kubernetes/
- Pipeline Syntax: https://www.jenkins.io/doc/book/pipeline/syntax/

Username configured: khaledhawil
