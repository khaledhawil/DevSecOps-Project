#!/bin/bash

# Deploy monitoring stack to Kubernetes cluster
# Usage: ./deploy-monitoring.sh [namespace]

set -e

NAMESPACE=${1:-monitoring}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create namespace
print_info "Creating namespace: ${NAMESPACE}"
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Deploy Prometheus
print_info "Deploying Prometheus..."
kubectl apply -f "${SCRIPT_DIR}/prometheus/rbac.yaml"
kubectl apply -f "${SCRIPT_DIR}/prometheus/configmap.yaml"
kubectl apply -f "${SCRIPT_DIR}/alertmanager/alert-rules.yaml"
kubectl apply -f "${SCRIPT_DIR}/prometheus/deployment.yaml"
kubectl apply -f "${SCRIPT_DIR}/prometheus/service.yaml"

# Deploy AlertManager
print_info "Deploying AlertManager..."
kubectl apply -f "${SCRIPT_DIR}/alertmanager/templates.yaml"
kubectl apply -f "${SCRIPT_DIR}/alertmanager/configmap.yaml"

# Deploy Grafana
print_info "Deploying Grafana..."
kubectl apply -f "${SCRIPT_DIR}/grafana/deployment.yaml"

# Deploy Fluent Bit
print_info "Deploying Fluent Bit..."
kubectl apply -f "${SCRIPT_DIR}/fluent-bit/rbac.yaml"
kubectl apply -f "${SCRIPT_DIR}/fluent-bit/configmap.yaml"
kubectl apply -f "${SCRIPT_DIR}/fluent-bit/daemonset.yaml"

# Wait for deployments
print_info "Waiting for Prometheus to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n ${NAMESPACE}

print_info "Waiting for Grafana to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n ${NAMESPACE}

print_info "Waiting for AlertManager to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/alertmanager -n ${NAMESPACE}

# Print access information
print_info "\n=== Monitoring Stack Deployed Successfully! ==="
print_info "\nAccess URLs (use port-forward):"
echo -e "${GREEN}Prometheus:${NC}"
echo "  kubectl port-forward -n ${NAMESPACE} svc/prometheus 9090:9090"
echo "  http://localhost:9090"
echo ""
echo -e "${GREEN}Grafana:${NC}"
echo "  kubectl port-forward -n ${NAMESPACE} svc/grafana 3000:3000"
echo "  http://localhost:3000"
echo "  Username: admin"
echo "  Password: $(kubectl get secret -n ${NAMESPACE} grafana-admin -o jsonpath='{.data.password}' | base64 -d)"
echo ""
echo -e "${GREEN}AlertManager:${NC}"
echo "  kubectl port-forward -n ${NAMESPACE} svc/alertmanager 9093:9093"
echo "  http://localhost:9093"
echo ""

print_info "\nVerify pods:"
echo "kubectl get pods -n ${NAMESPACE}"
