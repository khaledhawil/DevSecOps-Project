#!/bin/bash

#######################################
# Setup Jenkins CI/CD Server
# Author: DevSecOps Team
# Description: Installs and configures Jenkins with plugins and pipelines
#######################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/setup-jenkins.log"
JENKINS_NAMESPACE="jenkins"
JENKINS_RELEASE="jenkins"

# Create log directory
mkdir -p "${LOG_DIR}"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "${LOG_FILE}"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "${LOG_FILE}"
}

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v helm &> /dev/null; then
        missing_tools+=("helm")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_error "Please run: ./setup-prerequisites.sh"
        exit 2
    fi
    
    log "All prerequisites satisfied"
}

# Function to verify Kubernetes connection
verify_kubernetes() {
    log "Verifying Kubernetes cluster connection..."
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        log_error "Please configure kubectl access to your cluster"
        exit 1
    fi
    
    log "Successfully connected to Kubernetes cluster"
}

# Function to create namespace
create_namespace() {
    log "Creating Jenkins namespace..."
    
    if kubectl get namespace "${JENKINS_NAMESPACE}" &> /dev/null; then
        log_warning "Namespace ${JENKINS_NAMESPACE} already exists"
    else
        kubectl create namespace "${JENKINS_NAMESPACE}"
        log "Namespace ${JENKINS_NAMESPACE} created"
    fi
}

# Function to add Helm repository
add_helm_repo() {
    log "Adding Jenkins Helm repository..."
    
    helm repo add jenkins https://charts.jenkins.io
    helm repo update
    
    log "Jenkins Helm repository added and updated"
}

# Function to create values file for Jenkins
create_jenkins_values() {
    log "Creating Jenkins Helm values file..."
    
    local VALUES_FILE="${SCRIPT_DIR}/jenkins-values.yaml"
    
    cat > "${VALUES_FILE}" <<'EOF'
controller:
  componentName: "jenkins-controller"
  image: "jenkins/jenkins"
  tag: "2.426.1-lts"
  imagePullPolicy: "Always"
  
  # Resources
  resources:
    requests:
      cpu: "500m"
      memory: "512Mi"
    limits:
      cpu: "2000m"
      memory: "4096Mi"
  
  # Java options
  javaOpts: "-Xms512m -Xmx2048m"
  
  # Service type
  serviceType: LoadBalancer
  servicePort: 8080
  
  # Admin credentials
  admin:
    existingSecret: ""
    userKey: jenkins-admin-user
    passwordKey: jenkins-admin-password
  
  # Install plugins
  installPlugins:
    - kubernetes:4029.v5712230ccb_f8
    - workflow-aggregator:596.v8c21c963d92d
    - git:5.2.1
    - configuration-as-code:1670.v564dc8b_982d0
    - kubernetes-credentials-provider:1.231.v0b_3b_e77d_c18c
    - docker-workflow:572.v950f58993843
    - github-branch-source:1746.v217e27d3c27c
    - pipeline-stage-view:2.34
    - blueocean:1.27.9
    - prometheus:2.3.1
    - sonarqube:2.17.2
    - trivy:0.1.0
    - slack:664.vc9a_90f8b_c24a_
    - email-ext:2.102
    - credentials-binding:631.v861fa_8b_b_1847
    - docker-plugin:1.5
    - pipeline-utility-steps:2.16.0
    - http_request:1.18
    - job-dsl:1.87
    - matrix-auth:3.2.2
    - pipeline-aws:1.43
  
  # Additional plugins for DevSecOps
  additionalPlugins:
    - owasp-dependency-check:5.4.3
    - aqua-security-scanner:3.0.22
    - anchore-container-scanner:1.0.25
  
  # Jenkins Configuration as Code
  JCasC:
    defaultConfig: true
    configScripts:
      welcome-message: |
        jenkins:
          systemMessage: "Jenkins configured automatically by DevSecOps platform"
      security: |
        jenkins:
          securityRealm:
            local:
              allowsSignup: false
          authorizationStrategy:
            loggedInUsersCanDoAnything:
              allowAnonymousRead: false
      credentials: |
        credentials:
          system:
            domainCredentials:
              - credentials:
                - usernamePassword:
                    scope: GLOBAL
                    id: dockerhub-creds
                    username: ${DOCKERHUB_USER}
                    password: ${DOCKERHUB_PASS}
                    description: "Docker Hub credentials"
                - usernamePassword:
                    scope: GLOBAL
                    id: github-creds
                    username: ${GITHUB_USER}
                    password: ${GITHUB_TOKEN}
                    description: "GitHub credentials"
                - aws:
                    scope: GLOBAL
                    id: aws-creds
                    accessKey: ${AWS_ACCESS_KEY_ID}
                    secretKey: ${AWS_SECRET_ACCESS_KEY}
                    description: "AWS credentials"
  
  # Ingress configuration
  ingress:
    enabled: true
    apiVersion: "networking.k8s.io/v1"
    annotations:
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: letsencrypt-prod
    hostName: jenkins.example.com
    tls:
      - secretName: jenkins-tls
        hosts:
          - jenkins.example.com

# Persistence
persistence:
  enabled: true
  storageClass: "gp3"
  size: "20Gi"
  accessMode: ReadWriteOnce

# Backup configuration
backup:
  enabled: true
  schedule: "0 2 * * *"
  destination: s3

# Agent configuration
agent:
  enabled: true
  image: "jenkins/inbound-agent"
  tag: "latest"
  resources:
    requests:
      cpu: "250m"
      memory: "256Mi"
    limits:
      cpu: "1000m"
      memory: "2048Mi"
  
  # Pod templates for different types of builds
  podTemplates:
    docker: |
      - name: docker
        label: docker
        serviceAccount: jenkins
        containers:
        - name: docker
          image: docker:24-dind
          command: ["cat"]
          tty: true
          privileged: true
        - name: docker-cli
          image: docker:24-cli
          command: ["cat"]
          tty: true
          volumeMounts:
          - name: docker-sock
            mountPath: /var/run/docker.sock
        volumes:
        - name: docker-sock
          hostPath:
            path: /var/run/docker.sock
    
    kubectl: |
      - name: kubectl
        label: kubectl
        serviceAccount: jenkins
        containers:
        - name: kubectl
          image: bitnami/kubectl:latest
          command: ["cat"]
          tty: true
    
    maven: |
      - name: maven
        label: maven
        serviceAccount: jenkins
        containers:
        - name: maven
          image: maven:3.9-eclipse-temurin-17
          command: ["cat"]
          tty: true
    
    node: |
      - name: node
        label: node
        serviceAccount: jenkins
        containers:
        - name: node
          image: node:20-alpine
          command: ["cat"]
          tty: true
    
    python: |
      - name: python
        label: python
        serviceAccount: jenkins
        containers:
        - name: python
          image: python:3.11-slim
          command: ["cat"]
          tty: true
    
    go: |
      - name: go
        label: go
        serviceAccount: jenkins
        containers:
        - name: go
          image: golang:1.21-alpine
          command: ["cat"]
          tty: true

# Monitoring
prometheus:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: monitoring

# Security
rbac:
  create: true
  readSecrets: true

serviceAccount:
  create: true
  name: jenkins

networkPolicy:
  enabled: true
  internalAgents:
    allowed: true
EOF
    
    log "Jenkins values file created: ${VALUES_FILE}"
}

# Function to create secrets for credentials
create_secrets() {
    log "Creating Jenkins secrets..."
    
    # Check if .env file exists
    if [ -f "${PROJECT_ROOT}/.env" ]; then
        source "${PROJECT_ROOT}/.env"
    fi
    
    # Docker Hub credentials
    DOCKERHUB_USER="${DOCKER_USERNAME:-khaledhawil}"
    DOCKERHUB_PASS="${DOCKER_PASSWORD:-changeme}"
    
    # GitHub credentials
    GITHUB_USER="${GITHUB_USERNAME:-khaledhawil}"
    GITHUB_TOKEN="${GITHUB_TOKEN:-changeme}"
    
    # AWS credentials
    AWS_ACCESS_KEY="${AWS_ACCESS_KEY_ID:-changeme}"
    AWS_SECRET_KEY="${AWS_SECRET_ACCESS_KEY:-changeme}"
    
    # Create admin secret
    kubectl create secret generic jenkins-admin-credentials \
        --from-literal=jenkins-admin-user=admin \
        --from-literal=jenkins-admin-password="$(openssl rand -base64 20)" \
        --namespace="${JENKINS_NAMESPACE}" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create Docker Hub secret
    kubectl create secret generic dockerhub-credentials \
        --from-literal=username="${DOCKERHUB_USER}" \
        --from-literal=password="${DOCKERHUB_PASS}" \
        --namespace="${JENKINS_NAMESPACE}" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create GitHub secret
    kubectl create secret generic github-credentials \
        --from-literal=username="${GITHUB_USER}" \
        --from-literal=token="${GITHUB_TOKEN}" \
        --namespace="${JENKINS_NAMESPACE}" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create AWS secret
    kubectl create secret generic aws-credentials \
        --from-literal=access-key="${AWS_ACCESS_KEY}" \
        --from-literal=secret-key="${AWS_SECRET_KEY}" \
        --namespace="${JENKINS_NAMESPACE}" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log "Jenkins secrets created"
}

# Function to install Jenkins
install_jenkins() {
    log "Installing Jenkins with Helm..."
    
    local VALUES_FILE="${SCRIPT_DIR}/jenkins-values.yaml"
    
    helm upgrade --install "${JENKINS_RELEASE}" jenkins/jenkins \
        --namespace "${JENKINS_NAMESPACE}" \
        --values "${VALUES_FILE}" \
        --wait \
        --timeout 10m
    
    log "Jenkins installed successfully"
}

# Function to wait for Jenkins to be ready
wait_for_jenkins() {
    log "Waiting for Jenkins to be ready..."
    
    kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/component=jenkins-controller \
        -n "${JENKINS_NAMESPACE}" \
        --timeout=600s
    
    log "Jenkins is ready"
}

# Function to get Jenkins credentials
get_jenkins_credentials() {
    log "Retrieving Jenkins admin credentials..."
    
    local ADMIN_USER=$(kubectl get secret jenkins-admin-credentials \
        -n "${JENKINS_NAMESPACE}" \
        -o jsonpath="{.data.jenkins-admin-user}" | base64 --decode)
    
    local ADMIN_PASSWORD=$(kubectl get secret jenkins-admin-credentials \
        -n "${JENKINS_NAMESPACE}" \
        -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)
    
    echo ""
    echo "=========================================="
    echo "Jenkins Admin Credentials"
    echo "=========================================="
    echo "Username: ${ADMIN_USER}"
    echo "Password: ${ADMIN_PASSWORD}"
    echo "=========================================="
    echo ""
}

# Function to get Jenkins URL
get_jenkins_url() {
    log "Getting Jenkins URL..."
    
    local JENKINS_URL=$(kubectl get svc "${JENKINS_RELEASE}" \
        -n "${JENKINS_NAMESPACE}" \
        -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    if [ -z "${JENKINS_URL}" ]; then
        JENKINS_URL=$(kubectl get svc "${JENKINS_RELEASE}" \
            -n "${JENKINS_NAMESPACE}" \
            -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    fi
    
    if [ -z "${JENKINS_URL}" ]; then
        log_warning "LoadBalancer URL not yet available"
        log_info "Run: kubectl get svc -n ${JENKINS_NAMESPACE} to check status"
        JENKINS_URL="<pending>"
    fi
    
    echo ""
    echo "=========================================="
    echo "Jenkins Access Information"
    echo "=========================================="
    echo "Jenkins URL: http://${JENKINS_URL}:8080"
    echo "Namespace: ${JENKINS_NAMESPACE}"
    echo "=========================================="
    echo ""
}

# Function to create sample pipelines
create_sample_pipelines() {
    log "Creating sample Jenkins pipeline configurations..."
    
    local PIPELINES_DIR="${SCRIPT_DIR}/jenkins-pipelines"
    mkdir -p "${PIPELINES_DIR}"
    
    # Sample Jenkinsfile for microservices
    cat > "${PIPELINES_DIR}/Jenkinsfile.microservice" <<'PIPELINE_EOF'
pipeline {
    agent {
        kubernetes {
            label 'docker'
        }
    }
    
    environment {
        DOCKER_REGISTRY = 'khaledhawil'
        IMAGE_NAME = "${DOCKER_REGISTRY}/${JOB_NAME}"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                sh """
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                """
            }
        }
        
        stage('Test') {
            steps {
                sh 'make test'
            }
        }
        
        stage('Security Scan') {
            steps {
                sh """
                    trivy image --severity HIGH,CRITICAL ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
        
        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                    """
                }
            }
        }
        
        stage('Deploy to Dev') {
            steps {
                withKubeConfig([credentialsId: 'kubernetes-creds']) {
                    sh """
                        kubectl set image deployment/${JOB_NAME} \
                            ${JOB_NAME}=${IMAGE_NAME}:${IMAGE_TAG} \
                            -n dev
                    """
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
PIPELINE_EOF
    
    log "Sample pipelines created in ${PIPELINES_DIR}"
}

# Function to display summary
display_summary() {
    echo ""
    echo "=========================================="
    echo "Jenkins Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Next Steps:"
    echo "1. Access Jenkins UI using the URL above"
    echo "2. Login with the admin credentials"
    echo "3. Configure pipeline jobs"
    echo "4. Set up webhooks in GitHub"
    echo "5. Configure SonarQube integration"
    echo ""
    echo "Useful Commands:"
    echo "  View pods:     kubectl get pods -n ${JENKINS_NAMESPACE}"
    echo "  View logs:     kubectl logs -f -l app.kubernetes.io/component=jenkins-controller -n ${JENKINS_NAMESPACE}"
    echo "  Port forward:  kubectl port-forward svc/${JENKINS_RELEASE} 8080:8080 -n ${JENKINS_NAMESPACE}"
    echo ""
    echo "Documentation:"
    echo "  Jenkins docs: https://www.jenkins.io/doc/"
    echo "  Kubernetes plugin: https://plugins.jenkins.io/kubernetes/"
    echo "=========================================="
}

# Main function
main() {
    log "Starting Jenkins setup..."
    echo ""
    
    check_prerequisites
    verify_kubernetes
    create_namespace
    add_helm_repo
    create_jenkins_values
    create_secrets
    install_jenkins
    wait_for_jenkins
    get_jenkins_credentials
    get_jenkins_url
    create_sample_pipelines
    display_summary
    
    log "Jenkins setup completed successfully!"
    exit 0
}

# Run main function
main "$@"
