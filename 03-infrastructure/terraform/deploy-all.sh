#!/bin/bash
# Complete Infrastructure Deployment - Including Jenkins

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV="${1:-dev}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════╗
║   DevSecOps Infrastructure Deployment       ║
║   VPC + EKS + RDS + Redis + Jenkins         ║
╚══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${YELLOW}Environment: ${ENV}${NC}\n"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not installed${NC}"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not installed${NC}"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}\n"

# Display what will be deployed
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}  Infrastructure Components${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}✓${NC} VPC with public/private subnets"
echo -e "  ${GREEN}✓${NC} EKS Kubernetes cluster (v1.28)"
echo -e "  ${GREEN}✓${NC} RDS PostgreSQL (db.t4g.micro)"
echo -e "  ${GREEN}✓${NC} ElastiCache Redis (cache.t4g.micro)"
echo -e "  ${GREEN}✓${NC} Jenkins EC2 (t3.small)"
echo -e "  ${GREEN}✓${NC} IAM roles and policies"
echo -e "  ${GREEN}✓${NC} Security groups and networking"
echo -e "  ${GREEN}✓${NC} CloudWatch monitoring and alarms"
echo -e "  ${GREEN}✓${NC} Auto-generated SSH keys for Jenkins"
echo ""
echo -e "${YELLOW}Estimated deployment time:${NC} 15-20 minutes"
echo -e "${YELLOW}Estimated monthly cost:${NC} ~\$200-220"
echo ""

# Confirm deployment
read -p "$(echo -e ${YELLOW}Continue with deployment? [y/N]:${NC} )" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 0
fi

echo ""

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init

# Validate configuration
echo -e "\n${YELLOW}Validating configuration...${NC}"
terraform validate
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Configuration validation failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Configuration valid${NC}"

# Create plan
echo -e "\n${YELLOW}Creating deployment plan...${NC}"
terraform plan -var-file="environments/${ENV}.tfvars" -out="${ENV}.tfplan"

# Show plan summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}  Deployment Plan Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
terraform show -no-color "${ENV}.tfplan" | grep -E "Plan:|No changes"

# Final confirmation
echo ""
read -p "$(echo -e ${YELLOW}Apply this plan? [y/N]:${NC} )" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Deployment cancelled${NC}"
    rm -f "${ENV}.tfplan"
    exit 0
fi

# Apply plan
echo ""
echo -e "${GREEN}Starting deployment...${NC}"
echo -e "${YELLOW}This will take approximately 15-20 minutes${NC}\n"

START_TIME=$(date +%s)

terraform apply "${ENV}.tfplan"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# Success message
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                              ║${NC}"
echo -e "${GREEN}║   ✅ Deployment Completed Successfully!      ║${NC}"
echo -e "${GREEN}║                                              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Deployment time: ${MINUTES}m ${SECONDS}s${NC}"
echo ""

# Display outputs
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}  Access Information${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

JENKINS_IP=$(terraform output -raw jenkins_public_ip 2>/dev/null || echo "N/A")
JENKINS_URL=$(terraform output -raw jenkins_url 2>/dev/null || echo "N/A")
EKS_CLUSTER=$(terraform output -raw eks_cluster_name 2>/dev/null || echo "N/A")
RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null || echo "N/A")
REDIS_ENDPOINT=$(terraform output -raw redis_primary_endpoint 2>/dev/null || echo "N/A")

echo -e "${GREEN}Jenkins:${NC}"
echo -e "  URL: ${JENKINS_URL}"
echo -e "  IP:  ${JENKINS_IP}"
echo -e "  SSH: ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP}"
echo ""
echo -e "${GREEN}EKS Cluster:${NC} ${EKS_CLUSTER}"
echo -e "${GREEN}RDS Database:${NC} ${RDS_ENDPOINT}"
echo -e "${GREEN}Redis Cache:${NC} ${REDIS_ENDPOINT}"
echo ""

# Jenkins setup instructions
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}  Next Steps${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}1. Wait for Jenkins to boot (2-3 minutes)${NC}"
echo "   sleep 180"
echo ""
echo -e "${YELLOW}2. Get Jenkins initial admin password:${NC}"
echo "   ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} \\"
echo "     'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
echo ""
echo -e "${YELLOW}3. Access Jenkins:${NC}"
echo "   Open: ${JENKINS_URL}"
echo ""
echo -e "${YELLOW}4. (Optional) Configure Jenkins with Ansible:${NC}"
echo "   cd ../ansible"
echo "   # Update inventory with Jenkins IP"
echo "   # Then run: ansible-playbook -i inventory/hosts.ini install-jenkins.yml"
echo ""
echo -e "${YELLOW}5. Configure kubectl for EKS:${NC}"
echo "   aws eks update-kubeconfig --name ${EKS_CLUSTER} --region us-east-1"
echo ""

# Save outputs to file
OUTPUT_FILE="../deployment-info-${ENV}.txt"
cat > "${OUTPUT_FILE}" <<EOL
DevSecOps Infrastructure - Deployment Information
==================================================
Environment: ${ENV}
Deployed: $(date)
Duration: ${MINUTES}m ${SECONDS}s

Access Information:
-------------------
Jenkins URL: ${JENKINS_URL}
Jenkins IP: ${JENKINS_IP}
Jenkins SSH: ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP}

EKS Cluster: ${EKS_CLUSTER}
RDS Endpoint: ${RDS_ENDPOINT}
Redis Endpoint: ${REDIS_ENDPOINT}

SSH Key Location: ~/.ssh/jenkins-key.pem

Initial Admin Password:
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'

Configure kubectl:
aws eks update-kubeconfig --name ${EKS_CLUSTER} --region us-east-1

EOL

echo -e "${GREEN}✅ Deployment info saved to: ${OUTPUT_FILE}${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 Happy DevOps!${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
