# 📚 Documentation Index

Complete guide to all documentation in the DevSecOps Platform.

---

## 📖 Quick Links

| Category | Document | Description |
|----------|----------|-------------|
| 🏠 **Main** | [README.md](README.md) | Project overview and getting started |
| 📊 **Status** | [Project Summary](docs/status/PROJECT-SUMMARY.md) | Complete project statistics and status |
| ⚡ **Quick Start** | [Setup Guide](01-setup/QUICKSTART.md) | Fast track installation and setup |
| 🚀 **Deployment** | [Deployment Quick Start](08-deployment-scripts/QUICK-START.md) | Quick deployment reference |

---

## 📋 Table of Contents

- [Project Status & Overview](#-project-status--overview)
- [Setup & Installation](#-setup--installation)
- [Component Documentation](#-component-documentation)
- [Deployment Guides](#-deployment-guides)
- [Configuration Guides](#-configuration-guides)
- [Architecture & Design](#-architecture--design)
- [Operations & Maintenance](#-operations--maintenance)
- [Troubleshooting](#-troubleshooting)

---

## 📊 Project Status & Overview

### Current Status
- **[PROJECT-SUMMARY.md](docs/status/PROJECT-SUMMARY.md)** - Complete project overview, statistics, and components
- **[PROJECT_STATUS_FINAL.md](docs/status/PROJECT_STATUS_FINAL.md)** - Final implementation status and completion details
- **[PROJECT_COMPLETE.md](docs/status/PROJECT_COMPLETE.md)** - Project completion summary
- **[SERVICES_COMPLETE.md](docs/status/SERVICES_COMPLETE.md)** - Microservices implementation status

### Legacy Status Files (Archive)
- **[PROJECT_PROGRESS.md](docs/status/PROJECT_PROGRESS.md)** - Historical progress tracking
- **[PROJECT_STATUS.md](docs/status/PROJECT_STATUS.md)** - Earlier status snapshot
- **[IMPLEMENTATION_STATUS.md](docs/status/IMPLEMENTATION_STATUS.md)** - Implementation tracking

---

## 🛠️ Setup & Installation

### Prerequisites & Tools
- **[01-setup/README.md](01-setup/README.md)** - Tool installation guide (Docker, kubectl, Terraform, AWS CLI, etc.)
- **[01-setup/QUICKSTART.md](01-setup/QUICKSTART.md)** - Quick start installation guide
- **[01-setup/install-tools.sh](01-setup/install-tools.sh)** - Automated tool installation script
- **[01-setup/verify-installation.sh](01-setup/verify-installation.sh)** - Installation verification script

---

## 🧩 Component Documentation

### Microservices (02-services/)

#### User Service (Go)
- **[02-services/user-service/README.md](02-services/user-service/README.md)** - User management service documentation
- **Technology**: Go 1.21, Echo, GORM, PostgreSQL, Redis
- **Features**: CRUD operations, JWT auth, caching, metrics
- **Port**: 8080

#### Auth Service (TypeScript)
- **[02-services/auth-service/README.md](02-services/auth-service/README.md)** - Authentication service documentation
- **Technology**: Node.js 18, Express, TypeORM, JWT
- **Features**: Token management, refresh tokens, audit logging
- **Port**: 3001

#### Notification Service (Python)
- **[02-services/notification-service/README.md](02-services/notification-service/README.md)** - Notification service documentation
- **Technology**: Python 3.11, Flask, Celery, SQLAlchemy
- **Features**: Multi-channel notifications (email, SMS, push)
- **Port**: 5000

#### Analytics Service (Java)
- **[02-services/analytics-service/README.md](02-services/analytics-service/README.md)** - Analytics service documentation
- **Technology**: Java 17, Spring Boot 3.2, JPA
- **Features**: Event tracking, real-time analytics, caching
- **Port**: 8081

#### Frontend (React)
- **[02-services/frontend/README.md](02-services/frontend/README.md)** - Frontend application documentation
- **Technology**: React 18, TypeScript 5, Vite, TailwindCSS
- **Features**: Modern UI, authentication flow, responsive design
- **Port**: 3000

---

### Infrastructure (03-infrastructure/)

#### Main Infrastructure Documentation
- **[03-infrastructure/README.md](03-infrastructure/README.md)** - Complete infrastructure guide (281 lines)
- **[03-infrastructure/terraform/](03-infrastructure/terraform/)** - Terraform configurations

#### Terraform Modules
Located in `03-infrastructure/terraform/modules/`:
- **vpc/** - Multi-AZ VPC with public/private subnets
- **eks/** - EKS Kubernetes cluster (1.28)
- **rds/** - PostgreSQL Multi-AZ database
- **elasticache/** - Redis Multi-AZ cache
- **jenkins/** - Jenkins CI/CD server on EC2
- **iam/** - IAM roles and policies
- **security/** - Security groups
- **monitoring/** - CloudWatch integration

#### Environments
- **dev** - Development environment (1 replica per service)
- **staging** - Staging environment (2 replicas per service)
- **prod** - Production environment (3+ replicas per service)

---

### Kubernetes (04-kubernetes/)

- **[04-kubernetes/README.md](04-kubernetes/README.md)** - Kubernetes deployment guide
- **[04-kubernetes/KUBERNETES_COMPLETE.md](04-kubernetes/KUBERNETES_COMPLETE.md)** - Kubernetes implementation completion

#### Base Manifests (04-kubernetes/base/)
- Deployments, Services, ConfigMaps, Secrets
- HorizontalPodAutoscalers
- NetworkPolicies
- ServiceMonitors (Prometheus)
- Ingress configurations

#### Overlays (04-kubernetes/overlays/)
- **dev/** - Development overlays
- **staging/** - Staging overlays
- **prod/** - Production overlays

---

### CI/CD Pipeline (05-cicd/)

- **[05-cicd/README.md](05-cicd/README.md)** - Complete CI/CD documentation (400+ lines)
- **[05-cicd/IMPLEMENTATION-COMPLETE.md](05-cicd/IMPLEMENTATION-COMPLETE.md)** - CI/CD implementation summary

#### GitHub Actions (05-cicd/github-actions/)
- **user-service.yml** - User service pipeline (Go)
- **auth-service.yml** - Auth service pipeline (Node.js)
- **notification-service.yml** - Notification service pipeline (Python)
- **analytics-service.yml** - Analytics service pipeline (Java)
- **frontend.yml** - Frontend pipeline (React)
- **infrastructure.yml** - Infrastructure scanning
- **security-scan.yml** - Daily security scans

#### ArgoCD (05-cicd/argocd/)
- **argocd-config.yaml** - ArgoCD installation
- **app-of-apps.yaml** - Application of applications pattern
- **projects.yaml** - ArgoCD projects
- **applications/** - 15 application manifests (5 services × 3 environments)

---

### Monitoring (06-monitoring/)

- **[06-monitoring/README.md](06-monitoring/README.md)** - Complete monitoring guide (700+ lines)
- **[06-monitoring/IMPLEMENTATION-COMPLETE.md](06-monitoring/IMPLEMENTATION-COMPLETE.md)** - Monitoring implementation summary

#### Components
- **prometheus/** - Metrics collection, recording rules
- **grafana/** - Dashboards, datasources
- **alertmanager/** - Alert rules, notification templates
- **fluent-bit/** - Log aggregation to CloudWatch
- **logging/** - Logging configuration

---

### Security (07-security/)

- **[07-security/README.md](07-security/README.md)** - Complete security guide
- **[07-security/IMPLEMENTATION-COMPLETE.md](07-security/IMPLEMENTATION-COMPLETE.md)** - Security implementation summary

#### Security Components
- **gatekeeper/** - OPA policies (11 constraint templates)
- **falco/** - Runtime security (23 custom rules)
- **vault/** - Secret management
- **trivy/** - Vulnerability scanning
- **sonarqube/** - Code quality analysis
- **policies/** - Security policies
- **scanning/** - Security scanning configurations
- **secrets/** - Secret management configurations

---

## 🚀 Deployment Guides

### Automated Deployment Scripts (08-deployment-scripts/)

- **[08-deployment-scripts/README.md](08-deployment-scripts/README.md)** - Complete deployment guide (600+ lines)
- **[08-deployment-scripts/QUICK-START.md](08-deployment-scripts/QUICK-START.md)** - Quick deployment reference (400+ lines)
- **[08-deployment-scripts/IMPLEMENTATION-COMPLETE.md](08-deployment-scripts/IMPLEMENTATION-COMPLETE.md)** - Deployment automation summary (400+ lines)

#### Local Deployment (08-deployment-scripts/local/)
- **deploy-local.sh** - Complete local deployment
- **start-services.sh** - Start all services
- **stop-services.sh** - Stop all services
- **check-health.sh** - Health verification
- **clean-local.sh** - Cleanup script

#### AWS Deployment (08-deployment-scripts/aws/)
- **deploy-full-stack.sh** - Complete AWS deployment
- **deploy-infrastructure.sh** - Infrastructure only
- **update-kubeconfig.sh** - kubectl configuration
- **destroy-infrastructure.sh** - Safe destruction

#### Helper Scripts (08-deployment-scripts/helpers/)
- **common-functions.sh** - Utility functions (20+ functions)
- **check-prerequisites.sh** - Prerequisites validation

---

### Jenkins CI/CD Deployment

- **[docs/guides/ONE_COMMAND_JENKINS.md](docs/guides/ONE_COMMAND_JENKINS.md)** - Complete Jenkins deployment guide (450+ lines)
- **[docs/guides/JENKINS_INTEGRATION_COMPLETE.md](docs/guides/JENKINS_INTEGRATION_COMPLETE.md)** - Jenkins integration summary
- **[docs/guides/JENKINS_SETUP_COMPLETE.md](docs/guides/JENKINS_SETUP_COMPLETE.md)** - Jenkins setup reference
- **[03-infrastructure/terraform/deploy-all.sh](03-infrastructure/terraform/deploy-all.sh)** - Deploy all infrastructure including Jenkins

#### Jenkins Features
- Automated SSH key generation
- One-command deployment with infrastructure
- 25+ pre-installed plugins
- Configuration as Code (JCasC)
- Integrated with EKS, ECR, AWS CLI
- Automated daily backups to S3

---

## ⚙️ Configuration Guides

### Infrastructure Configuration
- **[docs/guides/FREE_TIER_CONFIG.md](docs/guides/FREE_TIER_CONFIG.md)** - AWS Free Tier configuration guide
- **[docs/guides/TERRAFORM_FIXES.md](docs/guides/TERRAFORM_FIXES.md)** - Terraform troubleshooting
- **[docs/guides/VARIABLE_NAMING_FIXES.md](docs/guides/VARIABLE_NAMING_FIXES.md)** - Variable naming conventions
- **[docs/guides/FINAL_CONFIGURATION.md](docs/guides/FINAL_CONFIGURATION.md)** - Final infrastructure configuration

### Deployment Configuration
- **[docs/guides/DEPLOYMENT.md](docs/guides/DEPLOYMENT.md)** - Deployment configuration guide
- **[docs/guides/DEPLOYMENT_ERRORS_RESOLVED.md](docs/guides/DEPLOYMENT_ERRORS_RESOLVED.md)** - Common deployment error resolutions

---

## 🏛️ Architecture & Design

### Architecture Documentation (08-docs/architecture/)
- System architecture diagrams
- Component interaction flows
- Data flow diagrams
- Security architecture
- Network topology

### API Documentation (08-docs/api/)
- API specifications
- Endpoint documentation
- Request/response examples
- Authentication flows

---

## 🔧 Operations & Maintenance

### Operational Runbooks (08-docs/runbooks/)
- Service deployment procedures
- Scaling operations
- Backup and restore
- Disaster recovery
- Incident response

### Helper Scripts (09-scripts/)
- **[09-scripts/README.md](09-scripts/README.md)** - Scripts documentation
- **[09-scripts/QUICKSTART.md](09-scripts/QUICKSTART.md)** - Scripts quick reference
- **[09-scripts/SCRIPTS-SUMMARY.md](09-scripts/SCRIPTS-SUMMARY.md)** - Scripts summary
- **[09-scripts/JENKINS-FLUX-SUMMARY.md](09-scripts/JENKINS-FLUX-SUMMARY.md)** - Jenkins and Flux integration

---

## 🔍 Troubleshooting

### Common Issues and Solutions

#### Infrastructure Issues
- **AWS Credentials**: See [01-setup/README.md](01-setup/README.md#troubleshooting)
- **Terraform Errors**: See [docs/guides/TERRAFORM_FIXES.md](docs/guides/TERRAFORM_FIXES.md)
- **Deployment Errors**: See [docs/guides/DEPLOYMENT_ERRORS_RESOLVED.md](docs/guides/DEPLOYMENT_ERRORS_RESOLVED.md)

#### Service Issues
- **Docker Issues**: Check component READMEs in [02-services/](02-services/)
- **Kubernetes Issues**: See [04-kubernetes/README.md](04-kubernetes/README.md)
- **CI/CD Issues**: See [05-cicd/README.md](05-cicd/README.md)

#### Monitoring Issues
- **Prometheus**: See [06-monitoring/README.md](06-monitoring/README.md)
- **Grafana**: Dashboard troubleshooting in monitoring documentation
- **Alerting**: AlertManager configuration guide

#### Security Issues
- **Policy Enforcement**: See [07-security/README.md](07-security/README.md)
- **Scanning Issues**: Trivy and SonarQube troubleshooting
- **Secret Management**: Vault setup guide

---

## 📊 Quick Reference Tables

### Service Endpoints

| Service | Port | Health Check | Metrics |
|---------|------|--------------|---------|
| User Service | 8080 | `/health` | `/metrics` |
| Auth Service | 3001 | `/health` | `/metrics` |
| Notification Service | 5000 | `/health` | `/metrics` |
| Analytics Service | 8081 | `/actuator/health` | `/actuator/prometheus` |
| Frontend | 3000 | `/` | N/A |

### Environment Configurations

| Environment | Replicas | Instance Type | Database | Cost/Month |
|-------------|----------|---------------|----------|------------|
| Local | 1 | N/A (Docker) | Local | $0 |
| Dev | 1 | t3.medium | db.t3.medium | ~$210 |
| Staging | 2 | t3.large | db.t3.large | ~$400 |
| Prod | 3+ | t3.xlarge | db.r5.xlarge | ~$700-1000 |

### Tool Versions

| Tool | Version | Purpose |
|------|---------|---------|
| Kubernetes | 1.28 | Container orchestration |
| Terraform | 1.6+ | Infrastructure as Code |
| Docker | 24.0+ | Containerization |
| AWS CLI | 2.13+ | AWS management |
| kubectl | 1.28+ | Kubernetes CLI |
| Helm | 3.12+ | Package manager |
| ArgoCD | 2.8+ | GitOps deployment |
| Prometheus | 2.47+ | Metrics collection |
| Grafana | 10.1+ | Visualization |

---

## 📝 Document Conventions

### Document Types

- **README.md** - Component introduction and overview
- **QUICKSTART.md** - Fast track setup guides
- **IMPLEMENTATION-COMPLETE.md** - Completion summaries
- **\*-COMPLETE.md** - Implementation completion status
- **\*_FIXES.md** - Troubleshooting and fixes
- **\*_CONFIG.md** - Configuration guides

### Status Indicators

- ✅ **Complete** - Fully implemented and tested
- 🔄 **In Progress** - Currently being implemented
- ⏳ **Planned** - Scheduled for future implementation
- 🔧 **Maintenance** - Ongoing maintenance mode

---

## 🎯 Getting Started Paths

### For Developers
1. [Tool Installation](01-setup/README.md)
2. [Local Development](08-deployment-scripts/local/)
3. [Service Documentation](02-services/)
4. [API Documentation](08-docs/api/)

### For DevOps Engineers
1. [Infrastructure Guide](03-infrastructure/README.md)
2. [Kubernetes Deployment](04-kubernetes/README.md)
3. [CI/CD Setup](05-cicd/README.md)
4. [Monitoring Setup](06-monitoring/README.md)

### For Security Engineers
1. [Security Overview](07-security/README.md)
2. [Policy Configuration](07-security/gatekeeper/)
3. [Scanning Setup](07-security/scanning/)
4. [Secret Management](07-security/vault/)

### For Operations
1. [Deployment Guide](08-deployment-scripts/README.md)
2. [Runbooks](08-docs/runbooks/)
3. [Monitoring Guide](06-monitoring/README.md)
4. [Troubleshooting](#-troubleshooting)

---

## 📞 Additional Resources

### External Documentation Links
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

### Community Resources
- AWS Documentation
- CNCF Projects
- DevSecOps Best Practices
- Security Compliance Guides

---

## 🔄 Documentation Updates

This documentation is continuously updated. Last update: **October 8, 2025**

To suggest improvements:
1. Review the relevant documentation
2. Identify gaps or outdated information
3. Submit updates or create issues
4. Follow documentation conventions

---

## ✅ Documentation Checklist

Use this checklist to ensure you have reviewed all relevant documentation:

### Initial Setup
- [ ] Read main [README.md](README.md)
- [ ] Review [Project Summary](docs/status/PROJECT-SUMMARY.md)
- [ ] Complete [Tool Installation](01-setup/README.md)
- [ ] Configure AWS credentials

### Deployment
- [ ] Choose deployment method (local or AWS)
- [ ] Review [Deployment Guide](08-deployment-scripts/README.md)
- [ ] Follow [Quick Start](08-deployment-scripts/QUICK-START.md)
- [ ] Verify deployment health

### Configuration
- [ ] Review service documentation in [02-services/](02-services/)
- [ ] Configure infrastructure in [03-infrastructure/](03-infrastructure/)
- [ ] Set up monitoring [06-monitoring/](06-monitoring/)
- [ ] Configure security [07-security/](07-security/)

### Operations
- [ ] Review [Runbooks](08-docs/runbooks/)
- [ ] Set up monitoring dashboards
- [ ] Configure alerting
- [ ] Test disaster recovery procedures

---

**📚 Happy Documentation Exploring!**

For questions or issues, refer to the troubleshooting sections in component-specific documentation.

---

**Last Updated**: October 8, 2025  
**Maintainer**: DevSecOps Platform Team  
**Version**: 1.0.0
