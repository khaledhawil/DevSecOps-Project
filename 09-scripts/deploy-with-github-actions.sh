#!/bin/bash

#######################################
# Deploy with GitHub Actions
# Author: DevSecOps Team
# Description: Trigger and monitor GitHub Actions workflows for deployment
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
LOG_FILE="${LOG_DIR}/deploy-with-github-actions.log"
ENVIRONMENT="${1:-dev}"
GITHUB_USER="${GITHUB_USERNAME:-khaledhawil}"
GITHUB_REPO="${GITHUB_REPO:-devsecops-project}"

# Create log directory
mkdir -p "${LOG_DIR}"

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "${LOG_FILE}"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "${LOG_FILE}"
}

print_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║            Deploy with GitHub Actions                            ║
║                                                                  ║
║  Trigger CI/CD workflows via GitHub Actions API                  ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Validate environment
validate_environment() {
    if [[ ! "${ENVIRONMENT}" =~ ^(dev|staging|prod)$ ]]; then
        log_error "Invalid environment: ${ENVIRONMENT}"
        echo "Usage: $0 <environment>"
        echo "  environment: dev, staging, or prod"
        exit 1
    fi
    log "Environment: ${ENVIRONMENT}"
}

# Check GitHub CLI
check_github_cli() {
    log "Checking GitHub CLI..."
    
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) not found"
        log_info "Install: https://cli.github.com/"
        log_info "Or use: brew install gh (macOS) / apt install gh (Ubuntu)"
        exit 1
    fi
    
    # Check authentication
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI not authenticated"
        log_info "Run: gh auth login"
        exit 1
    fi
    
    log "GitHub CLI is configured"
}

# Check if GITHUB_TOKEN is set
check_github_token() {
    if [ -z "${GITHUB_TOKEN}" ]; then
        if [ -f "${PROJECT_ROOT}/.env" ]; then
            source "${PROJECT_ROOT}/.env"
        fi
    fi
    
    if [ -z "${GITHUB_TOKEN}" ]; then
        log_warning "GITHUB_TOKEN not set, will use gh CLI authentication"
    else
        log "GITHUB_TOKEN is set"
    fi
}

# Trigger workflow dispatch
trigger_workflow() {
    local workflow_file=$1
    local service_name=$2
    
    log_info "Triggering workflow: ${workflow_file} for ${service_name}"
    
    gh workflow run "${workflow_file}" \
        --repo "${GITHUB_USER}/${GITHUB_REPO}" \
        --ref main \
        -f environment="${ENVIRONMENT}" \
        -f service="${service_name}"
    
    if [ $? -eq 0 ]; then
        log "Workflow triggered successfully: ${workflow_file}"
    else
        log_error "Failed to trigger workflow: ${workflow_file}"
        return 1
    fi
}

# Wait for workflow to complete
wait_for_workflow() {
    local workflow_name=$1
    local timeout=600
    local elapsed=0
    
    log_info "Waiting for workflow to complete: ${workflow_name}"
    
    while [ $elapsed -lt $timeout ]; do
        local status=$(gh run list \
            --repo "${GITHUB_USER}/${GITHUB_REPO}" \
            --workflow="${workflow_name}" \
            --limit 1 \
            --json status \
            --jq '.[0].status')
        
        if [ "${status}" == "completed" ]; then
            local conclusion=$(gh run list \
                --repo "${GITHUB_USER}/${GITHUB_REPO}" \
                --workflow="${workflow_name}" \
                --limit 1 \
                --json conclusion \
                --jq '.[0].conclusion')
            
            if [ "${conclusion}" == "success" ]; then
                log "Workflow completed successfully: ${workflow_name}"
                return 0
            else
                log_error "Workflow failed: ${workflow_name} (${conclusion})"
                return 1
            fi
        fi
        
        echo -n "."
        sleep 10
        elapsed=$((elapsed + 10))
    done
    
    log_warning "Workflow timeout: ${workflow_name}"
    return 1
}

# Deploy services
deploy_services() {
    log "Deploying services via GitHub Actions..."
    
    local SERVICES=(
        "frontend:frontend.yml"
        "auth-service:auth-service.yml"
        "user-service:user-service.yml"
        "analytics-service:analytics-service.yml"
        "notification-service:notification-service.yml"
    )
    
    for service_info in "${SERVICES[@]}"; do
        IFS=':' read -r service workflow <<< "${service_info}"
        
        log_info "Deploying ${service}..."
        trigger_workflow "${workflow}" "${service}"
        
        # Wait a bit before triggering next workflow
        sleep 5
    done
    
    log "All deployment workflows triggered"
}

# Monitor workflows
monitor_workflows() {
    log "Monitoring workflow executions..."
    
    echo ""
    log_info "Recent workflow runs:"
    gh run list \
        --repo "${GITHUB_USER}/${GITHUB_REPO}" \
        --limit 10
    
    echo ""
    log_info "To watch a specific workflow:"
    echo "  gh run watch <run-id> --repo ${GITHUB_USER}/${GITHUB_REPO}"
}

# View workflow logs
view_workflow_logs() {
    local workflow_name=$1
    
    log_info "Fetching logs for: ${workflow_name}"
    
    local run_id=$(gh run list \
        --repo "${GITHUB_USER}/${GITHUB_REPO}" \
        --workflow="${workflow_name}" \
        --limit 1 \
        --json databaseId \
        --jq '.[0].databaseId')
    
    if [ -n "${run_id}" ]; then
        gh run view "${run_id}" \
            --repo "${GITHUB_USER}/${GITHUB_REPO}" \
            --log
    else
        log_warning "No recent runs found for ${workflow_name}"
    fi
}

# Deploy infrastructure
deploy_infrastructure() {
    log "Deploying infrastructure via GitHub Actions..."
    
    trigger_workflow "infrastructure.yml" "terraform"
    
    log_info "Infrastructure deployment triggered"
    log_info "Monitor at: https://github.com/${GITHUB_USER}/${GITHUB_REPO}/actions"
}

# Check deployment status
check_status() {
    log "Checking deployment status..."
    
    echo ""
    echo "Recent Workflow Runs:"
    gh run list \
        --repo "${GITHUB_USER}/${GITHUB_REPO}" \
        --limit 10 \
        --json status,conclusion,name,createdAt \
        --template '{{range .}}{{.name}} - {{.status}} ({{.conclusion}}) - {{.createdAt}}{{"\n"}}{{end}}'
    
    echo ""
    echo "Kubernetes Deployments:"
    if kubectl get namespace "${ENVIRONMENT}" &> /dev/null; then
        kubectl get deployments -n "${ENVIRONMENT}"
        echo ""
        kubectl get pods -n "${ENVIRONMENT}"
    else
        log_warning "Namespace ${ENVIRONMENT} not found"
    fi
}

# Create workflow files (if not exists)
create_workflow_files() {
    log "Checking GitHub Actions workflow files..."
    
    local WORKFLOWS_DIR="${PROJECT_ROOT}/.github/workflows"
    
    if [ ! -d "${WORKFLOWS_DIR}" ]; then
        log_warning "Workflows directory not found: ${WORKFLOWS_DIR}"
        log_info "Workflow files should be in 05-cicd/github-actions/"
        log_info "Copy them to .github/workflows/ in your repository"
    else
        log "Workflow files found in ${WORKFLOWS_DIR}"
    fi
}

# Display summary
display_summary() {
    echo ""
    echo "=========================================="
    echo "GitHub Actions Deployment Complete!"
    echo "=========================================="
    echo ""
    echo "Environment: ${ENVIRONMENT}"
    echo "Repository: https://github.com/${GITHUB_USER}/${GITHUB_REPO}"
    echo ""
    echo "View workflows:"
    echo "  https://github.com/${GITHUB_USER}/${GITHUB_REPO}/actions"
    echo ""
    echo "Useful Commands:"
    echo "  List runs:        gh run list --repo ${GITHUB_USER}/${GITHUB_REPO}"
    echo "  Watch run:        gh run watch <run-id>"
    echo "  View logs:        gh run view <run-id> --log"
    echo "  Cancel run:       gh run cancel <run-id>"
    echo "  Rerun failed:     gh run rerun <run-id>"
    echo "  Trigger workflow: gh workflow run <workflow-file>"
    echo ""
    echo "GitHub CLI Help:"
    echo "  gh run --help"
    echo "  gh workflow --help"
    echo ""
    echo "Automatic Triggers:"
    echo "  - Push to main branch triggers build and test"
    echo "  - Pull requests trigger validation"
    echo "  - Tags (v*) trigger production deployment"
    echo "=========================================="
}

# Main function
main() {
    print_banner
    log "Starting GitHub Actions deployment for environment: ${ENVIRONMENT}"
    
    validate_environment
    check_github_cli
    check_github_token
    create_workflow_files
    
    echo ""
    read -p "Deploy infrastructure? (y/n): " deploy_infra
    if [[ "${deploy_infra}" == "y" ]]; then
        deploy_infrastructure
    fi
    
    echo ""
    read -p "Deploy services? (y/n): " deploy_svc
    if [[ "${deploy_svc}" == "y" ]]; then
        deploy_services
    fi
    
    monitor_workflows
    check_status
    display_summary
    
    log "GitHub Actions deployment workflow initiated!"
}

# Run main
main "$@"
