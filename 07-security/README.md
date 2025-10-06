# Security & Compliance Stack

Complete security and compliance solution for the DevSecOps platform with OPA policies, Gatekeeper constraints, Falco runtime security, secret management, and automated scanning.

## 📁 Directory Structure

```
07-security/
├── README.md                           # This file
├── opa/                                # Open Policy Agent
│   ├── deployment.yaml                # OPA deployment
│   ├── policies/                      # OPA policies
│   │   ├── required-labels.rego      # Require specific labels
│   │   ├── resource-limits.rego      # Enforce resource limits
│   │   ├── allowed-repos.rego        # Restrict image repositories
│   │   └── network-policies.rego     # Enforce network policies
│   └── configmap.yaml                # OPA configuration
├── gatekeeper/                        # Gatekeeper (OPA for K8s)
│   ├── install.yaml                  # Gatekeeper installation
│   ├── constraint-templates/         # Constraint templates
│   │   ├── required-labels.yaml     # Template for required labels
│   │   ├── container-limits.yaml    # Template for resource limits
│   │   ├── allowed-repos.yaml       # Template for allowed repos
│   │   ├── https-only.yaml          # Template for HTTPS ingress
│   │   └── deny-privileged.yaml     # Template to deny privileged pods
│   └── constraints/                  # Constraint instances
│       ├── required-labels.yaml     # Enforce labels on all resources
│       ├── container-limits.yaml    # Enforce limits on containers
│       ├── allowed-repos.yaml       # Enforce allowed repositories
│       ├── https-only.yaml          # Enforce HTTPS on ingress
│       └── deny-privileged.yaml     # Deny privileged containers
├── falco/                            # Runtime Security
│   ├── daemonset.yaml               # Falco DaemonSet
│   ├── configmap.yaml               # Falco configuration
│   ├── rules/                       # Custom Falco rules
│   │   ├── application-rules.yaml  # Application-specific rules
│   │   └── k8s-audit-rules.yaml    # Kubernetes audit rules
│   └── falcosidekick/              # Falco alert forwarder
│       ├── deployment.yaml         # Falcosidekick deployment
│       └── configmap.yaml          # Alert routing configuration
├── vault/                            # Secret Management
│   ├── deployment.yaml              # Vault deployment
│   ├── configmap.yaml               # Vault configuration
│   ├── service.yaml                 # Vault service
│   ├── secrets-operator/            # External Secrets Operator
│   │   ├── deployment.yaml         # Operator deployment
│   │   └── secret-store.yaml       # Secret store configuration
│   └── policies/                    # Vault policies
│       ├── app-policy.hcl          # Application access policy
│       └── admin-policy.hcl        # Admin access policy
├── trivy/                           # Container Scanning
│   ├── operator.yaml                # Trivy Operator
│   ├── configmap.yaml              # Scanning configuration
│   └── policies/                    # Scanning policies
│       ├── severity-policy.yaml    # Severity thresholds
│       └── ignore-policy.yaml      # CVE ignores
├── sonarqube/                       # Code Quality
│   ├── deployment.yaml             # SonarQube deployment
│   ├── postgresql.yaml             # PostgreSQL for SonarQube
│   ├── service.yaml                # SonarQube service
│   ├── ingress.yaml                # SonarQube ingress
│   └── quality-gates/              # Quality gate configs
│       └── default-gate.json       # Default quality gate
├── policies/                        # Security Policies
│   ├── pod-security-policy.yaml    # Pod security policies
│   ├── network-policy.yaml         # Network policies
│   ├── rbac.yaml                   # RBAC policies
│   └── admission-controller.yaml   # Admission controller config
├── compliance/                      # Compliance Reports
│   ├── cis-benchmark.yaml          # CIS benchmark scanner
│   ├── reports/                    # Report templates
│   │   └── compliance-report.md    # Compliance report template
│   └── scripts/                    # Compliance scripts
│       └── generate-report.sh      # Report generation script
└── scripts/                         # Helper Scripts
    ├── deploy-security.sh          # Deploy security stack
    ├── scan-all.sh                 # Run all security scans
    └── vault-setup.sh              # Initialize Vault
```

## 🎯 Security Components Overview

### 1. **OPA (Open Policy Agent)**
- **Purpose**: Policy-based control for Kubernetes
- **Features**:
  - Rego policy language
  - Admission control
  - Policy validation
  - Audit logging
- **Policies**:
  - Required labels enforcement
  - Resource limits enforcement
  - Allowed image repositories
  - Network policy requirements

### 2. **Gatekeeper (OPA for Kubernetes)**
- **Purpose**: Kubernetes-native policy enforcement
- **Features**:
  - Constraint templates (reusable policies)
  - Constraint instances (policy applications)
  - Audit mode for testing
  - Violation reporting
- **Constraints**:
  - Required labels on all resources
  - Container resource limits
  - Allowed image repositories (ECR only)
  - HTTPS-only ingress
  - Deny privileged containers

### 3. **Falco (Runtime Security)**
- **Purpose**: Runtime threat detection for Kubernetes
- **Features**:
  - System call monitoring
  - Kubernetes audit log analysis
  - Custom rule engine
  - Real-time alerting via Falcosidekick
- **Rules**:
  - Unauthorized file access
  - Privilege escalation attempts
  - Sensitive file reads
  - Network anomalies
  - Container escapes

### 4. **Vault (Secret Management)**
- **Purpose**: Centralized secret management
- **Features**:
  - Dynamic secrets
  - Secret versioning
  - Access policies
  - Encryption as a service
  - Kubernetes auth integration
- **Integration**:
  - External Secrets Operator
  - IRSA for AWS
  - Auto-rotation
  - Audit logging

### 5. **Trivy Operator**
- **Purpose**: Continuous container vulnerability scanning
- **Features**:
  - In-cluster vulnerability scanning
  - CRD-based results
  - Automated scanning on deploy
  - Integration with admission control
- **Scan Types**:
  - Container images
  - Kubernetes configurations
  - IaC templates
  - SBOM generation

### 6. **SonarQube**
- **Purpose**: Code quality and security analysis
- **Features**:
  - Static code analysis
  - Security hotspot detection
  - Code smell identification
  - Technical debt tracking
  - Quality gates
- **Integration**:
  - GitHub Actions workflows
  - Branch analysis
  - Pull request decoration
  - Quality gate enforcement

## 🔐 Security Policies

### Pod Security Policies

**Restricted Profile** (Production):
```yaml
- No privileged containers
- Drop all capabilities
- Run as non-root
- Read-only root filesystem
- No host network/PID/IPC
- Allowed volume types: configMap, secret, emptyDir, persistentVolumeClaim
```

**Baseline Profile** (Staging):
```yaml
- No privileged containers
- Limited capabilities (NET_BIND_SERVICE)
- Run as non-root (optional)
- No host network/PID/IPC
```

**Privileged Profile** (Dev):
```yaml
- Allow all (for debugging)
```

### Network Policies

**Default Deny All**:
```yaml
- Deny all ingress traffic by default
- Deny all egress traffic by default
- Explicit allow rules required
```

**Service-Specific**:
```yaml
User Service:
  - Allow from: frontend, ingress
  - Allow to: auth-service, postgres, redis

Auth Service:
  - Allow from: all services
  - Allow to: postgres, redis

Notification Service:
  - Allow from: all services
  - Allow to: redis, external SMTP/SMS

Analytics Service:
  - Allow from: all services
  - Allow to: postgres, redis

Frontend:
  - Allow from: ingress
  - Allow to: all backend services
```

### RBAC Policies

**Namespace Admin**:
- Full access within namespace
- No cluster-wide permissions

**Developer**:
- Read pods, services, deployments
- No secrets access
- No production write access

**CI/CD Service Account**:
- Deploy to dev/staging only
- Read-only in production
- No RBAC modification

## 🚨 Falco Rules

### Critical Rules

**Shell in Container**:
```yaml
- rule: Shell Spawned in Container
  desc: Detect shell execution in container
  condition: spawned_process and container and proc.name in (shell_binaries)
  output: Shell spawned in container
  priority: WARNING
```

**Sensitive File Access**:
```yaml
- rule: Read Sensitive File
  desc: Detect read of sensitive files
  condition: open_read and fd.name in (sensitive_files)
  output: Sensitive file opened for reading
  priority: WARNING
```

**Privilege Escalation**:
```yaml
- rule: Privilege Escalation
  desc: Detect privilege escalation attempts
  condition: proc.name = sudo or proc.name = su
  output: Privilege escalation detected
  priority: CRITICAL
```

**Network Anomaly**:
```yaml
- rule: Unexpected Network Connection
  desc: Detect unexpected outbound connections
  condition: outbound and not proc.name in (allowed_processes)
  output: Unexpected network connection
  priority: WARNING
```

## 🔒 Vault Secret Management

### Secret Types

**Database Credentials**:
```
Path: secret/data/database/postgres
- username: encrypted
- password: dynamic (rotated every 90 days)
- connection_string: generated
```

**API Keys**:
```
Path: secret/data/api-keys
- twilio_key: encrypted
- smtp_password: encrypted
- aws_access_key: IAM-based (no storage)
```

**JWT Secrets**:
```
Path: secret/data/jwt
- access_token_secret: versioned
- refresh_token_secret: versioned
- rotation_date: tracked
```

### Access Policies

**Application Access**:
```hcl
path "secret/data/database/*" {
  capabilities = ["read"]
}
path "secret/data/api-keys/*" {
  capabilities = ["read"]
}
```

**Admin Access**:
```hcl
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "sys/*" {
  capabilities = ["read", "list"]
}
```

## 📊 Compliance & Auditing

### CIS Kubernetes Benchmark

**Master Node Security**:
- API server configuration
- Controller manager security
- Scheduler security
- etcd configuration

**Worker Node Security**:
- Kubelet configuration
- Container runtime security
- Network configuration
- File permissions

### Compliance Reports

**Daily Reports**:
- Vulnerability scan results
- Policy violations
- Failed admission attempts
- Audit log anomalies

**Weekly Reports**:
- Compliance score
- Remediation status
- Trend analysis
- Risk assessment

**Monthly Reports**:
- Executive summary
- Security posture
- Compliance status
- Recommendations

## 🔧 Setup Instructions

### 1. Install Gatekeeper

```bash
# Install Gatekeeper
kubectl apply -f 07-security/gatekeeper/install.yaml

# Wait for Gatekeeper to be ready
kubectl wait --for=condition=Ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=300s

# Apply constraint templates
kubectl apply -f 07-security/gatekeeper/constraint-templates/

# Apply constraints
kubectl apply -f 07-security/gatekeeper/constraints/

# Verify installation
kubectl get constrainttemplates
kubectl get constraints
```

### 2. Deploy Falco

```bash
# Deploy Falco
kubectl apply -f 07-security/falco/daemonset.yaml

# Deploy Falcosidekick for alerts
kubectl apply -f 07-security/falco/falcosidekick/

# Verify Falco is running
kubectl get pods -n falco -l app=falco

# Check Falco logs
kubectl logs -n falco -l app=falco --tail=50
```

### 3. Deploy Vault

```bash
# Deploy Vault
kubectl apply -f 07-security/vault/

# Initialize Vault
./07-security/scripts/vault-setup.sh

# Unseal Vault (save unseal keys securely)
kubectl exec -n vault vault-0 -- vault operator unseal <key1>
kubectl exec -n vault vault-0 -- vault operator unseal <key2>
kubectl exec -n vault vault-0 -- vault operator unseal <key3>

# Configure policies
kubectl exec -n vault vault-0 -- vault policy write app /vault/policies/app-policy.hcl
```

### 4. Install Trivy Operator

```bash
# Install Trivy Operator
kubectl apply -f 07-security/trivy/operator.yaml

# Verify installation
kubectl get pods -n trivy-system

# Check vulnerability reports
kubectl get vulnerabilityreports -A
```

### 5. Deploy SonarQube

```bash
# Deploy SonarQube
kubectl apply -f 07-security/sonarqube/

# Wait for SonarQube to be ready
kubectl wait --for=condition=Ready pod -l app=sonarqube -n sonarqube --timeout=600s

# Access SonarQube
kubectl port-forward -n sonarqube svc/sonarqube 9000:9000
# Open: http://localhost:9000
# Default credentials: admin/admin (change immediately)
```

## 🔍 Security Scanning

### Automated Scans

**Container Images** (On every push):
```bash
# Trivy scan in CI/CD
trivy image --severity HIGH,CRITICAL <image>

# Cosign verify
cosign verify --key cosign.pub <image>
```

**Infrastructure** (On PR):
```bash
# Terraform security
tfsec .
checkov -d .

# Kubernetes manifests
trivy config .
kubesec scan *.yaml
```

**Code Quality** (On PR):
```bash
# SonarQube analysis
sonar-scanner \
  -Dsonar.projectKey=devsecops \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://sonarqube:9000
```

**Secrets** (Daily):
```bash
# Secret scanning
gitleaks detect --source .
trufflehog git file://.
```

### Manual Scans

```bash
# Run all scans
./07-security/scripts/scan-all.sh

# Vulnerability scan
trivy image --format table <image>

# Policy validation
kubectl apply --dry-run=server -f manifest.yaml

# Compliance check
kubectl exec -n compliance cis-benchmark -- /bin/sh -c "kube-bench run --targets master,node"
```

## 📈 Metrics & Monitoring

### Security Metrics

**Policy Violations**:
```promql
gatekeeper_violations{enforcement_action="deny"}
```

**Vulnerability Count**:
```promql
trivy_vulnerability_count{severity="HIGH"}
trivy_vulnerability_count{severity="CRITICAL"}
```

**Falco Alerts**:
```promql
falco_alerts_total{priority="Critical"}
falco_alerts_total{priority="Warning"}
```

**Failed Admissions**:
```promql
rate(gatekeeper_admission_denied_total[5m])
```

### Dashboards

**Security Overview**:
- Total policy violations
- Critical vulnerabilities
- Falco alerts (last 24h)
- Failed admission attempts
- Secret rotation status

**Compliance Status**:
- CIS benchmark score
- Policy compliance rate
- Vulnerability remediation time
- Secret age distribution

## 🚨 Incident Response

### Security Alert Workflow

1. **Alert Triggered**: Falco/Gatekeeper detects violation
2. **Notification**: Send to Slack #security-alerts
3. **Triage**: Security team investigates
4. **Containment**: Isolate affected resources
5. **Remediation**: Apply fix
6. **Verification**: Validate fix
7. **Documentation**: Update runbook

### Common Incidents

**Privilege Escalation Attempt**:
```bash
# Check Falco logs
kubectl logs -n falco -l app=falco | grep "Privilege"

# Identify pod
kubectl get pods -A --field-selector status.phase=Running

# Isolate pod
kubectl label pod <pod-name> quarantine=true
kubectl annotate pod <pod-name> "security-violation=privilege-escalation"

# Investigate
kubectl exec -it <pod-name> -- /bin/sh

# Remediate
kubectl delete pod <pod-name>
```

**Vulnerable Image Deployed**:
```bash
# Check Trivy reports
kubectl get vulnerabilityreports -A

# Get vulnerability details
kubectl describe vulnerabilityreport <report-name>

# Update image
kubectl set image deployment/<deployment> <container>=<new-image>

# Verify
trivy image <new-image>
```

## 🎯 Best Practices

1. **Principle of Least Privilege**: Grant minimum required permissions
2. **Defense in Depth**: Multiple security layers
3. **Zero Trust**: Verify everything, trust nothing
4. **Immutable Infrastructure**: Replace, don't modify
5. **Secret Rotation**: Rotate secrets regularly (90 days max)
6. **Audit Everything**: Enable comprehensive logging
7. **Automate Security**: Integrate into CI/CD
8. **Regular Reviews**: Weekly security reviews
9. **Incident Drills**: Monthly security exercises
10. **Stay Updated**: Patch management process

## 🔧 Troubleshooting

### Gatekeeper Not Enforcing Policies

```bash
# Check Gatekeeper status
kubectl get pods -n gatekeeper-system

# Check constraint status
kubectl get constraints
kubectl describe <constraint-name>

# Check audit logs
kubectl logs -n gatekeeper-system -l control-plane=audit-controller

# Test constraint
kubectl apply --dry-run=server -f test-manifest.yaml
```

### Falco Not Generating Alerts

```bash
# Check Falco status
kubectl get pods -n falco

# Check Falco logs
kubectl logs -n falco -l app=falco

# Check Falcosidekick
kubectl logs -n falco -l app=falcosidekick

# Test rule
kubectl exec -it test-pod -- /bin/sh
```

### Vault Sealed

```bash
# Check Vault status
kubectl exec -n vault vault-0 -- vault status

# Unseal Vault
kubectl exec -n vault vault-0 -- vault operator unseal <key1>
kubectl exec -n vault vault-0 -- vault operator unseal <key2>
kubectl exec -n vault vault-0 -- vault operator unseal <key3>
```

## 📚 Additional Resources

- [OPA Documentation](https://www.openpolicyagent.org/docs/)
- [Gatekeeper Documentation](https://open-policy-agent.github.io/gatekeeper/)
- [Falco Documentation](https://falco.org/docs/)
- [Vault Documentation](https://www.vaultproject.io/docs)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [SonarQube Documentation](https://docs.sonarqube.org/)

## ✅ Task 10 Deliverables

- [x] Gatekeeper installation with 5 constraint templates
- [x] OPA policies for Kubernetes
- [x] Falco runtime security with custom rules
- [x] Vault secret management setup
- [x] Trivy Operator for vulnerability scanning
- [x] SonarQube code quality platform
- [x] Security policies (PSP, Network, RBAC)
- [x] Compliance scanning and reporting
- [x] Complete documentation

**Status**: Security hardening complete! 🔒
