# DevSecOps Scripts - Comprehensive Summary

Complete reference for all automation scripts in the DevSecOps project.

## Overview

This directory contains 19 scripts divided into three categories:

- **Core Deployment Scripts (8):** Main deployment and development workflows
- **Management Scripts (4):** Operational and maintenance tasks
- **Utility Scripts (7):** Helper tools and validation

---

## Core Deployment Scripts

### 00-deploy-all.sh

**Complete automated deployment**

**Purpose:**
Deploy the entire DevSecOps platform from scratch to AWS with one command.

**What it does:**

- Validates all prerequisites
- Builds Docker images for all services
- Runs comprehensive security scans
- Pushes images to Docker Hub
- Deploys AWS infrastructure via Terraform
- Deploys Kubernetes manifests
- Installs monitoring tools (Prometheus, Grafana)
- Installs security tools (Falco, Trivy)
- Configures GitOps with ArgoCD
- Runs smoke tests
- Generates deployment summary report

**Usage:**

```bash
./00-deploy-all.sh <environment>
```

**Arguments:**

- `environment`: dev, staging, or prod

**Duration:** ~45 minutes

**Prerequisites:**

- Docker, Docker Compose
- Terraform 1.6+
- kubectl 1.28+
- AWS CLI configured
- Helm 3.0+

**Output:**

- Logs to `logs/deploy-all.log`
- Summary report at end
- All service endpoints

---

### 01-start-local.sh

**Start local development environment**

**Purpose:**
Launch all services locally using Docker Compose for development and testing.

**What it does:**

- Validates Docker and Docker Compose installation
- Checks if required ports are available (3000-3004, 5432, 6379, 9092)
- Starts all services with docker-compose
- Initializes PostgreSQL database
- Waits for all services to become healthy
- Displays access URLs for all services

**Usage:**

```bash
./01-start-local.sh
```

**Duration:** ~10 minutes

**Services Started:**

- Frontend (React) - Port 3000
- Auth Service (Node.js) - Port 3001
- User Service (Go) - Port 3002
- Analytics Service (Java) - Port 3003
- Notification Service (Python) - Port 3004
- PostgreSQL - Port 5432
- Redis - Port 6379
- Kafka - Port 9092

**Output:**

- Service URLs printed to console
- Logs to `logs/start-local.log`

---

### 02-run-tests.sh

**Run comprehensive test suite**

**Purpose:**
Execute all tests across all services to verify functionality.

**What it does:**

- Runs Go tests for user-service
- Runs Jest tests for auth-service
- Runs pytest for notification-service
- Runs Maven tests for analytics-service
- Runs Vitest for frontend
- Generates coverage reports
- Summarizes test results

**Usage:**

```bash
./02-run-tests.sh [OPTIONS]
```

**Options:**

- `--service <name>`: Run tests for specific service only
- `--coverage`: Generate detailed coverage report
- `--verbose`: Show detailed test output

**Duration:** ~5 minutes

**Test Frameworks:**

- Go: `go test`
- Node.js: `npm test` (Jest)
- Python: `pytest`
- Java: `mvn test`
- React: `npm test` (Vitest)

**Output:**

- Test results summary
- Coverage reports in `coverage/` directory
- Logs to `logs/run-tests.log`

---

### 03-build-images.sh

**Build all Docker images**

**Purpose:**
Build optimized Docker images for all services with proper tagging.

**What it does:**

- Builds Docker images for all services
- Tags images with git commit hash
- Tags images with 'latest'
- Uses multi-stage builds for optimization
- Leverages Docker build cache
- Reports image sizes
- Provides build statistics

**Usage:**

```bash
./03-build-images.sh [OPTIONS]
```

**Options:**

- `--service <name>`: Build specific service only
- `--no-cache`: Build without cache
- `--tag <tag>`: Use custom tag

**Duration:** ~15 minutes

**Images Built:**

- `khaledhawil/frontend:latest`
- `khaledhawil/auth-service:latest`
- `khaledhawil/user-service:latest`
- `khaledhawil/analytics-service:latest`
- `khaledhawil/notification-service:latest`

**Output:**

- Image names and sizes
- Build time statistics
- Logs to `logs/build-images.log`

---

### 04-scan-security.sh

**Security vulnerability scanning**

**Purpose:**
Scan all images and code for security vulnerabilities using Trivy.

**What it does:**

- Scans Docker images for vulnerabilities
- Scans filesystem for security issues
- Checks dependencies for known CVEs
- Generates JSON and HTML reports
- Categorizes by severity (CRITICAL, HIGH, MEDIUM, LOW)
- Optional fail-on-high mode

**Usage:**

```bash
./04-scan-security.sh [OPTIONS]
```

**Options:**

- `--image <name>`: Scan specific image only
- `--severity <level>`: Filter by severity (CRITICAL, HIGH)
- `--fail-on-high`: Exit with error if HIGH or CRITICAL found

**Duration:** ~10 minutes

**Scan Types:**

- Container image scanning
- Filesystem scanning
- Dependency scanning (npm, pip, maven, go modules)
- Configuration scanning

**Output:**

- Vulnerability summary
- Reports in `security-reports/` directory
- Logs to `logs/security-scan.log`

---

### 05-deploy-infrastructure.sh

**Deploy AWS infrastructure**

**Purpose:**
Deploy complete AWS infrastructure using Terraform.

**What it does:**

- Initializes Terraform with S3 backend
- Creates/selects workspace for environment
- Validates Terraform configuration
- Generates execution plan
- Applies infrastructure changes
- Creates VPC and networking
- Provisions EKS cluster
- Sets up RDS PostgreSQL
- Sets up ElastiCache Redis
- Configures IAM roles and policies
- Updates kubeconfig for kubectl access

**Usage:**

```bash
./05-deploy-infrastructure.sh <environment>
```

**Arguments:**

- `environment`: dev, staging, or prod

**Duration:** ~20 minutes

**Infrastructure Created:**

- VPC with public and private subnets
- EKS cluster (Kubernetes 1.28)
- RDS PostgreSQL (Multi-AZ for prod)
- ElastiCache Redis (Clustered for prod)
- NAT Gateway
- Internet Gateway
- Security Groups
- IAM roles and policies

**Output:**

- Infrastructure endpoints
- Database connection strings
- EKS cluster info
- Logs to `logs/deploy-infrastructure.log`

---

### 06-deploy-kubernetes.sh

**Deploy Kubernetes resources**

**Purpose:**
Deploy all application manifests to Kubernetes cluster.

**What it does:**

- Creates namespaces
- Creates secrets from AWS Secrets Manager
- Applies Kustomize overlays for environment
- Deploys all service deployments
- Creates services and ingress
- Configures autoscaling (HPA)
- Waits for all deployments to be ready
- Verifies pod status

**Usage:**

```bash
./06-deploy-kubernetes.sh <environment>
```

**Arguments:**

- `environment`: dev, staging, or prod

**Duration:** ~15 minutes

**Resources Deployed:**

- Deployments (all services)
- Services (ClusterIP and LoadBalancer)
- Ingress with TLS
- ConfigMaps
- Secrets
- HorizontalPodAutoscalers
- NetworkPolicies

**Output:**

- Deployment status
- Pod list
- Service endpoints
- Ingress URLs
- Logs to `logs/deploy-kubernetes.log`

---

### 07-setup-gitops.sh

**Setup ArgoCD GitOps**

**Purpose:**
Install and configure ArgoCD for continuous deployment.

**What it does:**

- Installs ArgoCD in argocd namespace
- Waits for ArgoCD to be ready
- Applies ArgoCD configuration
- Creates ArgoCD projects
- Creates applications for all services
- Configures GitHub repository access
- Enables auto-sync
- Retrieves admin password
- Provides UI access instructions

**Usage:**

```bash
./07-setup-gitops.sh <environment>
```

**Arguments:**

- `environment`: dev, staging, or prod

**Duration:** ~10 minutes

**Applications Created:**

- frontend-app
- auth-service-app
- user-service-app
- analytics-service-app
- notification-service-app
- monitoring-app
- security-app

**Output:**

- ArgoCD UI URL
- Admin username and password
- Application sync status
- Logs to `logs/setup-gitops.log`

---

## Management Scripts

### stop-local.sh

**Stop local services**

**Purpose:**
Stop all locally running Docker Compose services.

**What it does:**

- Stops all containers
- Removes containers
- Preserves volumes
- Shows stopped services

**Usage:**

```bash
./stop-local.sh [OPTIONS]
```

**Options:**

- `--volumes`: Remove volumes too (destructive)

**Duration:** ~1 minute

---

### clean-all.sh

**Clean up all resources**

**Purpose:**
Remove all Docker resources and clean up local environment.

**What it does:**

- Stops all containers
- Removes all containers
- Removes all volumes
- Removes all networks
- Removes dangling images
- Cleans Docker system
- Removes log files
- Removes test reports

**Usage:**

```bash
./clean-all.sh [OPTIONS]
```

**Options:**

- `--full`: Also remove all images and build cache

**Duration:** ~2 minutes

**Warning:** This is destructive! Use with caution.

---

### health-check.sh

**Check service health**

**Purpose:**
Verify health of all running services.

**What it does:**

- Checks Docker services (local)
- Checks Kubernetes pods (cluster)
- Queries health endpoints
- Tests database connections
- Verifies Redis connectivity
- Checks Kafka status
- Reports unhealthy services

**Usage:**

```bash
./health-check.sh [OPTIONS]
```

**Options:**

- `--local`: Check local services only
- `--cluster`: Check Kubernetes services only
- `--detailed`: Show detailed health info

**Duration:** ~2 minutes

**Output:**

- Service status table
- Health check results
- Recommendations for issues

---

### view-logs.sh

**View service logs**

**Purpose:**
Tail logs from all services.

**What it does:**

- Shows logs from local Docker services
- Shows logs from Kubernetes pods
- Filters logs by service
- Follows logs in real-time
- Shows last N lines

**Usage:**

```bash
./view-logs.sh [OPTIONS]
```

**Options:**

- `--service <name>`: Show logs for specific service
- `--lines <n>`: Show last n lines (default: 100)
- `--follow`: Follow log output
- `--since <time>`: Show logs since time (e.g., "5m")

**Usage Examples:**

```bash
# View all logs
./view-logs.sh

# Follow auth-service logs
./view-logs.sh --service auth-service --follow

# View last 50 lines
./view-logs.sh --lines 50

# View logs from last 5 minutes
./view-logs.sh --since 5m
```

---

## Utility Scripts

### setup-prerequisites.sh

**Install required tools**

**Purpose:**
Install all tools required for the DevSecOps platform.

**What it does:**

- Detects operating system
- Checks existing installations
- Installs missing tools
- Verifies installations
- Configures tools

**Tools Installed:**

- Docker 20.10+
- Docker Compose 2.0+
- Terraform 1.6+
- kubectl 1.28+
- Helm 3.0+
- AWS CLI 2.0+
- Trivy (latest)
- jq, yq
- k9s (optional)

**Usage:**

```bash
./setup-prerequisites.sh [OPTIONS]
```

**Options:**

- `--check-only`: Only check, don't install
- `--minimal`: Install only essential tools

**Duration:** ~10 minutes

---

### push-images.sh

**Push images to registry**

**Purpose:**
Push built Docker images to Docker Hub.

**What it does:**

- Logs into Docker Hub
- Tags images with registry prefix
- Pushes all service images
- Pushes multiple tags (version, latest)
- Verifies push success

**Usage:**

```bash
./push-images.sh <username> [OPTIONS]
```

**Arguments:**

- `username`: Docker Hub username (default: khaledhawil)

**Options:**

- `--image <name>`: Push specific image only
- `--tag <tag>`: Push specific tag

**Duration:** ~10 minutes

---

### run-smoke-tests.sh

**Run smoke tests**

**Purpose:**
Execute post-deployment smoke tests to verify the platform is operational.

**What it does:**

- Tests all service endpoints
- Verifies authentication flow
- Tests database connectivity
- Verifies cache operations
- Tests message queue
- Checks monitoring endpoints
- Validates ingress routing

**Usage:**

```bash
./run-smoke-tests.sh <environment>
```

**Arguments:**

- `environment`: dev, staging, or prod

**Duration:** ~5 minutes

**Tests Performed:**

- Health check endpoints
- API gateway routing
- Database read/write
- Cache read/write
- Authentication token flow
- Service-to-service communication

**Output:**

- Test results summary
- Pass/fail for each test
- Logs to `logs/smoke-tests.log`

---

### validate-project.sh

**Validate project setup**

**Purpose:**
Validate that the project is properly configured and all files exist.

**What it does:**

- Checks directory structure
- Validates script existence
- Verifies configuration files
- Checks Docker Compose file
- Validates Kubernetes manifests
- Checks Terraform files
- Validates environment variables

**Usage:**

```bash
./validate-project.sh
```

**Duration:** ~1 minute

**Validation Checks:**

- All required scripts present
- Scripts have execute permissions
- Configuration files exist
- Required directories present
- No syntax errors in YAML files

**Output:**

- Validation summary
- List of issues found
- Recommendations

---

### help.sh

**Quick reference guide**

**Purpose:**
Display quick reference information for all scripts.

**What it does:**

- Lists all available scripts
- Shows usage examples
- Displays common commands
- Provides troubleshooting tips

**Usage:**

```bash
./help.sh [SCRIPT_NAME]
```

**Arguments:**

- `SCRIPT_NAME` (optional): Show help for specific script

**Examples:**

```bash
# Show all scripts
./help.sh

# Show help for specific script
./help.sh 00-deploy-all.sh
```

---

## Script Dependencies

### Dependency Graph

```
00-deploy-all.sh
├── 03-build-images.sh
├── 04-scan-security.sh
├── push-images.sh
├── 05-deploy-infrastructure.sh
├── 06-deploy-kubernetes.sh
├── 07-setup-gitops.sh
└── run-smoke-tests.sh
```

### Tool Requirements

| Script | Docker | Terraform | kubectl | AWS CLI | Helm |
|--------|--------|-----------|---------|---------|------|
| 00-deploy-all.sh | Yes | Yes | Yes | Yes | Yes |
| 01-start-local.sh | Yes | No | No | No | No |
| 02-run-tests.sh | Yes | No | No | No | No |
| 03-build-images.sh | Yes | No | No | No | No |
| 04-scan-security.sh | Yes | No | No | No | No |
| 05-deploy-infrastructure.sh | No | Yes | Yes | Yes | No |
| 06-deploy-kubernetes.sh | No | No | Yes | Yes | No |
| 07-setup-gitops.sh | No | No | Yes | No | Yes |

---

## Environment Support

All scripts support three environments:

- **dev**: Development environment (minimal resources)
- **staging**: Staging environment (production-like)
- **prod**: Production environment (HA, multi-AZ)

Specify environment as an argument:

```bash
./script-name.sh <environment>
```

---

## Logging

All scripts log to the `logs/` directory:

```
logs/
├── deploy-all.log
├── start-local.log
├── run-tests.log
├── build-images.log
├── security-scan.log
├── deploy-infrastructure.log
├── deploy-kubernetes.log
├── setup-gitops.log
└── smoke-tests.log
```

View logs:

```bash
tail -f logs/script-name.log
```

---

## Configuration Files

Scripts use these configuration files:

- `.env`: Environment variables
- `docker-compose.yml`: Local services configuration
- Terraform files: Infrastructure configuration
- Kustomize overlays: Kubernetes configuration
- ArgoCD manifests: GitOps configuration

---

## Exit Codes

All scripts use standard exit codes:

- `0`: Success
- `1`: General error
- `2`: Missing prerequisites
- `3`: Configuration error
- `4`: Deployment failure
- `5`: Validation failure

---

## Best Practices

1. Always run `setup-prerequisites.sh` first
2. Use `validate-project.sh` before deployment
3. Test locally with `01-start-local.sh` before AWS deployment
4. Run `04-scan-security.sh` before pushing images
5. Use `health-check.sh` after deployment
6. Monitor logs during deployment
7. Run `run-smoke-tests.sh` after deployment

---

## Troubleshooting

### Common Issues

**Permission Denied:**

```bash
chmod +x *.sh
```

**Docker Not Running:**

```bash
sudo systemctl start docker
```

**AWS Credentials Not Found:**

```bash
aws configure
```

**Terraform State Locked:**

```bash
cd ../03-infrastructure/terraform
terraform force-unlock <lock-id>
```

**Kubernetes Context Wrong:**

```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

---

## Support

For detailed information about each script:

```bash
./help.sh <script-name>
```

For general project documentation:

- [Main README](README.md)
- [Quick Start Guide](QUICKSTART.md)
- [Project Documentation](../README.md)

---

Username configured throughout: khaledhawil

All scripts are production-ready and tested!
