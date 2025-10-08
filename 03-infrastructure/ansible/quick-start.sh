#!/bin/bash
# Quick Start - Generate SSH Key and Deploy Jenkins

set -e

echo "========================================="
echo " Jenkins Quick Start Setup"
echo "========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/jenkins-key.pem ]; then
    echo -e "\n${YELLOW}Step 1: Generating SSH key pair...${NC}"
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/jenkins-key -N "" -C "jenkins@devsecops"
    mv ~/.ssh/jenkins-key ~/.ssh/jenkins-key.pem
    chmod 600 ~/.ssh/jenkins-key.pem
    echo -e "${GREEN}✓ SSH key generated${NC}"
else
    echo -e "\n${GREEN}✓ SSH key already exists${NC}"
fi

# Step 2: Display public key
echo -e "\n${YELLOW}Step 2: Your SSH Public Key:${NC}"
echo -e "${GREEN}$(cat ~/.ssh/jenkins-key.pub)${NC}"
echo ""

# Step 3: Prompt to update tfvars
echo -e "${YELLOW}Step 3: Update Terraform variables${NC}"
TFVARS_FILE="terraform/environments/dev.tfvars"

if [ -f "$TFVARS_FILE" ]; then
    PUBLIC_KEY=$(cat ~/.ssh/jenkins-key.pub)
    
    # Check if jenkins_ssh_public_key exists in the file
    if grep -q "jenkins_ssh_public_key" "$TFVARS_FILE"; then
        echo "Updating jenkins_ssh_public_key in $TFVARS_FILE..."
        
        # Escape special characters in the public key for sed
        ESCAPED_KEY=$(echo "$PUBLIC_KEY" | sed 's/[\/&]/\\&/g')
        
        # Update the public key value
        sed -i "s|jenkins_ssh_public_key.*=.*|jenkins_ssh_public_key = \"$ESCAPED_KEY\"|" "$TFVARS_FILE"
        echo -e "${GREEN}✓ Updated SSH public key in tfvars${NC}"
    else
        echo -e "${YELLOW}Please manually add this line to $TFVARS_FILE:${NC}"
        echo "jenkins_ssh_public_key = \"$PUBLIC_KEY\""
    fi
    
    # Prompt for IP restriction
    echo ""
    echo -e "${YELLOW}For security, restrict access to your IP address${NC}"
    echo "Getting your current IP..."
    MY_IP=$(curl -s ifconfig.me)
    echo "Your IP: $MY_IP"
    echo ""
    read -p "Update security groups to allow only your IP? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sed -i "s|jenkins_allowed_ssh_cidr_blocks.*=.*|jenkins_allowed_ssh_cidr_blocks = [\"$MY_IP/32\"]|" "$TFVARS_FILE"
        sed -i "s|jenkins_allowed_cidr_blocks.*=.*|jenkins_allowed_cidr_blocks = [\"$MY_IP/32\"]|" "$TFVARS_FILE"
        echo -e "${GREEN}✓ Updated security group rules${NC}"
    fi
else
    echo -e "${RED}Error: $TFVARS_FILE not found${NC}"
    exit 1
fi

# Step 4: Review configuration
echo -e "\n${YELLOW}Step 4: Review configuration${NC}"
echo "Jenkins configuration in $TFVARS_FILE:"
grep "jenkins_" "$TFVARS_FILE"

echo ""
read -p "Configuration looks good? Continue with deployment? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled. You can manually run: ./ansible/deploy-jenkins.sh dev${NC}"
    exit 0
fi

# Step 5: Run deployment
echo -e "\n${YELLOW}Step 5: Starting deployment...${NC}"
./ansible/deploy-jenkins.sh dev

echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN} Quick Start Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
