#!/bin/bash

# Security Scanning Script
# Run all security scans across the platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Scan container images
scan_images() {
    print_info "Scanning container images with Trivy..."
    
    IMAGES=(
        "user-service:latest"
        "auth-service:latest"
        "notification-service:latest"
        "analytics-service:latest"
        "frontend:latest"
    )
    
    for image in "${IMAGES[@]}"; do
        print_info "Scanning $image..."
        trivy image --severity HIGH,CRITICAL "$image" || true
    done
    
    print_success "Image scanning complete"
}

# Check vulnerability reports
check_vuln_reports() {
    print_info "Checking Trivy vulnerability reports..."
    
    kubectl get vulnerabilityreports -A -o json | \
        jq -r '.items[] | select(.report.summary.criticalCount > 0 or .report.summary.highCount > 0) | 
        "\(.metadata.namespace)/\(.metadata.name): Critical: \(.report.summary.criticalCount), High: \(.report.summary.highCount)"'
    
    print_success "Vulnerability report check complete"
}

# Check Gatekeeper violations
check_policy_violations() {
    print_info "Checking Gatekeeper policy violations..."
    
    CONSTRAINTS=$(kubectl get constraints -o name)
    
    for constraint in $CONSTRAINTS; do
        VIOLATIONS=$(kubectl get "$constraint" -o json | jq -r '.status.totalViolations // 0')
        if [ "$VIOLATIONS" -gt 0 ]; then
            print_warning "Policy violations found in $constraint: $VIOLATIONS"
            kubectl get "$constraint" -o json | jq -r '.status.violations[] | "  - \(.message)"'
        fi
    done
    
    print_success "Policy violation check complete"
}

# Check Falco alerts
check_falco_alerts() {
    print_info "Checking recent Falco alerts..."
    
    kubectl logs -n falco -l app=falco --tail=100 | grep -i "priority" || print_info "No recent alerts"
    
    print_success "Falco alert check complete"
}

# Check secret age
check_secret_age() {
    print_info "Checking secret age..."
    
    kubectl get secrets -A -o json | \
        jq -r '.items[] | select(.metadata.creationTimestamp != null) | 
        "\(.metadata.namespace)/\(.metadata.name): \(.metadata.creationTimestamp)"' | \
        while read -r line; do
            SECRET_DATE=$(echo "$line" | awk '{print $2}')
            SECRET_NAME=$(echo "$line" | awk '{print $1}')
            DAYS_OLD=$(( ($(date +%s) - $(date -d "$SECRET_DATE" +%s)) / 86400 ))
            
            if [ $DAYS_OLD -gt 90 ]; then
                print_warning "$SECRET_NAME is $DAYS_OLD days old (consider rotation)"
            fi
        done
    
    print_success "Secret age check complete"
}

# Run config audit
run_config_audit() {
    print_info "Running Kubernetes configuration audit..."
    
    kubectl get configauditreports -A -o json | \
        jq -r '.items[] | select(.report.summary.criticalCount > 0 or .report.summary.highCount > 0) | 
        "\(.metadata.namespace)/\(.metadata.name): Critical: \(.report.summary.criticalCount), High: \(.report.summary.highCount)"'
    
    print_success "Configuration audit complete"
}

# Check RBAC
check_rbac() {
    print_info "Checking RBAC permissions..."
    
    # List cluster admins
    print_info "Cluster admins:"
    kubectl get clusterrolebindings -o json | \
        jq -r '.items[] | select(.roleRef.name == "cluster-admin") | .subjects[]? | "  - \(.kind)/\(.name)"'
    
    # Check for overly permissive roles
    print_info "Checking for wildcard permissions..."
    kubectl get clusterroles -o json | \
        jq -r '.items[] | select(.rules[]? | .resources[]? == "*") | .metadata.name' | \
        while read -r role; do
            print_warning "Role $role has wildcard resource permissions"
        done
    
    print_success "RBAC check complete"
}

# Generate summary report
generate_report() {
    print_info "Generating security summary report..."
    
    REPORT_FILE="security-scan-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "====================================="
        echo "Security Scan Report"
        echo "Generated: $(date)"
        echo "====================================="
        echo ""
        
        echo "1. Vulnerability Summary"
        echo "------------------------"
        kubectl get vulnerabilityreports -A -o json | \
            jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name): Critical: \(.report.summary.criticalCount), High: \(.report.summary.highCount), Medium: \(.report.summary.mediumCount)"'
        echo ""
        
        echo "2. Policy Violations"
        echo "-------------------"
        kubectl get constraints -o json | \
            jq -r '.items[] | "\(.metadata.name): \(.status.totalViolations // 0) violations"'
        echo ""
        
        echo "3. Configuration Issues"
        echo "----------------------"
        kubectl get configauditreports -A -o json | \
            jq -r '.items[] | select(.report.summary.criticalCount > 0 or .report.summary.highCount > 0) | 
            "\(.metadata.namespace)/\(.metadata.name): Critical: \(.report.summary.criticalCount), High: \(.report.summary.highCount)"'
        echo ""
        
        echo "4. Security Recommendations"
        echo "--------------------------"
        echo "- Review and remediate critical vulnerabilities immediately"
        echo "- Fix policy violations before deploying to production"
        echo "- Rotate secrets older than 90 days"
        echo "- Review RBAC permissions regularly"
        echo "- Monitor Falco alerts for runtime threats"
        echo ""
        
    } > "$REPORT_FILE"
    
    print_success "Report generated: $REPORT_FILE"
}

# Main function
main() {
    echo ""
    print_info "========================================="
    print_info "Security Scanning Suite"
    print_info "========================================="
    echo ""
    
    scan_images
    echo ""
    
    check_vuln_reports
    echo ""
    
    check_policy_violations
    echo ""
    
    check_falco_alerts
    echo ""
    
    check_secret_age
    echo ""
    
    run_config_audit
    echo ""
    
    check_rbac
    echo ""
    
    generate_report
    
    echo ""
    print_success "========================================="
    print_success "Security scan complete! 🔍"
    print_success "========================================="
    echo ""
}

# Run main function
main
