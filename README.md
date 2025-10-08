# 🚀 Enterprise DevSecOps Platform

[![Status](https://img.shields.io/badge/Status-Production%20Ready-success)](docs/status/PROJECT-SUMMARY.md)
[![Infrastructure](https://img.shields.io/badge/Infrastructure-Terraform-blueviolet)](03-infrastructure/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28-blue)](04-kubernetes/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions%20%2B%20ArgoCD-orange)](05-cicd/)
[![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%20%2B%20Grafana-red)](06-monitoring/)
[![Security](https://img.shields.io/badge/Security-Multi--Layer-green)](07-security/)

> **A complete, production-ready DevSecOps platform featuring 5 microservices, full CI/CD automation, comprehensive monitoring, and enterprise-grade security.**

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Quick Start](#-quick-start)
- [Components](#-components)
- [Deployment Options](#-deployment-options)
- [Monitoring & Observability](#-monitoring--observability)
- [Security Features](#-security-features)
- [Documentation](#-documentation)
- [Cost Breakdown](#-cost-breakdown)
- [Contributing](#-contributing)

---

## 🎯 Overview

This project is a **complete enterprise-grade DevSecOps platform** that demonstrates modern cloud-native architecture, automated CI/CD pipelines, comprehensive security controls, and production-ready monitoring.

### Key Highlights

✅ **5 Microservices** in 5 different languages (Go, TypeScript, Python, Java, React)  
✅ **Cloud Infrastructure** on AWS with Terraform (VPC, EKS, RDS, ElastiCache, Jenkins)  
✅ **Kubernetes Orchestration** with multi-environment support (dev/staging/prod)  
✅ **GitOps CI/CD** with GitHub Actions and ArgoCD  
✅ **Comprehensive Monitoring** with Prometheus, Grafana, and AlertManager  
✅ **Multi-Layer Security** with Gatekeeper, Falco, Vault, Trivy, and SonarQube  
✅ **Complete Automation** with deployment scripts and Infrastructure as Code  

### Project Statistics

| Metric | Value |
|--------|-------|
| **Total Files** | 208+ files |
| **Lines of Code** | ~35,000+ lines |
| **Microservices** | 5 services |
| **Programming Languages** | 5 languages |
| **Infrastructure Modules** | 8 Terraform modules |
| **Kubernetes Resources** | 50+ manifests |
| **CI/CD Workflows** | 7 GitHub Actions |
| **ArgoCD Applications** | 15 applications |
| **Monitoring Components** | 4 stacks |
| **Security Tools** | 5+ tools |

---

## 🏗️ Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                            AWS Cloud                                 │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    VPC (Multi-AZ)                              │ │
│  │                                                                │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │            EKS Cluster (Kubernetes 1.28)                 │ │ │
│  │  │                                                          │ │ │
│  │  │  ┌────────────┐  ┌────────────┐  ┌────────────┐       │ │ │
│  │  │  │   User     │  │   Auth     │  │Notification│       │ │ │
│  │  │  │  Service   │  │  Service   │  │  Service   │       │ │ │
│  │  │  │   (Go)     │  │(TypeScript)│  │  (Python)  │       │ │ │
│  │  │  └────────────┘  └────────────┘  └────────────┘       │ │ │
│  │  │                                                          │ │ │
│  │  │  ┌────────────┐  ┌────────────┐                        │ │ │
│  │  │  │ Analytics  │  │  Frontend  │                        │ │ │
│  │  │  │  Service   │  │   (React)  │                        │ │ │
│  │  │  │   (Java)   │  │            │                        │ │ │
│  │  │  └────────────┘  └────────────┘                        │ │ │
│  │  │                                                          │ │ │
│  │  │  ┌──────────────────────────────────────────────────┐  │ │ │
│  │  │  │          Monitoring & Security Stack             │  │ │ │
│  │  │  │  • Prometheus  • Grafana  • AlertManager         │  │ │ │
│  │  │  │  • Fluent Bit  • Falco    • Gatekeeper           │  │ │ │
│  │  │  └──────────────────────────────────────────────────┘  │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  │                                                                │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │ │
│  │  │ RDS PostgreSQL  │  │ElastiCache Redis│  │   Jenkins    │ │ │
│  │  │   (Multi-AZ)    │  │   (Multi-AZ)    │  │   CI/CD      │ │ │
│  │  └─────────────────┘  └─────────────────┘  └──────────────┘ │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  External Services: ECR • CloudWatch • S3 • Route53 • ALB           │
└──────────────────────────────────────────────────────────────────────┘
                                 ▲
                                 │
                    ┌────────────┴────────────┐
                    │   GitHub Actions CI/CD  │
                    │   • Build  • Test       │
                    │   • Scan   • Deploy     │
                    └─────────────────────────┘
```

### Technology Stack

#### Services Layer
- **User Service**: Go 1.21 + Echo + GORM + PostgreSQL + Redis
- **Auth Service**: Node.js 18 + Express + JWT + PostgreSQL + Redis
- **Notification Service**: Python 3.11 + Flask + Celery + Redis
- **Analytics Service**: Java 17 + Spring Boot 3.2 + JPA + PostgreSQL
- **Frontend**: React 18 + TypeScript 5 + Vite + TailwindCSS

#### Infrastructure Layer
- **Cloud Provider**: AWS
- **Infrastructure as Code**: Terraform 1.6+
- **Container Orchestration**: Kubernetes 1.28 (EKS)
- **Container Registry**: Amazon ECR
- **Database**: Amazon RDS (PostgreSQL 15.7)
- **Cache**: Amazon ElastiCache (Redis 7.0)
- **CI/CD Server**: Jenkins on EC2 (t3.small)

#### CI/CD Layer
- **Pipeline**: GitHub Actions (7 workflows)
- **GitOps**: ArgoCD (15 applications)
- **Security Scanning**: Trivy, SonarQube, Gitleaks
- **Image Signing**: Cosign
- **SBOM Generation**: Syft

#### Monitoring Layer
- **Metrics**: Prometheus (15s scrape interval)
- **Visualization**: Grafana (2 custom dashboards)
- **Alerting**: AlertManager (12 rules)
- **Logging**: Fluent Bit → CloudWatch Logs

#### Security Layer
- **Policy Enforcement**: OPA Gatekeeper (11 policies)
- **Runtime Security**: Falco (23 custom rules)
- **Secret Management**: HashiCorp Vault + External Secrets
- **Vulnerability Scanning**: Trivy Operator
- **Code Quality**: SonarQube

---

## ⚡ Quick Start

### Prerequisites

- **Docker** 24.0+ and **Docker Compose** 2.0+
- **AWS Account** with admin access
- **AWS CLI** configured
- **Terraform** 1.6+
- **kubectl** 1.28+
- **Helm** 3.0+

### Installation

#### Step 1: Install Required Tools

```bash
cd 01-setup
chmod +x install-tools.sh verify-installation.sh
./install-tools.sh
./verify-installation.sh
```

#### Step 2: Choose Your Deployment Method

**Option A: Local Development (Recommended for testing)**

```bash
cd 08-deployment-scripts/local
./deploy-local.sh

# Services will be available at:
# - Frontend: http://localhost:3000
# - User API: http://localhost:8080
# - Auth API: http://localhost:3001
# - Notification API: http://localhost:5000
# - Analytics API: http://localhost:8081
```

**Time**: ~10 minutes | **Cost**: FREE

**Option B: AWS Production Deployment**

```bash
cd 08-deployment-scripts/aws
./deploy-full-stack.sh dev

# Or deploy specific components:
./deploy-infrastructure.sh dev  # Infrastructure only
```

**Time**: ~30-40 minutes | **Cost**: ~$210/month (dev)

#### Step 3: Deploy Jenkins CI/CD (Optional)

```bash
cd 03-infrastructure/terraform
./deploy-all.sh dev

# Access Jenkins at: http://<jenkins-public-ip>:8080
# Get initial password:
ssh -i ~/.ssh/jenkins-key.pem ec2-user@<jenkins-ip> \
  'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
```

See [Jenkins Documentation](docs/guides/ONE_COMMAND_JENKINS.md) for details.

#### Step 4: Verify Deployment

```bash
# Local
cd 08-deployment-scripts/local
./check-health.sh

# AWS
kubectl get pods -A
kubectl get svc -A
```

---

## 🧩 Components

### 1. [Microservices](02-services/)

| Service | Language | Purpose | Port |
|---------|----------|---------|------|
| [User Service](02-services/user-service/) | Go | User management, CRUD operations | 8080 |
| [Auth Service](02-services/auth-service/) | TypeScript | Authentication, JWT tokens | 3001 |
| [Notification Service](02-services/notification-service/) | Python | Multi-channel notifications | 5000 |
| [Analytics Service](02-services/analytics-service/) | Java | Event tracking, analytics | 8081 |
| [Frontend](02-services/frontend/) | React | Web UI, user interface | 3000 |

**Features**: RESTful APIs, Health checks, Metrics, Logging, Caching, Error handling

### 2. [Infrastructure as Code](03-infrastructure/)

**8 Terraform Modules**:
- **VPC**: Multi-AZ networking with public/private subnets
- **EKS**: Kubernetes cluster with managed node groups
- **RDS**: PostgreSQL Multi-AZ database
- **ElastiCache**: Redis Multi-AZ cache cluster
- **Jenkins**: EC2 instance with automated setup
- **IAM**: Roles and policies for cluster and services
- **Security**: Security groups and network policies
- **Monitoring**: CloudWatch integration

**Environments**: dev, staging, prod with isolated configurations

📖 [Infrastructure Documentation](03-infrastructure/README.md)

### 3. [Kubernetes Manifests](04-kubernetes/)

**50+ Kubernetes Resources**:
- Deployments with HorizontalPodAutoscalers
- Services (ClusterIP, LoadBalancer)
- ConfigMaps and Secrets
- NetworkPolicies for segmentation
- ServiceMonitors for Prometheus
- Ingress with AWS ALB
- PodDisruptionBudgets

**Kustomize Overlays**: dev (1 replica), staging (2 replicas), prod (3+ replicas)

📖 [Kubernetes Documentation](04-kubernetes/README.md)

### 4. [CI/CD Pipeline](05-cicd/)

**GitHub Actions (7 Workflows)**:
- Service build, test, and security scanning
- Multi-layer scanning (code, dependencies, containers, IaC)
- Image signing with Cosign
- SBOM generation with Syft
- Automated deployment triggers

**ArgoCD (15 Applications)**:
- GitOps deployment model
- 5 services × 3 environments
- Auto-sync enabled
- Self-healing capabilities
- Progressive rollout strategies

📖 [CI/CD Documentation](05-cicd/README.md)

### 5. [Monitoring Stack](06-monitoring/)

**Components**:
- **Prometheus**: Metrics collection, 15s scrape interval, 15-day retention
- **Grafana**: 2 custom dashboards (Cluster + Services)
- **AlertManager**: 12 alert rules (6 critical, 6 warning)
- **Fluent Bit**: Log aggregation to CloudWatch

**Metrics Tracked**:
- Request rate, latency (P50/P95/P99), error rate
- CPU, memory, disk, network usage
- Business metrics (signups, logins, notifications)

📖 [Monitoring Documentation](06-monitoring/README.md)

### 6. [Security & Compliance](07-security/)

**Multi-Layer Security**:
- **Gatekeeper**: 11 OPA policies for admission control
- **Falco**: 23 custom rules for runtime security
- **Vault**: Secret management with Kubernetes auth
- **Trivy**: Continuous vulnerability scanning
- **SonarQube**: Code quality and security analysis

**Security Features**:
- Network policies (default deny)
- RBAC with least privilege
- Image signing and SBOM
- Secrets encryption at rest
- Audit logging

📖 [Security Documentation](07-security/README.md)

### 7. [Deployment Scripts](08-deployment-scripts/)

**Automated Deployment**:
- Single command deployment for local and AWS
- Health verification and validation
- Safe destruction procedures
- Prerequisites checking
- Comprehensive logging

📖 [Deployment Documentation](08-deployment-scripts/README.md)

---

## 🚀 Deployment Options

### Local Development

**Ideal for**: Development, testing, demos

**Requirements**:
- 8GB RAM minimum
- 20GB disk space
- Docker & Docker Compose

**Deploy**:
```bash
./08-deployment-scripts/local/deploy-local.sh
```

**Services**:
- All 5 microservices
- PostgreSQL 15.5
- Redis 7.2
- MailHog (email testing)

**Cost**: FREE

### AWS Development Environment

**Ideal for**: Integration testing, staging

**Requirements**:
- AWS account
- AWS CLI configured
- Terraform, kubectl, Helm

**Deploy**:
```bash
./08-deployment-scripts/aws/deploy-full-stack.sh dev
```

**Resources**:
- EKS cluster (1.28)
- RDS PostgreSQL (Multi-AZ)
- ElastiCache Redis
- 1 replica per service
- Basic monitoring

**Cost**: ~$210/month

### AWS Production Environment

**Ideal for**: Production workloads

**Deploy**:
```bash
./08-deployment-scripts/aws/deploy-full-stack.sh prod
```

**Resources**:
- EKS cluster with auto-scaling
- RDS Multi-AZ with read replicas
- ElastiCache cluster mode
- 3+ replicas per service
- Full monitoring and alerting
- Complete security stack

**Cost**: ~$700-1000/month

---

## 📈 Monitoring & Observability

### Metrics Collection

**Prometheus** scrapes metrics from:
- All microservices (custom application metrics)
- Kubernetes cluster (kube-state-metrics)
- Node metrics (node-exporter)
- Infrastructure (CloudWatch integration)

**Scrape Interval**: 15 seconds  
**Retention**: 15 days  
**Storage**: 50GB persistent volume

### Dashboards

**Grafana** includes:
1. **Cluster Overview**: Node health, pod status, resource usage
2. **Services Overview**: Request rate, latency, error rate, API performance

**Access**: `kubectl port-forward -n monitoring svc/grafana 3000:80`  
**Credentials**: admin / (from secret)

### Alerting

**12 Alert Rules**:
- **Critical** (6): High error rate, pod crashes, node down, disk full, memory exhaustion, deployment failure
- **Warning** (6): High latency, increased memory, CPU pressure, pod restarts, low replica count

**Notification Channels**:
- Slack (instant alerts)
- PagerDuty (critical only)
- Email (daily summary)

### Logging

**Fluent Bit** collects logs from:
- All application pods
- System components
- Kubernetes events

**Destination**: CloudWatch Logs (30-day retention)

**Access**:
```bash
kubectl logs -n <namespace> <pod-name>
# Or use CloudWatch Logs Insights
```

---

## 🔐 Security Features

### Defense in Depth

**Layer 1: Network Security**
- VPC with private subnets
- Security groups (least privilege)
- NetworkPolicies (default deny + explicit allow)
- TLS/SSL for all external endpoints

**Layer 2: Identity & Access**
- AWS IAM roles with IRSA
- Kubernetes RBAC
- Service accounts per application
- JWT authentication

**Layer 3: Admission Control**
- Gatekeeper policies (OPA)
- Pod Security Standards
- Resource quotas
- Image scanning enforcement

**Layer 4: Runtime Security**
- Falco threat detection
- Read-only root filesystem
- Dropped capabilities
- Non-root containers

**Layer 5: Secret Management**
- Vault for dynamic secrets
- External Secrets Operator
- Secrets encryption at rest
- Automatic rotation

**Layer 6: Vulnerability Management**
- Trivy continuous scanning
- SonarQube code analysis
- Dependency scanning
- SBOM generation

**Layer 7: Compliance & Audit**
- CloudTrail logging
- Kubernetes audit logs
- Policy compliance reports
- CIS benchmark scanning

### Security Scanning

**Automated Scans**:
- **Daily**: Container images, dependencies, secrets
- **On Commit**: Code quality, security issues
- **On PR**: Full security scan + approval gates
- **On Deploy**: Image signature verification

**Tools Used**:
- Trivy (vulnerabilities)
- SonarQube (code quality)
- Gitleaks (secrets)
- OWASP Dependency Check
- Cosign (image signing)

---

## 📚 Documentation

### Core Documentation

- **[Project Summary](docs/status/PROJECT-SUMMARY.md)**: Complete project overview
- **[Project Status](docs/status/PROJECT_STATUS_FINAL.md)**: Implementation status
- **[Documentation Index](DOCUMENTATION.md)**: All documentation links

### Component Documentation

- **[Setup Guide](01-setup/README.md)**: Tool installation and prerequisites
- **[Services Documentation](02-services/)**: Microservices details
- **[Infrastructure Guide](03-infrastructure/README.md)**: Terraform setup
- **[Kubernetes Guide](04-kubernetes/README.md)**: K8s deployment
- **[CI/CD Guide](05-cicd/README.md)**: Pipeline configuration
- **[Monitoring Guide](06-monitoring/README.md)**: Observability setup
- **[Security Guide](07-security/README.md)**: Security implementation
- **[Deployment Guide](08-deployment-scripts/README.md)**: Deployment automation

### Quick Reference Guides

- **[Jenkins Setup](docs/guides/ONE_COMMAND_JENKINS.md)**: Jenkins deployment guide
- **[Quick Start](01-setup/QUICKSTART.md)**: Fast track setup
- **[Deployment Quick Start](08-deployment-scripts/QUICK-START.md)**: Deployment reference
- **[Scripts Summary](09-scripts/SCRIPTS-SUMMARY.md)**: Helper scripts

### Architecture Documents

- **[Architecture Overview](08-docs/architecture/)**: System architecture
- **[API Documentation](08-docs/api/)**: API specifications
- **[Runbooks](08-docs/runbooks/)**: Operational procedures

---

## 💰 Cost Breakdown

### Local Development
- **Monthly Cost**: $0 (FREE)
- **Hardware**: Local machine (8GB RAM, 20GB disk)

### AWS Development Environment
- **Monthly Cost**: ~$210
- EKS Control Plane: $73
- Worker Nodes (2× t3.medium): $30
- RDS (db.t3.medium): $60
- ElastiCache (cache.t3.micro): $15
- NAT Gateway: $32

### AWS Staging Environment
- **Monthly Cost**: ~$400
- EKS Control Plane: $73
- Worker Nodes (3× t3.large): $150
- RDS (db.t3.large, Multi-AZ): $120
- ElastiCache (cache.t3.small, Multi-AZ): $30
- Load Balancers: $20
- Monitoring & Logs: ~$10

### AWS Production Environment
- **Monthly Cost**: ~$700-1000
- EKS Control Plane: $73
- Worker Nodes (5× t3.xlarge): $300
- RDS (db.r5.xlarge, Multi-AZ): $350
- ElastiCache (cache.r5.large, cluster): $100
- Load Balancers: $40
- Monitoring, Logs, Backups: ~$50
- Data Transfer: Variable

### Jenkins Server (Optional)
- **Monthly Cost**: ~$15-20
- EC2 (t3.small): $15
- EBS Storage (50GB): $5

**Total Platform Cost**:
- **Dev**: $210-230/month
- **Staging**: $400-450/month  
- **Prod**: $700-1000/month

---

## 🎓 What You Get

This platform provides:

✅ **Production-Ready Microservices**
- RESTful APIs with comprehensive error handling
- Database persistence and caching
- Health checks and metrics
- Unit and integration tests

✅ **Enterprise Infrastructure**
- Multi-AZ high availability
- Auto-scaling capabilities
- Disaster recovery ready
- Cost-optimized configurations

✅ **GitOps CI/CD**
- Automated build, test, deploy
- Multi-layer security scanning
- Image signing and SBOM
- Progressive rollout strategies

✅ **Comprehensive Monitoring**
- Real-time metrics and dashboards
- Multi-channel alerting
- Centralized logging
- Performance tracking

✅ **Multi-Layer Security**
- Policy enforcement
- Runtime threat detection
- Secret management
- Vulnerability scanning
- Compliance reporting

✅ **Complete Automation**
- Single-command deployment
- Infrastructure as Code
- Self-healing systems
- Automated backups

---

## 🤝 Contributing

This is a demonstration project showcasing DevSecOps best practices. Feel free to:

- Fork the repository
- Customize for your needs
- Submit improvements
- Share feedback

---

## 📞 Support & Troubleshooting

### Common Issues

**Problem**: Docker permission denied
```bash
sudo usermod -aG docker $USER
newgrp docker
```

**Problem**: AWS credentials not configured
```bash
aws configure
aws sts get-caller-identity
```

**Problem**: kubectl not connecting
```bash
aws eks update-kubeconfig --region us-west-2 --name devsecops-dev-cluster
kubectl get nodes
```

**Problem**: Services not starting
```bash
# Check logs
kubectl logs -n <namespace> <pod-name>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

### Getting Help

1. Check component-specific README files
2. Review troubleshooting sections in documentation
3. Check logs for error details
4. Review [runbooks](08-docs/runbooks/) for common scenarios

---

## 🎉 Success!

You now have a **complete, production-ready DevSecOps platform** with:

- ✅ 208+ files of production-grade code
- ✅ ~35,000+ lines of infrastructure and application code
- ✅ 5 microservices in 5 languages
- ✅ Complete CI/CD automation
- ✅ Enterprise security controls
- ✅ Comprehensive monitoring
- ✅ Multi-environment support
- ✅ Complete documentation

**Ready to deploy to production!** 🚀

---

## 📜 License

This project is for educational and demonstration purposes.

---

## 🌟 Acknowledgments

Built with modern DevSecOps best practices using:
- AWS Cloud Platform
- Kubernetes & Docker
- Terraform & Ansible
- GitHub Actions & ArgoCD
- Prometheus & Grafana
- HashiCorp Vault
- And many more amazing open-source tools

---

**Last Updated**: October 8, 2025  
**Project Status**: ✅ Production Ready  
**Completion**: 100%

**Built with ❤️ and DevSecOps Excellence**
