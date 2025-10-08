# Jenkins Infrastructure Deployment

This directory contains Terraform and Ansible configurations to deploy and configure a Jenkins CI/CD server on AWS.

## Overview

The deployment creates:
- **EC2 Instance**: Amazon Linux 2 instance for Jenkins
- **Security Group**: Configured for SSH (22), Jenkins web (8080), and HTTPS (443)
- **IAM Role**: With permissions for ECR, EKS, S3, Secrets Manager
- **Elastic IP**: Static IP address for Jenkins
- **EBS Volumes**: Root volume (20GB) and data volume (30GB) for Jenkins
- **CloudWatch**: Monitoring and logging
- **SNS Alerts**: For CPU and status check alarms

## Prerequisites

1. **Tools Required**:
   ```bash
   # Terraform >= 1.6.0
   terraform version
   
   # Ansible >= 2.14
   ansible --version
   
   # AWS CLI v2
   aws --version
   ```

2. **AWS Credentials**:
   ```bash
   aws configure
   # Or set environment variables:
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

3. **SSH Key Pair**:
   ```bash
   # Generate SSH key pair
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/jenkins-key -C "jenkins@example.com"
   
   # Set permissions
   chmod 600 ~/.ssh/jenkins-key
   mv ~/.ssh/jenkins-key ~/.ssh/jenkins-key.pem
   
   # Copy public key content
   cat ~/.ssh/jenkins-key.pub
   ```

## Configuration

### Step 1: Update Terraform Variables

Edit `terraform/environments/dev.tfvars`:

```hcl
# Jenkins Configuration
jenkins_instance_type            = "t3.small"  # Free tier eligible
jenkins_root_volume_size         = 20
jenkins_data_volume_size         = 30
jenkins_ssh_public_key           = "ssh-rsa AAAAB3... your-public-key-here"  # Paste your public key
jenkins_allowed_ssh_cidr_blocks  = ["YOUR_IP/32"]  # Restrict to your IP
jenkins_allowed_cidr_blocks      = ["YOUR_IP/32"]  # Restrict to your IP
jenkins_artifacts_bucket         = "devsecops-dev-jenkins-artifacts"
```

**Important Security Notes**:
- Replace `"YOUR_IP/32"` with your actual IP address
- Never use `"0.0.0.0/0"` in production
- Get your IP: `curl ifconfig.me`

### Step 2: Configure Ansible Variables (Optional)

Edit `ansible/install-jenkins.yml` vars section:

```yaml
vars:
  jenkins_version: "2.426.3"
  jenkins_port: 8080
  jenkins_admin_username: "admin"
  jenkins_admin_password: "{{ lookup('env', 'JENKINS_ADMIN_PASSWORD') | default('Admin@123', true) }}"
```

## Deployment

### Option 1: Automated Deployment (Recommended)

Use the all-in-one deployment script:

```bash
cd ansible
./deploy-jenkins.sh dev
```

This script will:
1. ✅ Check prerequisites
2. ✅ Deploy infrastructure with Terraform
3. ✅ Update Ansible inventory
4. ✅ Install Ansible collections
5. ✅ Configure Jenkins with Ansible
6. ✅ Display access information

### Option 2: Manual Deployment

#### Step 1: Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="environments/dev.tfvars" -out=dev-jenkins.tfplan

# Apply changes
terraform apply dev-jenkins.tfplan

# Get outputs
terraform output jenkins_public_ip
terraform output jenkins_url
```

#### Step 2: Update Ansible Inventory

```bash
# Get Jenkins IP
JENKINS_IP=$(cd terraform && terraform output -raw jenkins_public_ip)

# Update inventory
cat > ansible/inventory/hosts.ini <<EOF
[jenkins]
jenkins ansible_host=${JENKINS_IP} ansible_user=ec2-user

[jenkins:vars]
ansible_ssh_private_key_file=~/.ssh/jenkins-key.pem
ansible_python_interpreter=/usr/bin/python3
environment=dev
EOF
```

#### Step 3: Test Connection

```bash
# Wait for instance to be ready
sleep 30

# Test SSH
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP}
```

#### Step 4: Install Ansible Collections

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```

#### Step 5: Run Ansible Playbook

```bash
# Test connectivity
ansible -i inventory/hosts.ini jenkins -m ping

# Deploy Jenkins configuration
ansible-playbook -i inventory/hosts.ini install-jenkins.yml
```

## Accessing Jenkins

### Initial Setup

1. **Get Initial Password**:
   ```bash
   JENKINS_IP=$(cd terraform && terraform output -raw jenkins_public_ip)
   ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} \
     'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
   ```

2. **Open Jenkins**:
   ```bash
   # Open in browser
   echo "http://${JENKINS_IP}:8080"
   ```

3. **Complete Setup Wizard**:
   - Enter initial admin password
   - Install suggested plugins (or use pre-configured plugins)
   - Create admin user
   - Configure Jenkins URL

### Jenkins Plugins Installed

The Ansible playbook installs these essential plugins:

**Source Control**:
- git, github, github-branch-source

**Pipeline**:
- workflow-aggregator, pipeline-stage-view, job-dsl

**Docker & Kubernetes**:
- docker-workflow, docker-plugin
- kubernetes, kubernetes-cli, kubernetes-credentials

**AWS**:
- aws-credentials, amazon-ecr

**DevSecOps**:
- sonarqube-scanner, terraform, ansible

**Configuration**:
- configuration-as-code

**Utilities**:
- credentials-binding, slack, email-ext
- prometheus, blueocean, timestamper

## Infrastructure Details

### Resources Created

| Resource | Type | Details |
|----------|------|---------|
| EC2 Instance | t3.small | 2 vCPU, 2 GB RAM |
| Root Volume | EBS gp3 | 20 GB, encrypted |
| Data Volume | EBS gp3 | 30 GB, encrypted |
| Elastic IP | Public IP | Static IP address |
| Security Group | Firewall | SSH, HTTP, HTTPS |
| IAM Role | Permissions | ECR, EKS, S3, Secrets |
| CloudWatch Logs | Monitoring | 7 days retention |

### Security Configuration

- ✅ IMDSv2 enforced
- ✅ EBS encryption enabled
- ✅ HTTPS/TLS for Jenkins (optional with reverse proxy)
- ✅ Security groups with minimal access
- ✅ IAM role with least privilege
- ✅ CloudWatch monitoring
- ✅ SNS alerts for anomalies

### Cost Estimate (Monthly)

**Free Tier Eligible**:
- EC2 t3.small: ~$15/month
- EBS storage (50GB): ~$5/month
- Elastic IP (attached): Free
- Data transfer (first 1GB): Free

**Total**: ~$20-25/month

## Jenkins Configuration

### Configuration as Code (JCasC)

Jenkins is configured using JCasC at:
```
/var/lib/jenkins/casc_configs/jenkins.yaml
```

To update configuration:
```bash
# Edit configuration
sudo vim /var/lib/jenkins/casc_configs/jenkins.yaml

# Reload configuration (or restart Jenkins)
sudo systemctl restart jenkins
```

### Backup & Restore

**Automated Backups**:
- Daily backups at 2 AM (configured via cron)
- Stored in `/backup/jenkins/`
- Uploaded to S3 bucket
- 30-day retention

**Manual Backup**:
```bash
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP}
sudo /usr/local/bin/jenkins-backup.sh
```

**Restore from Backup**:
```bash
# Stop Jenkins
sudo systemctl stop jenkins

# Extract backup
sudo tar -xzf /backup/jenkins/jenkins_backup_YYYYMMDD_HHMMSS.tar.gz -C /

# Start Jenkins
sudo systemctl start jenkins
```

### Tools Installed

| Tool | Version | Location |
|------|---------|----------|
| Java | 11 (Corretto) | /usr/lib/jvm/java-11-amazon-corretto |
| Docker | Latest | /usr/bin/docker |
| kubectl | 1.28.0 | /usr/local/bin/kubectl |
| AWS CLI | v2 | /usr/local/bin/aws |
| Terraform | 1.6.6 | /usr/local/bin/terraform |
| Helm | v3 | /usr/local/bin/helm |
| Git | Latest | /usr/bin/git |

## Troubleshooting

### Jenkins Won't Start

```bash
# Check service status
sudo systemctl status jenkins

# Check logs
sudo journalctl -u jenkins -f

# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log
```

### Cannot Connect via SSH

```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids <SG_ID>

# Verify SSH key permissions
ls -la ~/.ssh/jenkins-key.pem  # Should be 600

# Test with verbose output
ssh -vvv -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP}
```

### Plugins Not Installing

```bash
# Manual plugin installation
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP}

# Download plugin
cd /var/lib/jenkins/plugins
sudo wget https://updates.jenkins.io/download/plugins/<plugin-name>/latest/<plugin-name>.hpi

# Restart Jenkins
sudo systemctl restart jenkins
```

### High CPU Usage

```bash
# Check running jobs
# Via Jenkins UI: Manage Jenkins > System Information

# Increase JVM memory
sudo vim /etc/sysconfig/jenkins
# Modify: JENKINS_JAVA_OPTIONS="-Xmx4096m -Xms1024m"

sudo systemctl restart jenkins
```

## Maintenance

### Update Jenkins

```bash
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP}

# Update Jenkins
sudo yum update jenkins -y
sudo systemctl restart jenkins
```

### Update Plugins

Via Jenkins UI:
1. Go to **Manage Jenkins > Manage Plugins**
2. Select **Updates** tab
3. Select plugins to update
4. Click **Download now and install after restart**

### Monitor Resources

```bash
# CPU and Memory
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} 'top -bn1 | head -20'

# Disk usage
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} 'df -h'

# Jenkins disk usage
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} 'sudo du -sh /var/lib/jenkins/*'
```

## Cleanup

### Destroy Infrastructure

```bash
cd terraform
terraform destroy -var-file="environments/dev.tfvars"
```

**Warning**: This will delete:
- EC2 instance
- EBS volumes (unless `delete_on_termination = false`)
- Elastic IP
- Security groups
- IAM roles
- CloudWatch logs

## Integration with EKS

Jenkins is configured with IAM permissions to access your EKS cluster:

```bash
# Configure kubectl on Jenkins
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP}
aws eks update-kubeconfig --name devsecops-dev-eks --region us-east-1
kubectl get nodes
```

## Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Configuration as Code](https://github.com/jenkinsci/configuration-as-code-plugin)
- [AWS EC2 Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-best-practices.html)
- [Ansible Documentation](https://docs.ansible.com/)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review CloudWatch logs in AWS Console
3. Check Jenkins system logs
4. Review Terraform/Ansible output

## License

This infrastructure code is part of the DevSecOps project.
