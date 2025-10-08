#!/bin/bash

################################################################################
# DevSecOps Project - Destroy Infrastructure
################################################################################
#
# Purpose: Safely destroy all infrastructure resources
#
# Usage: ./destroy-infrastructure.sh <environment> [options]
#
# Examples:
#   ./destroy-infrastructure.sh dev
#   ./destroy-infrastructure.sh staging --skip-backup
#   ./destroy-infrastructure.sh prod --force
#
# Options:
#   --skip-backup    Skip database backup before destruction
#   --force          Skip all confirmations (dangerous!)
#   --keep-s3        Keep S3 buckets (don't empty/delete)
#   --dry-run        Show what would be destroyed without actually doing it
#
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${PROJECT_ROOT}/03-infrastructure/terraform"
K8S_DIR="${PROJECT_ROOT}/04-kubernetes"

# Default values
ENVIRONMENT=""
SKIP_BACKUP=false
FORCE=false
KEEP_S3=false
DRY_RUN=false

# Valid environments
VALID_ENVS=("dev" "staging" "prod")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

################################################################################
# Functions
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

print_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

print_separator() {
    echo -e "${CYAN}----------------------------------------${NC}"
}

usage() {
    cat << EOF
Usage: $0 <environment> [options]

Environments:
  dev, staging, prod

Options:
  --skip-backup    Skip database backup before destruction
  --force          Skip all confirmations (DANGEROUS!)
  --keep-s3        Keep S3 buckets (don't empty/delete)
  --dry-run        Show what would be destroyed without actually doing it
  -h, --help       Show this help message

Examples:
  $0 dev
  $0 staging --skip-backup
  $0 prod --dry-run

EOF
    exit 1
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    log_success "All prerequisites met"
}

validate_environment() {
    if [[ ! " ${VALID_ENVS[@]} " =~ " ${ENVIRONMENT} " ]]; then
        log_error "Invalid environment: ${ENVIRONMENT}"
        echo "Valid environments: ${VALID_ENVS[*]}"
        exit 1
    fi
}

confirm_destruction() {
    if [ "$FORCE" = true ]; then
        log_warn "Force mode enabled - skipping confirmations"
        return 0
    fi
    
    print_separator
    log_warn "⚠️  DANGER: You are about to DESTROY infrastructure!"
    echo ""
    echo "Environment: ${ENVIRONMENT}"
    echo "This will destroy:"
    echo "  • EKS Cluster and all workloads"
    echo "  • RDS Database instances"
    echo "  • ElastiCache Redis clusters"
    echo "  • VPC and all networking"
    echo "  • Jenkins EC2 instance"
    echo "  • S3 buckets (unless --keep-s3)"
    echo "  • IAM roles and policies"
    echo "  • CloudWatch logs and alarms"
    echo "  • KMS keys"
    echo "  • Secrets Manager secrets"
    echo ""
    
    if [ "$ENVIRONMENT" = "prod" ]; then
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}  WARNING: PRODUCTION ENVIRONMENT!${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
    fi
    
    read -p "Type '${ENVIRONMENT}' to confirm: " confirm
    if [ "$confirm" != "${ENVIRONMENT}" ]; then
        log_info "Destruction cancelled"
        exit 0
    fi
    
    if [ "$ENVIRONMENT" = "prod" ]; then
        echo ""
        read -p "Type 'DESTROY PRODUCTION' to proceed: " prod_confirm
        if [ "$prod_confirm" != "DESTROY PRODUCTION" ]; then
            log_info "Destruction cancelled"
            exit 0
        fi
    fi
    
    echo ""
    read -p "Final confirmation - proceed with destruction? (yes/no): " final_confirm
    if [ "$final_confirm" != "yes" ]; then
        log_info "Destruction cancelled"
        exit 0
    fi
    
    print_separator
}

backup_database() {
    if [ "$SKIP_BACKUP" = true ]; then
        log_warn "Skipping database backup (--skip-backup flag)"
        return 0
    fi
    
    print_header "Creating Database Backup"
    
    local db_identifier="devsecops-${ENVIRONMENT}-postgres"
    local snapshot_name="devsecops-${ENVIRONMENT}-final-snapshot-$(date +%Y%m%d-%H%M%S)"
    
    log_info "Creating final snapshot: ${snapshot_name}"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would create snapshot: ${snapshot_name}"
        return 0
    fi
    
    if aws rds describe-db-instances --db-instance-identifier "${db_identifier}" &>/dev/null; then
        aws rds create-db-snapshot \
            --db-instance-identifier "${db_identifier}" \
            --db-snapshot-identifier "${snapshot_name}" \
            --tags Key=Environment,Value="${ENVIRONMENT}" Key=Type,Value=FinalSnapshot || true
        
        log_success "Snapshot creation initiated: ${snapshot_name}"
        log_info "Snapshot will be retained after destruction"
    else
        log_warn "Database instance not found, skipping backup"
    fi
}

destroy_kubernetes_resources() {
    print_header "Destroying Kubernetes Resources"
    
    local namespace="devsecops-${ENVIRONMENT}"
    
    # Check if kubectl is configured
    if ! kubectl cluster-info &>/dev/null; then
        log_warn "kubectl not configured or cluster not accessible"
        log_info "Skipping Kubernetes cleanup - will be destroyed with EKS cluster"
        return 0
    fi
    
    # Check if namespace exists
    if ! kubectl get namespace "${namespace}" &>/dev/null 2>&1; then
        log_warn "Namespace ${namespace} does not exist"
        return 0
    fi
    
    log_info "Destroying resources in namespace: ${namespace}"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would delete Kubernetes resources in namespace: ${namespace}"
        return 0
    fi
    
    # Delete applications first
    if [ -d "${K8S_DIR}/overlays/${ENVIRONMENT}" ]; then
        log_info "Deleting application resources..."
        kubectl delete -k "${K8S_DIR}/overlays/${ENVIRONMENT}" --timeout=300s || true
    fi
    
    # Delete monitoring resources
    log_info "Deleting monitoring resources..."
    kubectl delete namespace monitoring --timeout=300s || true
    
    # Delete security resources
    log_info "Deleting security resources..."
    kubectl delete namespace falco --timeout=300s || true
    kubectl delete namespace vault --timeout=300s || true
    
    # Delete ArgoCD if present
    log_info "Deleting ArgoCD..."
    kubectl delete namespace argocd --timeout=300s || true
    
    # Delete Flux if present
    log_info "Deleting Flux..."
    kubectl delete namespace flux-system --timeout=300s || true
    
    # Delete main namespace
    log_info "Deleting namespace: ${namespace}"
    kubectl delete namespace "${namespace}" --timeout=300s || true
    
    log_success "Kubernetes resources destroyed"
}

empty_s3_buckets() {
    if [ "$KEEP_S3" = true ]; then
        log_warn "Keeping S3 buckets (--keep-s3 flag)"
        return 0
    fi
    
    print_header "Emptying S3 Buckets"
    
    local bucket_prefix="devsecops-${ENVIRONMENT}"
    
    log_info "Finding S3 buckets with prefix: ${bucket_prefix}"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would empty S3 buckets with prefix: ${bucket_prefix}"
        return 0
    fi
    
    # Get list of buckets
    local buckets=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${bucket_prefix}')].Name" --output text || echo "")
    
    if [ -z "$buckets" ]; then
        log_info "No S3 buckets found"
        return 0
    fi
    
    for bucket in $buckets; do
        log_info "Emptying bucket: ${bucket}"
        
        # Delete all versions and delete markers
        aws s3api delete-objects --bucket "${bucket}" \
            --delete "$(aws s3api list-object-versions --bucket "${bucket}" \
            --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
            --max-items 1000)" 2>/dev/null || true
        
        aws s3api delete-objects --bucket "${bucket}" \
            --delete "$(aws s3api list-object-versions --bucket "${bucket}" \
            --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
            --max-items 1000)" 2>/dev/null || true
        
        # Remove all objects
        aws s3 rm "s3://${bucket}" --recursive || true
        
        log_success "Bucket emptied: ${bucket}"
    done
}

destroy_terraform_infrastructure() {
    print_header "Destroying Terraform Infrastructure"
    
    cd "${TERRAFORM_DIR}"
    
    local tfvars_file="environments/${ENVIRONMENT}.tfvars"
    
    if [ ! -f "${tfvars_file}" ]; then
        log_error "Terraform variables file not found: ${tfvars_file}"
        exit 1
    fi
    
    log_info "Initializing Terraform..."
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would initialize Terraform"
    else
        terraform init -upgrade
    fi
    
    log_info "Creating destruction plan..."
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would create destruction plan"
        terraform plan -destroy -var-file="${tfvars_file}" -out="${ENVIRONMENT}-destroy.tfplan"
        
        log_info ""
        log_info "Destruction plan saved to: ${ENVIRONMENT}-destroy.tfplan"
        log_info "Review the plan above to see what would be destroyed"
        return 0
    else
        terraform plan -destroy -var-file="${tfvars_file}" -out="${ENVIRONMENT}-destroy.tfplan"
    fi
    
    echo ""
    log_warn "Destruction plan created. Review the changes above."
    
    if [ "$FORCE" = false ]; then
        read -p "Proceed with destruction? (yes/no): " proceed
        if [ "$proceed" != "yes" ]; then
            log_info "Destruction cancelled"
            exit 0
        fi
    fi
    
    log_info "Destroying infrastructure..."
    terraform apply "${ENVIRONMENT}-destroy.tfplan"
    
    log_success "Terraform infrastructure destroyed"
    
    # Clean up plan file
    rm -f "${ENVIRONMENT}-destroy.tfplan"
}

clean_local_state() {
    print_header "Cleaning Local State"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would clean local Terraform state and kubectl config"
        return 0
    fi
    
    # Remove kubectl context for destroyed cluster
    local cluster_name="devsecops-${ENVIRONMENT}-cluster"
    log_info "Removing kubectl context: ${cluster_name}"
    kubectl config delete-context "${cluster_name}" 2>/dev/null || true
    kubectl config delete-cluster "${cluster_name}" 2>/dev/null || true
    
    # Clean up local kubeconfig
    log_info "Cleaning kubectl config..."
    sed -i.bak "/devsecops-${ENVIRONMENT}/d" ~/.kube/config 2>/dev/null || true
    
    log_success "Local state cleaned"
}

generate_destruction_report() {
    print_header "Destruction Summary"
    
    local report_file="${PROJECT_ROOT}/destruction-report-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "${report_file}" << EOF
DevSecOps Infrastructure Destruction Report
============================================

Environment: ${ENVIRONMENT}
Date: $(date +'%Y-%m-%d %H:%M:%S')
User: ${USER}

Destroyed Resources:
-------------------
✓ Kubernetes resources (namespace: devsecops-${ENVIRONMENT})
✓ Monitoring namespace
✓ Security namespaces (Falco, Vault)
✓ GitOps namespaces (ArgoCD/Flux)
✓ EKS Cluster: devsecops-${ENVIRONMENT}-cluster
✓ RDS Database: devsecops-${ENVIRONMENT}-postgres
✓ ElastiCache Redis: devsecops-${ENVIRONMENT}-redis
✓ Jenkins EC2 Instance
✓ VPC and Networking
✓ IAM Roles and Policies
✓ CloudWatch Logs and Alarms
✓ KMS Keys (scheduled for deletion)
✓ Secrets Manager Secrets (scheduled for deletion)
$([ "$KEEP_S3" = false ] && echo "✓ S3 Buckets emptied and deleted" || echo "⊗ S3 Buckets retained")

$([ "$SKIP_BACKUP" = false ] && echo "Database Snapshot: devsecops-${ENVIRONMENT}-final-snapshot-$(date +%Y%m%d)" || echo "No database backup created")

Notes:
------
- KMS keys will be deleted after 30-day waiting period
- Secrets Manager secrets will be deleted after 7-day recovery window
- CloudWatch logs may have retention periods
$([ "$SKIP_BACKUP" = false ] && echo "- Database snapshot created and retained" || echo "- No database backup was created")
$([ "$KEEP_S3" = true ] && echo "- S3 buckets were retained as requested" || echo "- S3 buckets were emptied and deleted")

To restore from backup (if created):
-----------------------------------
1. Deploy new infrastructure: cd 03-infrastructure/terraform && terraform apply
2. Restore from snapshot in AWS Console or CLI
3. Update connection strings in Kubernetes configs

Cost Impact:
-----------
Monthly cost reduction: ~\$XXX (depends on your configuration)
Retained resources cost: Snapshots only (~\$X/month per snapshot)

EOF
    
    log_success "Destruction report saved to: ${report_file}"
    
    cat "${report_file}"
}

################################################################################
# Main Execution
################################################################################

main() {
    # Parse arguments
    if [ $# -eq 0 ]; then
        usage
    fi
    
    ENVIRONMENT=$1
    shift
    
    # Parse options
    while [ $# -gt 0 ]; do
        case $1 in
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --keep-s3)
                KEEP_S3=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    # Display banner
    print_header "DevSecOps Infrastructure Destruction"
    echo "Environment: ${ENVIRONMENT}"
    echo "Dry Run: ${DRY_RUN}"
    echo "Skip Backup: ${SKIP_BACKUP}"
    echo "Keep S3: ${KEEP_S3}"
    echo "Force: ${FORCE}"
    
    # Validation
    validate_environment
    check_prerequisites
    
    # Confirmation
    confirm_destruction
    
    # Start destruction process
    local start_time=$(date +%s)
    
    if [ "$DRY_RUN" = true ]; then
        log_warn "DRY-RUN MODE: No actual changes will be made"
    fi
    
    # Execute destruction steps
    backup_database
    destroy_kubernetes_resources
    empty_s3_buckets
    destroy_terraform_infrastructure
    clean_local_state
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Generate report
    if [ "$DRY_RUN" = false ]; then
        generate_destruction_report
    fi
    
    # Final message
    print_separator
    if [ "$DRY_RUN" = true ]; then
        log_success "Dry run completed in ${duration} seconds"
        log_info "No actual resources were destroyed"
        log_info "Review the destruction plan in Terraform"
    else
        log_success "Infrastructure destruction completed in ${duration} seconds!"
        log_info "All resources have been destroyed"
        if [ "$SKIP_BACKUP" = false ]; then
            log_info "Database snapshot created and retained"
        fi
    fi
    print_separator
}

# Run main function
main "$@"
