#!/bin/bash
# Deploy Jenkins Infrastructure with Terraform and Configure with Ansible

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"
ANSIBLE_DIR="${SCRIPT_DIR}/../ansible"
ENV="${1:-dev}"

echo "========================================="
echo "Jenkins Infrastructure Deployment"
echo "Environment: ${ENV}"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    exit 1
fi

if ! command -v ansible &> /dev/null; then
    echo -e "${RED}Error: Ansible is not installed${NC}"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met${NC}"

# Check for SSH key
if [ ! -f "${HOME}/.ssh/jenkins-key.pem" ]; then
    echo -e "\n${YELLOW}SSH key not found. Please ensure you have:${NC}"
    echo "1. Generated an SSH key pair"
    echo "2. Updated the jenkins_ssh_public_key in environments/${ENV}.tfvars"
    echo "3. Saved the private key to ~/.ssh/jenkins-key.pem"
    echo ""
    read -p "Do you have your SSH key ready? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Please set up your SSH key first${NC}"
        exit 1
    fi
fi

# Deploy infrastructure with Terraform
echo -e "\n${YELLOW}Deploying infrastructure with Terraform...${NC}"
cd "${TERRAFORM_DIR}"

terraform init

echo -e "\n${YELLOW}Planning infrastructure changes...${NC}"
terraform plan -var-file="environments/${ENV}.tfvars" -out="${ENV}-jenkins.tfplan"

echo ""
read -p "Do you want to apply these changes? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Applying infrastructure changes...${NC}"
terraform apply "${ENV}-jenkins.tfplan"

# Get Jenkins IP address
echo -e "\n${YELLOW}Retrieving Jenkins IP address...${NC}"
JENKINS_IP=$(terraform output -raw jenkins_public_ip)

if [ -z "${JENKINS_IP}" ]; then
    echo -e "${RED}Error: Could not retrieve Jenkins IP address${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Infrastructure deployed successfully${NC}"
echo -e "Jenkins IP: ${JENKINS_IP}"

# Update Ansible inventory
echo -e "\n${YELLOW}Updating Ansible inventory...${NC}"
cat > "${ANSIBLE_DIR}/inventory/hosts.ini" <<EOF
[jenkins]
jenkins ansible_host=${JENKINS_IP} ansible_user=ec2-user

[jenkins:vars]
ansible_ssh_private_key_file=~/.ssh/jenkins-key.pem
ansible_python_interpreter=/usr/bin/python3
environment=${ENV}
EOF

echo -e "${GREEN}✓ Ansible inventory updated${NC}"

# Wait for EC2 instance to be ready
echo -e "\n${YELLOW}Waiting for EC2 instance to be ready...${NC}"
sleep 30

# Test SSH connection
echo -e "\n${YELLOW}Testing SSH connection...${NC}"
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if ssh -i ~/.ssh/jenkins-key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=10 ec2-user@${JENKINS_IP} "echo 'SSH connection successful'" 2>/dev/null; then
        echo -e "${GREEN}✓ SSH connection established${NC}"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Retry $RETRY_COUNT/$MAX_RETRIES - Waiting for SSH..."
    sleep 10
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}Error: Could not establish SSH connection${NC}"
    exit 1
fi

# Install Ansible collections
echo -e "\n${YELLOW}Installing Ansible collections...${NC}"
cd "${ANSIBLE_DIR}"
ansible-galaxy collection install -r requirements.yml

# Configure Jenkins with Ansible
echo -e "\n${YELLOW}Configuring Jenkins with Ansible...${NC}"
ansible-playbook -i inventory/hosts.ini install-jenkins.yml

echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}Jenkins Deployment Completed!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Jenkins URL: http://${JENKINS_IP}:8080"
echo "SSH Command: ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP}"
echo ""
echo "Initial admin password can be found at:"
echo "/var/lib/jenkins/secrets/initialAdminPassword"
echo ""
echo "Or retrieve it with:"
echo "ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
echo ""
