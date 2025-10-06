#!/bin/bash

# Push all service images to ECR
# Usage: ./push-all.sh [tag] [aws-account-id] [region]

set -e

TAG=${1:-latest}
AWS_ACCOUNT_ID=${2:-}
AWS_REGION=${3:-us-east-1}

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check AWS account ID
if [ -z "$AWS_ACCOUNT_ID" ]; then
    print_error "AWS Account ID is required"
    echo "Usage: ./push-all.sh [tag] [aws-account-id] [region]"
    exit 1
fi

# Services to push
SERVICES=("user-service" "auth-service" "notification-service" "analytics-service" "frontend")

# Login to ECR
print_info "Logging in to Amazon ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

print_info "Pushing all services with tag: ${TAG}"

for SERVICE in "${SERVICES[@]}"; do
    print_info "Pushing ${SERVICE}..."
    
    ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${SERVICE}"
    
    # Tag image
    docker tag ${SERVICE}:${TAG} ${ECR_REPO}:${TAG}
    
    # Push image
    docker push ${ECR_REPO}:${TAG}
    
    print_info "${SERVICE} pushed successfully to ${ECR_REPO}:${TAG}"
done

print_info "All services pushed successfully!"
