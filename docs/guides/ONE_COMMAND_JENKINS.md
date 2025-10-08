# 🚀 One-Command Jenkins Deployment

## ✨ What's New

Jenkins is now **fully integrated** into the main Terraform deployment! No manual SSH key setup required - everything is automated.

## 🎯 Single Command Deployment

```bash
cd 03-infrastructure/terraform
terraform apply -var-file="environments/dev.tfvars"
```

That's it! This single command will deploy:
- ✅ VPC, Subnets, Security Groups
- ✅ EKS Cluster with nodes
- ✅ RDS PostgreSQL database
- ✅ ElastiCache Redis
- ✅ **Jenkins EC2 instance with auto-generated SSH keys**
- ✅ All IAM roles, KMS keys, CloudWatch monitoring

## 🔑 SSH Key Auto-Generation

The Jenkins module now **automatically generates** SSH key pairs using Terraform:

- **Private key**: Saved to `~/.ssh/jenkins-key.pem` (600 permissions)
- **Public key**: Saved to `~/.ssh/jenkins-key.pub` (644 permissions)
- **AWS Key Pair**: Automatically created and attached to EC2

No manual key generation needed!

## 📋 Deployment Steps

### 1. Configure Your Environment (Optional)

Edit `environments/dev.tfvars` to customize:

```hcl
# Restrict access to your IP for security
jenkins_allowed_ssh_cidr_blocks = ["YOUR_IP/32"]
jenkins_allowed_cidr_blocks = ["YOUR_IP/32"]

# Get your IP
# curl ifconfig.me
```

### 2. Deploy Everything

```bash
cd 03-infrastructure/terraform

# Review what will be created
terraform plan -var-file="environments/dev.tfvars"

# Deploy all infrastructure
terraform apply -var-file="environments/dev.tfvars"
```

**Expected time**: 15-20 minutes

### 3. Get Jenkins Access Info

After deployment completes:

```bash
# View all outputs including Jenkins info
terraform output

# Get Jenkins URL
terraform output jenkins_url

# Get SSH command
terraform output jenkins_ssh_command

# View complete setup instructions
terraform output jenkins_setup_complete
```

### 4. Access Jenkins

```bash
# Get Jenkins IP
JENKINS_IP=$(terraform output -raw jenkins_public_ip)

# Wait for instance to boot (2-3 minutes)
sleep 180

# Get initial admin password
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} \
  'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'

# Open in browser
echo "http://${JENKINS_IP}:8080"
```

### 5. Configure Jenkins with Ansible (Optional but Recommended)

For full Jenkins setup with plugins, tools, and configuration:

```bash
cd ../ansible

# Update inventory with Jenkins IP
JENKINS_IP=$(cd ../terraform && terraform output -raw jenkins_public_ip)
cat > inventory/hosts.ini <<EOF
[jenkins]
jenkins ansible_host=${JENKINS_IP} ansible_user=ec2-user

[jenkins:vars]
ansible_ssh_private_key_file=~/.ssh/jenkins-key.pem
ansible_python_interpreter=/usr/bin/python3
environment=dev
EOF

# Install Ansible collections
ansible-galaxy collection install -r requirements.yml

# Run playbook
ansible-playbook -i inventory/hosts.ini install-jenkins.yml
```

**This installs**:
- Java 11, Docker, Git
- Jenkins with 25+ essential plugins
- kubectl, AWS CLI, Terraform, Helm
- Configuration as Code (JCasC)
- Automated backups

## 🎁 What You Get

### Infrastructure Resources

| Component | Details |
|-----------|---------|
| **VPC** | 10.0.0.0/16 with public/private subnets |
| **EKS** | Kubernetes 1.28 cluster |
| **RDS** | PostgreSQL 15.7 (db.t4g.micro) |
| **ElastiCache** | Redis 7.0 (cache.t4g.micro) |
| **Jenkins EC2** | t3.small with Amazon Linux 2 |
| **Storage** | 20GB root + 30GB data volume (encrypted) |
| **Network** | Elastic IP with Security Groups |
| **IAM** | Roles for EC2, EKS, RDS, Jenkins |
| **Monitoring** | CloudWatch logs and alarms |

### Jenkins Setup

**Pre-installed Software**:
- Jenkins 2.426.3
- Java 11 (Corretto)
- Docker (latest)
- kubectl 1.28.0
- AWS CLI v2
- Terraform 1.6.6
- Helm v3
- Git

**Pre-configured Plugins** (via Ansible):
- Pipeline & Blue Ocean
- Git & GitHub
- Docker & Kubernetes
- AWS (ECR, Credentials)
- Configuration as Code
- SonarQube, Terraform, Ansible
- Slack, Email notifications
- And 15+ more...

## 💰 Cost Breakdown

**AWS Resources (Monthly)**:

| Resource | Type | Cost |
|----------|------|------|
| EC2 (Jenkins) | t3.small | ~$15 |
| EKS Cluster | Control Plane | ~$72 |
| EKS Nodes | t3.small x1 | ~$15 |
| RDS | db.t4g.micro | ~$12 |
| ElastiCache | cache.t4g.micro | ~$11 |
| EBS Volumes | ~100GB total | ~$10 |
| Elastic IPs | 2 attached | Free |
| NAT Gateways | 2 x $0.045/hr | ~$65 |
| Data Transfer | First 1GB | Free |

**Total**: ~$200-220/month

**Free Tier Benefits** (First 12 months):
- 750 hours EC2 t2.micro (upgrade path)
- 750 hours RDS db.t2.micro
- 20GB EBS storage

## 🔧 Advanced Configuration

### Customize Jenkins Instance

Edit `environments/dev.tfvars`:

```hcl
# Upgrade instance size
jenkins_instance_type = "t3.medium"  # 4GB RAM

# Increase storage
jenkins_root_volume_size = 30
jenkins_data_volume_size = 100

# Restrict access (HIGHLY RECOMMENDED)
jenkins_allowed_ssh_cidr_blocks = ["1.2.3.4/32"]  # Your IP only
jenkins_allowed_cidr_blocks = ["1.2.3.4/32"]      # Your IP only
```

### Scale Resources

```hcl
# More EKS nodes
eks_node_desired_size = 2
eks_node_max_size = 5

# Larger RDS instance
rds_instance_class = "db.t4g.small"
rds_allocated_storage = 50

# More Redis nodes
redis_num_cache_nodes = 2
```

## 🔐 Security Best Practices

After deployment:

1. **Restrict Access**:
   ```hcl
   # Update dev.tfvars
   jenkins_allowed_ssh_cidr_blocks = ["YOUR_IP/32"]
   jenkins_allowed_cidr_blocks = ["YOUR_IP/32"]
   
   # Reapply
   terraform apply -var-file="environments/dev.tfvars"
   ```

2. **Change Default Password**:
   - Access Jenkins UI
   - Go to Manage Jenkins > Manage Users
   - Change admin password

3. **Enable HTTPS** (Optional):
   ```bash
   # Use ALB with ACM certificate
   # Or configure nginx reverse proxy
   ```

4. **Backup Configuration**:
   ```bash
   # Manual backup
   ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} \
     'sudo /usr/local/bin/jenkins-backup.sh'
   ```

5. **Keep Software Updated**:
   ```bash
   # Update Jenkins and plugins regularly
   # Via Jenkins UI or automation
   ```

## 📊 Monitoring

### CloudWatch Dashboards

```bash
# View metrics
aws cloudwatch get-dashboard --dashboard-name devsecops-dev-dashboard

# Check alarms
aws cloudwatch describe-alarms --alarm-names \
  devsecops-dev-jenkins-high-cpu \
  devsecops-dev-jenkins-status-check
```

### View Logs

```bash
# Jenkins logs
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} \
  'sudo journalctl -u jenkins -f'

# System logs
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} \
  'sudo tail -f /var/log/messages'
```

## 🧪 Testing

### Test SSH Access

```bash
ssh -i ~/.ssh/jenkins-key.pem ec2-user@$(terraform output -raw jenkins_public_ip)
```

### Test Jenkins API

```bash
JENKINS_URL=$(terraform output -raw jenkins_url)
curl -I ${JENKINS_URL}
```

### Test EKS Integration

```bash
# On Jenkins server
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP}
aws eks update-kubeconfig --name devsecops-dev-eks --region us-east-1
kubectl get nodes
```

## 🔄 Updates and Maintenance

### Update Infrastructure

```bash
# Modify dev.tfvars
vim environments/dev.tfvars

# Plan changes
terraform plan -var-file="environments/dev.tfvars"

# Apply updates
terraform apply -var-file="environments/dev.tfvars"
```

### Update Jenkins

```bash
# SSH to Jenkins
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP}

# Update system packages
sudo yum update -y

# Update Jenkins
sudo yum update jenkins -y
sudo systemctl restart jenkins
```

## 🧹 Cleanup

### Destroy Specific Resources

```bash
# Remove only Jenkins
terraform destroy -target=module.jenkins -var-file="environments/dev.tfvars"

# Remove EKS
terraform destroy -target=module.eks -var-file="environments/dev.tfvars"
```

### Destroy Everything

```bash
terraform destroy -var-file="environments/dev.tfvars"
```

**Warning**: This deletes ALL resources including:
- All EC2 instances
- EKS cluster and nodes
- RDS database (with backups)
- ElastiCache cluster
- All EBS volumes
- VPC and networking

## 🆘 Troubleshooting

### Jenkins Not Accessible

```bash
# Check EC2 status
aws ec2 describe-instances --filters "Name=tag:Name,Values=devsecops-dev-jenkins"

# Check security group
JENKINS_SG=$(terraform output -raw module.jenkins.jenkins_security_group_id)
aws ec2 describe-security-groups --group-ids ${JENKINS_SG}

# Check Jenkins service
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} 'sudo systemctl status jenkins'
```

### SSH Key Issues

```bash
# Check key permissions
ls -la ~/.ssh/jenkins-key.pem

# Should be 600
chmod 600 ~/.ssh/jenkins-key.pem

# Test connection with verbose output
ssh -vvv -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP}
```

### Terraform State Lock

```bash
# If terraform commands hang
terraform force-unlock <LOCK_ID>
```

### High Costs

```bash
# Check running resources
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Environment,Values=dev

# Stop non-critical resources
aws ec2 stop-instances --instance-ids <INSTANCE_ID>
```

## 📚 Additional Documentation

- **Detailed Guide**: `JENKINS_DEPLOYMENT.md`
- **Setup Summary**: `JENKINS_SETUP_COMPLETE.md`
- **Terraform Modules**: `terraform/modules/jenkins/`
- **Ansible Playbook**: `ansible/install-jenkins.yml`
- **Deployment Script**: `ansible/deploy-jenkins.sh`

## ✅ Verification Checklist

After deployment, verify:

- [ ] Terraform apply completed successfully
- [ ] Jenkins EC2 instance is running
- [ ] SSH key created at `~/.ssh/jenkins-key.pem`
- [ ] Can SSH to Jenkins server
- [ ] Jenkins web UI is accessible
- [ ] Initial admin password retrieved
- [ ] Security groups restrict access appropriately
- [ ] CloudWatch alarms are active
- [ ] EKS cluster is accessible from Jenkins
- [ ] Automated backups configured

## 🎉 Success!

Your complete DevSecOps infrastructure with Jenkins is now deployed!

**Next Steps**:
1. Complete Jenkins setup wizard
2. Create your first pipeline
3. Configure GitHub webhooks
4. Set up CI/CD workflows
5. Deploy applications to EKS

**Happy DevOps! 🚀**
