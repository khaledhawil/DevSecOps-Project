#!/bin/bash

#######################################
# Setup Flux CD for GitOps
# Author: DevSecOps Team
# Description: Installs and configures Flux CD v2 for GitOps continuous delivery
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
LOG_FILE="${LOG_DIR}/setup-flux.log"
FLUX_NAMESPACE="flux-system"
GITHUB_USER="${GITHUB_USERNAME:-khaledhawil}"
GITHUB_REPO="${GITHUB_REPO:-devsecops-project}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"

# Environment
ENVIRONMENT="${1:-dev}"

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
    
    if ! command -v flux &> /dev/null; then
        log_warning "Flux CLI not found, will install it"
        install_flux_cli
    fi
    
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_error "Please run: ./setup-prerequisites.sh"
        exit 2
    fi
    
    log "All prerequisites satisfied"
}

# Function to install Flux CLI
install_flux_cli() {
    log "Installing Flux CLI..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -s https://fluxcd.io/install.sh | sudo bash
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install fluxcd/tap/flux
    else
        log_error "Unsupported OS. Please install Flux CLI manually: https://fluxcd.io/flux/installation/"
        exit 1
    fi
    
    log "Flux CLI installed successfully"
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

# Function to check Flux prerequisites
check_flux_prerequisites() {
    log "Checking Flux prerequisites on cluster..."
    
    flux check --pre
    
    if [ $? -ne 0 ]; then
        log_error "Flux prerequisites check failed"
        log_error "Please ensure your cluster meets Flux requirements"
        exit 1
    fi
    
    log "Flux prerequisites check passed"
}

# Function to get GitHub token
get_github_token() {
    log "Checking for GitHub token..."
    
    if [ -z "${GITHUB_TOKEN}" ]; then
        if [ -f "${PROJECT_ROOT}/.env" ]; then
            source "${PROJECT_ROOT}/.env"
        fi
    fi
    
    if [ -z "${GITHUB_TOKEN}" ]; then
        log_error "GITHUB_TOKEN not found"
        log_error "Please set GITHUB_TOKEN environment variable or add it to .env file"
        log_error "Create a GitHub Personal Access Token with 'repo' scope"
        log_error "https://github.com/settings/tokens"
        exit 1
    fi
    
    export GITHUB_TOKEN
    log "GitHub token found"
}

# Function to bootstrap Flux
bootstrap_flux() {
    log "Bootstrapping Flux CD..."
    
    flux bootstrap github \
        --owner="${GITHUB_USER}" \
        --repository="${GITHUB_REPO}" \
        --branch="${GITHUB_BRANCH}" \
        --path="./clusters/${ENVIRONMENT}" \
        --personal \
        --private=false \
        --token-auth
    
    if [ $? -ne 0 ]; then
        log_error "Flux bootstrap failed"
        exit 1
    fi
    
    log "Flux bootstrapped successfully"
}

# Function to wait for Flux to be ready
wait_for_flux() {
    log "Waiting for Flux components to be ready..."
    
    kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/instance=flux-system \
        -n "${FLUX_NAMESPACE}" \
        --timeout=600s
    
    log "Flux components are ready"
}

# Function to create Git repository structure
create_git_structure() {
    log "Creating Flux Git repository structure..."
    
    local FLUX_DIR="${PROJECT_ROOT}/clusters/${ENVIRONMENT}"
    mkdir -p "${FLUX_DIR}"/{apps,infrastructure,monitoring,security}
    
    # Create kustomization files
    cat > "${FLUX_DIR}/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - infrastructure
  - apps
  - monitoring
  - security
EOF
    
    cat > "${FLUX_DIR}/infrastructure/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - postgres.yaml
  - redis.yaml
EOF
    
    cat > "${FLUX_DIR}/apps/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - auth-service.yaml
  - user-service.yaml
  - analytics-service.yaml
  - notification-service.yaml
  - frontend.yaml
EOF
    
    log "Git repository structure created"
}

# Function to create Flux sources
create_flux_sources() {
    log "Creating Flux sources..."
    
    local SOURCES_DIR="${SCRIPT_DIR}/flux-sources"
    mkdir -p "${SOURCES_DIR}"
    
    # Create GitRepository source
    cat > "${SOURCES_DIR}/git-repository.yaml" <<EOF
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: devsecops-repo
  namespace: ${FLUX_NAMESPACE}
spec:
  interval: 1m
  url: https://github.com/${GITHUB_USER}/${GITHUB_REPO}
  ref:
    branch: ${GITHUB_BRANCH}
  secretRef:
    name: github-credentials
EOF
    
    # Create HelmRepository for charts
    cat > "${SOURCES_DIR}/helm-repositories.yaml" <<EOF
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: bitnami
  namespace: ${FLUX_NAMESPACE}
spec:
  interval: 24h
  url: https://charts.bitnami.com/bitnami
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: prometheus-community
  namespace: ${FLUX_NAMESPACE}
spec:
  interval: 24h
  url: https://prometheus-community.github.io/helm-charts
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: grafana
  namespace: ${FLUX_NAMESPACE}
spec:
  interval: 24h
  url: https://grafana.github.io/helm-charts
EOF
    
    kubectl apply -f "${SOURCES_DIR}/"
    
    log "Flux sources created"
}

# Function to create Flux kustomizations
create_flux_kustomizations() {
    log "Creating Flux kustomizations..."
    
    local KUSTOMIZE_DIR="${SCRIPT_DIR}/flux-kustomizations"
    mkdir -p "${KUSTOMIZE_DIR}"
    
    # Infrastructure kustomization
    cat > "${KUSTOMIZE_DIR}/infrastructure.yaml" <<EOF
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: infrastructure
  namespace: ${FLUX_NAMESPACE}
spec:
  interval: 10m
  sourceRef:
    kind: GitRepository
    name: devsecops-repo
  path: ./clusters/${ENVIRONMENT}/infrastructure
  prune: true
  wait: true
  timeout: 5m
EOF
    
    # Apps kustomization
    cat > "${KUSTOMIZE_DIR}/apps.yaml" <<EOF
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps
  namespace: ${FLUX_NAMESPACE}
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: devsecops-repo
  path: ./clusters/${ENVIRONMENT}/apps
  prune: true
  wait: true
  timeout: 10m
  dependsOn:
    - name: infrastructure
EOF
    
    # Monitoring kustomization
    cat > "${KUSTOMIZE_DIR}/monitoring.yaml" <<EOF
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: monitoring
  namespace: ${FLUX_NAMESPACE}
spec:
  interval: 10m
  sourceRef:
    kind: GitRepository
    name: devsecops-repo
  path: ./clusters/${ENVIRONMENT}/monitoring
  prune: true
  wait: true
  timeout: 5m
  dependsOn:
    - name: infrastructure
EOF
    
    kubectl apply -f "${KUSTOMIZE_DIR}/"
    
    log "Flux kustomizations created"
}

# Function to create image automation
create_image_automation() {
    log "Creating Flux image automation..."
    
    local IMAGE_DIR="${SCRIPT_DIR}/flux-image-automation"
    mkdir -p "${IMAGE_DIR}"
    
    # Image repository
    cat > "${IMAGE_DIR}/image-repository.yaml" <<EOF
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: auth-service
  namespace: ${FLUX_NAMESPACE}
spec:
  image: khaledhawil/auth-service
  interval: 5m
---
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: user-service
  namespace: ${FLUX_NAMESPACE}
spec:
  image: khaledhawil/user-service
  interval: 5m
---
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: analytics-service
  namespace: ${FLUX_NAMESPACE}
spec:
  image: khaledhawil/analytics-service
  interval: 5m
---
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: notification-service
  namespace: ${FLUX_NAMESPACE}
spec:
  image: khaledhawil/notification-service
  interval: 5m
---
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: frontend
  namespace: ${FLUX_NAMESPACE}
spec:
  image: khaledhawil/frontend
  interval: 5m
EOF
    
    # Image policy
    cat > "${IMAGE_DIR}/image-policy.yaml" <<EOF
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImagePolicy
metadata:
  name: auth-service
  namespace: ${FLUX_NAMESPACE}
spec:
  imageRepositoryRef:
    name: auth-service
  policy:
    semver:
      range: '>=1.0.0'
---
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImagePolicy
metadata:
  name: user-service
  namespace: ${FLUX_NAMESPACE}
spec:
  imageRepositoryRef:
    name: user-service
  policy:
    semver:
      range: '>=1.0.0'
EOF
    
    # Image update automation
    cat > "${IMAGE_DIR}/image-update.yaml" <<EOF
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImageUpdateAutomation
metadata:
  name: devsecops-automation
  namespace: ${FLUX_NAMESPACE}
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: devsecops-repo
  git:
    checkout:
      ref:
        branch: ${GITHUB_BRANCH}
    commit:
      author:
        email: fluxcd@users.noreply.github.com
        name: FluxCD
      messageTemplate: |
        Automated image update
        
        Automation name: {{ .AutomationObject }}
        
        Files:
        {{ range \$filename, \$_ := .Updated.Files -}}
        - {{ \$filename }}
        {{ end -}}
        
        Objects:
        {{ range \$resource, \$_ := .Updated.Objects -}}
        - {{ \$resource.Kind }} {{ \$resource.Name }}
        {{ end -}}
    push:
      branch: ${GITHUB_BRANCH}
  update:
    path: ./clusters/${ENVIRONMENT}
    strategy: Setters
EOF
    
    kubectl apply -f "${IMAGE_DIR}/"
    
    log "Flux image automation created"
}

# Function to create Flux alerts
create_flux_alerts() {
    log "Creating Flux notification alerts..."
    
    local ALERTS_DIR="${SCRIPT_DIR}/flux-alerts"
    mkdir -p "${ALERTS_DIR}"
    
    # Alert provider (Slack example)
    cat > "${ALERTS_DIR}/alert-provider.yaml" <<EOF
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Provider
metadata:
  name: slack
  namespace: ${FLUX_NAMESPACE}
spec:
  type: slack
  channel: flux-notifications
  secretRef:
    name: slack-webhook
---
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Provider
metadata:
  name: github
  namespace: ${FLUX_NAMESPACE}
spec:
  type: github
  address: https://github.com/${GITHUB_USER}/${GITHUB_REPO}
  secretRef:
    name: github-token
EOF
    
    # Alert
    cat > "${ALERTS_DIR}/alert.yaml" <<EOF
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Alert
metadata:
  name: flux-system
  namespace: ${FLUX_NAMESPACE}
spec:
  providerRef:
    name: slack
  eventSeverity: info
  eventSources:
    - kind: GitRepository
      name: '*'
    - kind: Kustomization
      name: '*'
    - kind: HelmRelease
      name: '*'
    - kind: ImageRepository
      name: '*'
    - kind: ImagePolicy
      name: '*'
  suspend: false
EOF
    
    kubectl apply -f "${ALERTS_DIR}/"
    
    log "Flux alerts created"
}

# Function to check Flux status
check_flux_status() {
    log "Checking Flux status..."
    
    echo ""
    echo "Flux Components:"
    flux check
    
    echo ""
    echo "Git Repositories:"
    flux get sources git
    
    echo ""
    echo "Kustomizations:"
    flux get kustomizations
    
    echo ""
    echo "Helm Releases:"
    flux get helmreleases --all-namespaces
    
    log "Flux status check completed"
}

# Function to display summary
display_summary() {
    echo ""
    echo "=========================================="
    echo "Flux CD Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Configuration:"
    echo "  GitHub User:   ${GITHUB_USER}"
    echo "  Repository:    ${GITHUB_REPO}"
    echo "  Branch:        ${GITHUB_BRANCH}"
    echo "  Environment:   ${ENVIRONMENT}"
    echo "  Namespace:     ${FLUX_NAMESPACE}"
    echo ""
    echo "Next Steps:"
    echo "1. Push your Kubernetes manifests to the Git repository"
    echo "2. Flux will automatically sync changes from Git"
    echo "3. Monitor reconciliation: flux get kustomizations --watch"
    echo "4. Configure Slack/GitHub notifications"
    echo ""
    echo "Useful Commands:"
    echo "  Check status:       flux get all"
    echo "  View logs:          flux logs --all-namespaces"
    echo "  Force reconcile:    flux reconcile kustomization <name>"
    echo "  Suspend/Resume:     flux suspend/resume kustomization <name>"
    echo "  Export config:      flux export source git --all"
    echo ""
    echo "Image Automation:"
    echo "  Flux will automatically detect new image tags"
    echo "  And update your deployments in Git"
    echo "  Configure image policies for version control"
    echo ""
    echo "Documentation:"
    echo "  Flux docs:     https://fluxcd.io/docs/"
    echo "  GitHub:        https://github.com/fluxcd/flux2"
    echo "  Tutorials:     https://fluxcd.io/flux/guides/"
    echo "=========================================="
}

# Main function
main() {
    log "Starting Flux CD setup for environment: ${ENVIRONMENT}"
    echo ""
    
    if [ -z "${ENVIRONMENT}" ]; then
        log_error "Environment not specified"
        log_error "Usage: $0 <environment>"
        log_error "  environment: dev, staging, or prod"
        exit 1
    fi
    
    check_prerequisites
    verify_kubernetes
    check_flux_prerequisites
    get_github_token
    bootstrap_flux
    wait_for_flux
    create_git_structure
    create_flux_sources
    create_flux_kustomizations
    create_image_automation
    create_flux_alerts
    check_flux_status
    display_summary
    
    log "Flux CD setup completed successfully!"
    exit 0
}

# Run main function
main "$@"
