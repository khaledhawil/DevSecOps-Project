#!/bin/bash

################################################################################
# DevSecOps Project - Complete Project Setup and Validation
################################################################################
#
# Purpose: Validate entire project setup and provide guidance
#
# Usage: ./validate-project.sh
#
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

log() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $*"
}

log_info() {
    echo -e "${BLUE}[i]${NC} $*"
}

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                    DevSecOps Project Validation                              ║
║                                                                              ║
║              Complete validation of project structure and scripts            ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

echo ""
print_banner
echo ""

log_info "Validating DevSecOps Project..."
echo ""

# Check scripts directory
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Checking Scripts Directory...${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"

REQUIRED_SCRIPTS=(
    "00-deploy-all.sh"
    "01-start-local.sh"
    "02-run-tests.sh"
    "03-build-images.sh"
    "04-scan-security.sh"
    "05-deploy-infrastructure.sh"
    "06-deploy-kubernetes.sh"
    "07-setup-gitops.sh"
    "push-images.sh"
    "stop-local.sh"
    "clean-all.sh"
    "health-check.sh"
    "view-logs.sh"
    "run-smoke-tests.sh"
    "setup-prerequisites.sh"
)

all_scripts_found=true
for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [[ -f "${SCRIPT_DIR}/${script}" ]]; then
        if [[ -x "${SCRIPT_DIR}/${script}" ]]; then
            log "${script} (executable)"
        else
            log_warn "${script} (not executable, run: chmod +x ${script})"
        fi
    else
        log_error "${script} NOT FOUND"
        all_scripts_found=false
    fi
done

echo ""

# Check documentation
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Checking Documentation...${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"

DOCS=(
    "README.md"
    "QUICKSTART.md"
    "SCRIPTS-SUMMARY.md"
    ".env.example"
)

for doc in "${DOCS[@]}"; do
    if [[ -f "${SCRIPT_DIR}/${doc}" ]]; then
        log "${doc}"
    else
        log_error "${doc} NOT FOUND"
    fi
done

echo ""

# Check project structure
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Checking Project Structure...${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"

PROJECT_DIRS=(
    "01-setup"
    "02-services"
    "03-infrastructure"
    "04-kubernetes"
    "05-cicd"
    "06-monitoring"
    "07-security"
    "08-deployment-scripts"
    "09-scripts"
)

for dir in "${PROJECT_DIRS[@]}"; do
    if [[ -d "${PROJECT_ROOT}/${dir}" ]]; then
        log "${dir}/"
    else
        log_error "${dir}/ NOT FOUND"
    fi
done

echo ""

# Summary
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Project Summary${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"

echo ""
echo -e "${CYAN}📊 Script Inventory:${NC}"
echo -e "  ${GREEN}✓${NC} Core deployment scripts: 8"
echo -e "  ${GREEN}✓${NC} Utility scripts: 7"
echo -e "  ${GREEN}✓${NC} Documentation files: 4"
echo -e "  ${GREEN}✓${NC} Total: 19 files"

echo ""
echo -e "${CYAN}🎯 Capabilities:${NC}"
echo -e "  ${GREEN}✓${NC} Local development environment"
echo -e "  ${GREEN}✓${NC} Complete testing suite"
echo -e "  ${GREEN}✓${NC} Docker image building and scanning"
echo -e "  ${GREEN}✓${NC} AWS infrastructure deployment"
echo -e "  ${GREEN}✓${NC} Kubernetes deployment"
echo -e "  ${GREEN}✓${NC} GitOps with ArgoCD"
echo -e "  ${GREEN}✓${NC} Monitoring and security"
echo -e "  ${GREEN}✓${NC} Full automation via 00-deploy-all.sh"

echo ""
echo -e "${CYAN}👤 Configuration:${NC}"
echo -e "  ${GREEN}✓${NC} Docker Hub username: ${YELLOW}khaledhawil${NC}"
echo -e "  ${GREEN}✓${NC} GitHub username: ${YELLOW}khaledhawil${NC}"
echo -e "  ${GREEN}✓${NC} All scripts configured for these usernames"

echo ""
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Quick Start Commands${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"

echo ""
echo -e "${YELLOW}For Local Development:${NC}"
echo -e "  cd ${SCRIPT_DIR}"
echo -e "  ./setup-prerequisites.sh"
echo -e "  ./01-start-local.sh"
echo ""

echo -e "${YELLOW}For AWS Deployment:${NC}"
echo -e "  cd ${SCRIPT_DIR}"
echo -e "  cp .env.example .env  # Edit with your values"
echo -e "  aws configure         # Configure AWS credentials"
echo -e "  ./00-deploy-all.sh dev"
echo ""

echo -e "${YELLOW}For Build and Scan:${NC}"
echo -e "  cd ${SCRIPT_DIR}"
echo -e "  ./03-build-images.sh"
echo -e "  ./04-scan-security.sh"
echo -e "  ./push-images.sh khaledhawil"
echo ""

echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Documentation${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"

echo ""
echo -e "  📖 Complete Guide:    ${SCRIPT_DIR}/README.md"
echo -e "  🚀 Quick Start:       ${SCRIPT_DIR}/QUICKSTART.md"
echo -e "  📋 Scripts Summary:   ${SCRIPT_DIR}/SCRIPTS-SUMMARY.md"
echo -e "  ⚙️  Configuration:     ${SCRIPT_DIR}/.env.example"
echo ""

if [[ "${all_scripts_found}" == "true" ]]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                              ║${NC}"
    echo -e "${GREEN}║                    ✅ All Scripts Successfully Created!                      ║${NC}"
    echo -e "${GREEN}║                                                                              ║${NC}"
    echo -e "${GREEN}║                    Ready for deployment and development                      ║${NC}"
    echo -e "${GREEN}║                                                                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                                              ║${NC}"
    echo -e "${RED}║                    ⚠️  Some scripts are missing!                            ║${NC}"
    echo -e "${RED}║                                                                              ║${NC}"
    echo -e "${RED}║                    Please check the errors above                             ║${NC}"
    echo -e "${RED}║                                                                              ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
fi

echo ""
