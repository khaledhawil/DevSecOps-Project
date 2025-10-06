#!/bin/bash

#######################################
# Deploy with Jenkins
# Author: DevSecOps Team
# Description: Trigger and monitor Jenkins pipelines for deployment
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
LOG_FILE="${LOG_DIR}/deploy-with-jenkins.log"
ENVIRONMENT="${1:-dev}"
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_NAMESPACE="jenkins"

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
║               Deploy with Jenkins                                ║
║                                                                  ║
║  Trigger and monitor Jenkins CI/CD pipelines                     ║
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

# Check if Jenkins is installed
check_jenkins() {
    log "Checking Jenkins installation..."
    
    if ! kubectl get namespace "${JENKINS_NAMESPACE}" &> /dev/null; then
        log_error "Jenkins namespace not found"
        log_info "Run: ./08-setup-jenkins.sh"
        exit 1
    fi
    
    if ! kubectl get pods -n "${JENKINS_NAMESPACE}" -l app.kubernetes.io/component=jenkins-controller &> /dev/null; then
        log_error "Jenkins controller not found"
        log_info "Run: ./08-setup-jenkins.sh"
        exit 1
    fi
    
    log "Jenkins is installed"
}

# Get Jenkins credentials
get_jenkins_credentials() {
    log "Retrieving Jenkins credentials..."
    
    JENKINS_USER=$(kubectl get secret jenkins-admin-credentials \
        -n "${JENKINS_NAMESPACE}" \
        -o jsonpath="{.data.jenkins-admin-user}" 2>/dev/null | base64 --decode || echo "admin")
    
    JENKINS_PASSWORD=$(kubectl get secret jenkins-admin-credentials \
        -n "${JENKINS_NAMESPACE}" \
        -o jsonpath="{.data.jenkins-admin-password}" 2>/dev/null | base64 --decode || echo "")
    
    if [ -z "${JENKINS_PASSWORD}" ]; then
        log_error "Failed to retrieve Jenkins password"
        log_info "Get password manually: kubectl get secret jenkins-admin-credentials -n jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 -d"
        exit 1
    fi
    
    log "Jenkins credentials retrieved"
}

# Setup port forward to Jenkins
setup_port_forward() {
    log "Setting up port forward to Jenkins..."
    
    # Kill any existing port forwards
    pkill -f "port-forward.*jenkins" || true
    sleep 2
    
    # Create new port forward in background
    kubectl port-forward svc/jenkins \
        -n "${JENKINS_NAMESPACE}" \
        8080:8080 > /dev/null 2>&1 &
    
    local PF_PID=$!
    echo "${PF_PID}" > "${LOG_DIR}/jenkins-port-forward.pid"
    
    # Wait for port forward to be ready
    sleep 5
    
    if ! curl -s http://localhost:8080 > /dev/null; then
        log_warning "Port forward may not be ready yet"
    fi
    
    JENKINS_URL="http://localhost:8080"
    log "Port forward established: ${JENKINS_URL}"
}

# Get Jenkins crumb for CSRF protection
get_jenkins_crumb() {
    log "Getting Jenkins crumb..."
    
    JENKINS_CRUMB=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
        "${JENKINS_URL}/crumbIssuer/api/json" | \
        grep -o '"crumb":"[^"]*"' | \
        cut -d'"' -f4)
    
    if [ -z "${JENKINS_CRUMB}" ]; then
        log_warning "Failed to get Jenkins crumb (CSRF might be disabled)"
        JENKINS_CRUMB=""
    fi
}

# Create Jenkins jobs
create_jenkins_jobs() {
    log "Creating Jenkins jobs..."
    
    local SERVICES=("frontend" "auth-service" "user-service" "analytics-service" "notification-service")
    
    for service in "${SERVICES[@]}"; do
        log_info "Creating job for ${service}..."
        
        local JOB_CONFIG=$(cat <<EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <description>Build and deploy ${service}</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>ENVIRONMENT</name>
          <defaultValue>${ENVIRONMENT}</defaultValue>
          <description>Target environment</description>
        </hudson.model.StringParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>IMAGE_TAG</name>
          <defaultValue>latest</defaultValue>
          <description>Docker image tag</description>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.90">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.2">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/khaledhawil/devsecops-project.git</url>
          <credentialsId>github-creds</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
)
        
        # Create job via Jenkins API
        curl -s -X POST \
            -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
            -H "Jenkins-Crumb:${JENKINS_CRUMB}" \
            -H "Content-Type: application/xml" \
            --data "${JOB_CONFIG}" \
            "${JENKINS_URL}/createItem?name=${service}-${ENVIRONMENT}" || true
    done
    
    log "Jenkins jobs created"
}

# Trigger Jenkins job
trigger_jenkins_job() {
    local job_name=$1
    
    log_info "Triggering Jenkins job: ${job_name}"
    
    local BUILD_URL=$(curl -s -X POST \
        -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
        -H "Jenkins-Crumb:${JENKINS_CRUMB}" \
        "${JENKINS_URL}/job/${job_name}/buildWithParameters?ENVIRONMENT=${ENVIRONMENT}" \
        -D - | grep -i "^Location:" | cut -d' ' -f2 | tr -d '\r')
    
    if [ -n "${BUILD_URL}" ]; then
        log "Build triggered: ${BUILD_URL}"
        echo "${BUILD_URL}" >> "${LOG_DIR}/jenkins-builds.txt"
    else
        log_error "Failed to trigger job: ${job_name}"
        return 1
    fi
}

# Wait for Jenkins job
wait_for_jenkins_job() {
    local job_name=$1
    local timeout=600
    local elapsed=0
    
    log_info "Waiting for job to complete: ${job_name}"
    
    while [ $elapsed -lt $timeout ]; do
        local result=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
            "${JENKINS_URL}/job/${job_name}/lastBuild/api/json" | \
            grep -o '"result":"[^"]*"' | cut -d'"' -f4 || echo "")
        
        if [ "${result}" == "SUCCESS" ]; then
            log "Job completed successfully: ${job_name}"
            return 0
        elif [ "${result}" == "FAILURE" ]; then
            log_error "Job failed: ${job_name}"
            return 1
        elif [ "${result}" == "ABORTED" ]; then
            log_warning "Job aborted: ${job_name}"
            return 1
        fi
        
        echo -n "."
        sleep 10
        elapsed=$((elapsed + 10))
    done
    
    log_warning "Job timeout: ${job_name}"
    return 1
}

# Deploy services
deploy_services() {
    log "Deploying services via Jenkins..."
    
    local SERVICES=("frontend" "auth-service" "user-service" "analytics-service" "notification-service")
    
    for service in "${SERVICES[@]}"; do
        local job_name="${service}-${ENVIRONMENT}"
        
        log_info "Deploying ${service}..."
        trigger_jenkins_job "${job_name}"
        
        # Wait a bit before triggering next job
        sleep 5
    done
    
    log "All Jenkins jobs triggered"
}

# Check build status
check_build_status() {
    log "Checking Jenkins build status..."
    
    echo ""
    echo "Recent Builds:"
    
    local SERVICES=("frontend" "auth-service" "user-service" "analytics-service" "notification-service")
    
    for service in "${SERVICES[@]}"; do
        local job_name="${service}-${ENVIRONMENT}"
        
        local build_info=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
            "${JENKINS_URL}/job/${job_name}/lastBuild/api/json" 2>/dev/null || echo "")
        
        if [ -n "${build_info}" ]; then
            local build_number=$(echo "${build_info}" | grep -o '"number":[0-9]*' | cut -d':' -f2 || echo "N/A")
            local result=$(echo "${build_info}" | grep -o '"result":"[^"]*"' | cut -d'"' -f4 || echo "IN_PROGRESS")
            
            echo "  ${job_name}: Build #${build_number} - ${result}"
        else
            echo "  ${job_name}: No builds found"
        fi
    done
}

# View build logs
view_build_logs() {
    local job_name=$1
    
    log_info "Fetching logs for: ${job_name}"
    
    curl -s -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
        "${JENKINS_URL}/job/${job_name}/lastBuild/consoleText"
}

# Cleanup port forward
cleanup() {
    if [ -f "${LOG_DIR}/jenkins-port-forward.pid" ]; then
        local PF_PID=$(cat "${LOG_DIR}/jenkins-port-forward.pid")
        kill "${PF_PID}" 2>/dev/null || true
        rm -f "${LOG_DIR}/jenkins-port-forward.pid"
    fi
}

# Display summary
display_summary() {
    echo ""
    echo "=========================================="
    echo "Jenkins Deployment Complete!"
    echo "=========================================="
    echo ""
    echo "Environment: ${ENVIRONMENT}"
    echo "Jenkins URL: ${JENKINS_URL}"
    echo "Username: ${JENKINS_USER}"
    echo ""
    echo "Access Jenkins UI:"
    echo "  URL: ${JENKINS_URL}"
    echo "  Or: kubectl port-forward svc/jenkins -n jenkins 8080:8080"
    echo ""
    echo "Useful Commands:"
    echo "  View jobs:        curl -u user:pass ${JENKINS_URL}/api/json"
    echo "  Trigger build:    curl -X POST -u user:pass ${JENKINS_URL}/job/<name>/build"
    echo "  View logs:        curl -u user:pass ${JENKINS_URL}/job/<name>/lastBuild/consoleText"
    echo "  Build status:     curl -u user:pass ${JENKINS_URL}/job/<name>/lastBuild/api/json"
    echo ""
    echo "Jenkins CLI:"
    echo "  Download: wget ${JENKINS_URL}/jnlpJars/jenkins-cli.jar"
    echo "  Usage: java -jar jenkins-cli.jar -s ${JENKINS_URL} -auth user:pass <command>"
    echo ""
    echo "Build Triggers:"
    echo "  - Manual trigger via UI or API"
    echo "  - GitHub webhook on push"
    echo "  - Scheduled builds (cron)"
    echo "  - Parameterized builds"
    echo "=========================================="
}

# Main function
main() {
    print_banner
    log "Starting Jenkins deployment for environment: ${ENVIRONMENT}"
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    validate_environment
    check_jenkins
    get_jenkins_credentials
    setup_port_forward
    get_jenkins_crumb
    
    echo ""
    read -p "Create/update Jenkins jobs? (y/n): " create_jobs
    if [[ "${create_jobs}" == "y" ]]; then
        create_jenkins_jobs
    fi
    
    echo ""
    read -p "Trigger deployment builds? (y/n): " deploy_builds
    if [[ "${deploy_builds}" == "y" ]]; then
        deploy_services
    fi
    
    check_build_status
    display_summary
    
    log "Jenkins deployment workflow completed!"
    log "Port forward is still active. Press Ctrl+C to stop."
    
    # Keep script running to maintain port forward
    read -p "Press Enter to cleanup and exit..."
}

# Run main
main "$@"
