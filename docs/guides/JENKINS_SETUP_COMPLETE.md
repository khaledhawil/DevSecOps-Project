# Jenkins EC2 Deployment - Complete Setup

## 🎯 What You Have

A complete Infrastructure as Code (IaC) solution for deploying Jenkins on AWS:

### 📁 File Structure

```
03-infrastructure/
├── terraform/
│   ├── modules/
│   │   └── jenkins/              # Jenkins Terraform module
│   │       ├── main.tf           # EC2, Security Groups, IAM
│   │       ├── variables.tf      # Input variables
│   │       └── outputs.tf        # Output values
│   ├── environments/
│   │   └── dev.tfvars            # Updated with Jenkins config
│   ├── main.tf                   # Updated to include Jenkins module
│   ├── variables.tf              # Updated with Jenkins variables
│   └── outputs.tf                # Updated with Jenkins outputs
│
└── ansible/
    ├── install-jenkins.yml       # Main playbook
    ├── templates/
    │   ├── jenkins_defaults.j2   # Jenkins system config
    │   ├── basic-security.groovy.j2   # Security setup
    │   ├── jenkins-casc.yaml.j2  # Configuration as Code
    │   └── jenkins-backup.sh.j2  # Backup script
    ├── inventory/
    │   └── hosts.ini             # Ansible inventory
    ├── ansible.cfg               # Ansible configuration
    ├── requirements.yml          # Ansible collections
    ├── deploy-jenkins.sh         # Automated deployment script
    └── quick-start.sh            # Quick start helper
```

## 🚀 Quick Start (3 Steps)

### Option 1: Fully Automated

```bash
cd 03-infrastructure/ansible
./quick-start.sh
```

This will:
1. Generate SSH key pair
2. Update Terraform variables automatically
3. Restrict access to your IP
4. Deploy everything

### Option 2: Manual Setup

#### Step 1: Generate SSH Key

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/jenkins-key -N ""
mv ~/.ssh/jenkins-key ~/.ssh/jenkins-key.pem
chmod 600 ~/.ssh/jenkins-key.pem
cat ~/.ssh/jenkins-key.pub
```

#### Step 2: Update Configuration

Edit `03-infrastructure/terraform/environments/dev.tfvars`:

```hcl
# Replace with your SSH public key (from step 1)
jenkins_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EA... your-key-here"

# Replace with your IP address (run: curl ifconfig.me)
jenkins_allowed_ssh_cidr_blocks = ["YOUR_IP/32"]
jenkins_allowed_cidr_blocks = ["YOUR_IP/32"]
```

#### Step 3: Deploy

```bash
cd 03-infrastructure/ansible
./deploy-jenkins.sh dev
```

## 📋 What Gets Deployed

### AWS Resources

| Resource | Configuration |
|----------|--------------|
| **EC2 Instance** | t3.small (2 vCPU, 2GB RAM) |
| **OS** | Amazon Linux 2 |
| **Root Volume** | 20 GB EBS gp3 (encrypted) |
| **Data Volume** | 30 GB EBS gp3 (encrypted) |
| **Network** | Elastic IP (static) |
| **Security** | Custom security group |
| **IAM** | Role with ECR, EKS, S3 access |
| **Monitoring** | CloudWatch logs & alarms |

### Software Installed

| Software | Version | Purpose |
|----------|---------|---------|
| **Jenkins** | 2.426.3 | CI/CD Server |
| **Java** | 11 (Corretto) | Jenkins runtime |
| **Docker** | Latest | Container builds |
| **kubectl** | 1.28.0 | Kubernetes management |
| **AWS CLI** | v2 | AWS operations |
| **Terraform** | 1.6.6 | Infrastructure automation |
| **Helm** | v3 | Kubernetes packages |
| **Git** | Latest | Source control |

### Jenkins Plugins Installed

**Core Pipeline**:
- workflow-aggregator (Pipeline)
- pipeline-stage-view
- job-dsl
- blueocean (Modern UI)

**Source Control**:
- git, github, github-branch-source

**Docker & Kubernetes**:
- docker-workflow, docker-plugin
- kubernetes, kubernetes-cli

**Cloud Providers**:
- aws-credentials, amazon-ecr

**DevSecOps Tools**:
- sonarqube-scanner
- terraform
- ansible

**Configuration & Security**:
- configuration-as-code (JCasC)
- credentials-binding
- matrix-auth

**Notifications**:
- slack, email-ext

**Utilities**:
- timestamper, ws-cleanup
- build-timeout, prometheus

## 🔐 Security Features

- ✅ **IMDSv2** enforced on EC2
- ✅ **EBS volumes** encrypted
- ✅ **Security groups** with minimal access
- ✅ **IAM role** with least privilege
- ✅ **Jenkins authentication** configured
- ✅ **CSRF protection** enabled
- ✅ **CloudWatch monitoring** enabled
- ✅ **SNS alerts** for anomalies
- ✅ **Automated backups** to S3

## 📊 Cost Estimate

**Monthly Cost (AWS Free Tier)**:
- EC2 t3.small: ~$15/month
- EBS Storage (50GB): ~$5/month
- Elastic IP (attached): Free
- Data Transfer (1GB): Free

**Total**: ~$20-25/month

## 🎬 After Deployment

### 1. Get Jenkins URL

```bash
cd 03-infrastructure/terraform
terraform output jenkins_url
```

### 2. Get Initial Admin Password

```bash
JENKINS_IP=$(terraform output -raw jenkins_public_ip)
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} \
  'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
```

### 3. Access Jenkins

Open browser to: `http://<JENKINS_IP>:8080`

### 4. Complete Setup Wizard

1. Enter initial admin password
2. Select "Install suggested plugins" (or skip, plugins are pre-installed)
3. Create admin user
4. Configure Jenkins URL
5. Start using Jenkins!

## 🔧 Common Operations

### SSH into Jenkins Server

```bash
JENKINS_IP=$(cd terraform && terraform output -raw jenkins_public_ip)
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP}
```

### View Jenkins Logs

```bash
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} \
  'sudo journalctl -u jenkins -f'
```

### Restart Jenkins

```bash
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} \
  'sudo systemctl restart jenkins'
```

### Manual Backup

```bash
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} \
  'sudo /usr/local/bin/jenkins-backup.sh'
```

### Update Jenkins Configuration

```bash
# Edit JCasC configuration
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP}
sudo vim /var/lib/jenkins/casc_configs/jenkins.yaml

# Restart Jenkins to apply
sudo systemctl restart jenkins
```

## 🔗 Integration with EKS

Jenkins has IAM permissions to access your EKS cluster:

```bash
# On Jenkins server
aws eks update-kubeconfig --name devsecops-dev-eks --region us-east-1
kubectl get nodes
kubectl get pods --all-namespaces
```

## 📖 Pipeline Examples

### Example 1: Simple Pipeline

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
                sh 'echo "Hello from Jenkins!"'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing...'
                sh 'echo "Running tests..."'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying...'
                sh 'echo "Deploying application..."'
            }
        }
    }
}
```

### Example 2: Docker Build & Push to ECR

```groovy
pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO = '<account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${ECR_REPO}:${IMAGE_TAG}")
                }
            }
        }
        stage('Push to ECR') {
            steps {
                script {
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REPO}
                    '''
                    docker.image("${ECR_REPO}:${IMAGE_TAG}").push()
                    docker.image("${ECR_REPO}:${IMAGE_TAG}").push('latest')
                }
            }
        }
    }
}
```

### Example 3: Deploy to EKS

```groovy
pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1'
        EKS_CLUSTER = 'devsecops-dev-eks'
    }
    stages {
        stage('Configure kubectl') {
            steps {
                sh '''
                    aws eks update-kubeconfig \
                      --name ${EKS_CLUSTER} \
                      --region ${AWS_REGION}
                '''
            }
        }
        stage('Deploy') {
            steps {
                sh '''
                    kubectl apply -f k8s/deployment.yaml
                    kubectl rollout status deployment/my-app
                '''
            }
        }
    }
}
```

## 🧹 Cleanup

### Destroy Jenkins Infrastructure

```bash
cd 03-infrastructure/terraform
terraform destroy -var-file="environments/dev.tfvars"
```

**Note**: This will delete all resources including EC2, EBS volumes, Elastic IP, etc.

## 📚 Documentation

- Main Guide: `JENKINS_DEPLOYMENT.md`
- This File: Quick reference
- Terraform Module: `terraform/modules/jenkins/`
- Ansible Playbook: `ansible/install-jenkins.yml`

## ⚠️ Important Notes

1. **SSH Key**: Keep `~/.ssh/jenkins-key.pem` secure. Never commit to Git!
2. **Admin Password**: Change the default password immediately
3. **Security Groups**: Restrict access to your IP only
4. **Backups**: Verify automated backups are working
5. **Updates**: Keep Jenkins and plugins updated
6. **Monitoring**: Check CloudWatch alarms regularly

## 🆘 Troubleshooting

### Can't Access Jenkins

```bash
# Check instance is running
aws ec2 describe-instances --filters "Name=tag:Name,Values=devsecops-dev-jenkins"

# Check security group
aws ec2 describe-security-groups --group-ids <SG_ID>

# Verify Jenkins is running
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP} 'sudo systemctl status jenkins'
```

### Forgot Admin Password

```bash
# Reset password
ssh -i ~/.ssh/jenkins-key.pem ec2-user@${JENKINS_IP}
sudo systemctl stop jenkins
sudo rm -f /var/lib/jenkins/config.xml
sudo systemctl start jenkins
# Get new initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Need More Resources

Edit `terraform/environments/dev.tfvars`:
```hcl
jenkins_instance_type = "t3.medium"  # Upgrade to 4GB RAM
jenkins_data_volume_size = 100       # Increase storage
```

Then apply:
```bash
cd terraform
terraform apply -var-file="environments/dev.tfvars"
```

## ✅ Next Steps

1. **Create Your First Pipeline**
   - Click "New Item"
   - Choose "Pipeline"
   - Add your Jenkinsfile

2. **Configure GitHub Integration**
   - Add GitHub credentials
   - Set up webhooks
   - Create multibranch pipeline

3. **Set Up Notifications**
   - Configure Slack integration
   - Set up email alerts
   - Enable build status badges

4. **Implement CI/CD**
   - Build microservices pipelines
   - Deploy to Kubernetes
   - Run security scans

5. **Backup Configuration**
   - Export JCasC configuration
   - Store pipeline definitions in Git
   - Document your setup

## 🎉 Success!

You now have a fully functional Jenkins server on AWS, configured with Terraform and Ansible, ready for CI/CD workflows!

**Happy Building! 🚀**
