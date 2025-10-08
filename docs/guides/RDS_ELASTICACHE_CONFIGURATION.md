# 🔧 Configuring Applications to Use RDS and ElastiCache

**Complete Guide to Connect Microservices to AWS-Managed Databases**

---

## 📋 Overview

This guide shows how to configure all microservices to use:
- **AWS RDS PostgreSQL** - Managed relational database
- **AWS ElastiCache Redis** - Managed in-memory cache

All services are pre-configured with environment variables to connect to RDS and ElastiCache. You just need to update the endpoints!

---

## 🎯 What's Already Configured

### ✅ Services Using RDS PostgreSQL

| Service | Language | Database Usage |
|---------|----------|----------------|
| **user-service** | Go | User data, authentication |
| **auth-service** | TypeScript | Sessions, tokens, audit logs |
| **notification-service** | Python | Notification history, templates |
| **analytics-service** | Java | Event data, analytics |

### ✅ Services Using ElastiCache Redis

| Service | Cache Usage |
|---------|-------------|
| **user-service** | User sessions, API rate limiting |
| **auth-service** | Token storage, session management |
| **notification-service** | Celery task queue, job results |
| **analytics-service** | Query caching, aggregated data |

---

## 🚀 Quick Start - Automated Configuration

### Step 1: Deploy Infrastructure

```bash
cd 03-infrastructure/terraform
terraform apply -var-file="environments/dev.tfvars"
```

This creates:
- RDS PostgreSQL instance (Multi-AZ)
- ElastiCache Redis cluster
- Security groups allowing EKS to connect
- Secrets Manager entries for credentials

### Step 2: Configure Services Automatically

```bash
cd 04-kubernetes/scripts
./configure-rds-redis.sh dev
```

**This script automatically**:
- ✅ Fetches RDS endpoint from Terraform
- ✅ Fetches ElastiCache endpoint from Terraform
- ✅ Retrieves credentials from AWS Secrets Manager
- ✅ Updates all Kubernetes ConfigMaps
- ✅ Creates Kubernetes Secrets
- ✅ Generates configuration summary

### Step 3: Deploy Services

```bash
cd ../overlays/dev
kubectl apply -k .
```

**Done!** Your services are now connected to RDS and ElastiCache.

---

## 📝 Manual Configuration (Alternative)

If you prefer to configure manually:

### Step 1: Get Database Endpoints

```bash
cd 03-infrastructure/terraform

# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
RDS_PORT=$(terraform output -raw rds_port)
RDS_DATABASE=$(terraform output -raw rds_database_name)

# Get ElastiCache endpoint
REDIS_ENDPOINT=$(terraform output -raw redis_primary_endpoint)
REDIS_PORT=$(terraform output -raw redis_port)

echo "RDS: $RDS_ENDPOINT:$RDS_PORT/$RDS_DATABASE"
echo "Redis: $REDIS_ENDPOINT:$REDIS_PORT"
```

### Step 2: Get Credentials

```bash
# Get RDS username
RDS_USERNAME=$(terraform output -raw rds_username)

# Get RDS password from Secrets Manager
RDS_PASSWORD_ARN=$(terraform output -raw rds_password_secret_arn)
RDS_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id "$RDS_PASSWORD_ARN" \
  --query 'SecretString' \
  --output text)

echo "Username: $RDS_USERNAME"
echo "Password: $RDS_PASSWORD"
```

### Step 3: Update ConfigMaps

Edit each service's ConfigMap:

**User Service** (`04-kubernetes/base/user-service/configmap.yaml`):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-service-config
data:
  db-host: "devsecops-dev-postgres.xxxx.us-east-1.rds.amazonaws.com"  # Replace with actual
  db-port: "5432"
  db-name: "devsecops_dev"
  redis-host: "devsecops-dev-redis.xxxx.cache.amazonaws.com"  # Replace with actual
  redis-port: "6379"
```

**Auth Service** (`04-kubernetes/base/auth-service/manifests.yaml`):
```yaml
# Find the ConfigMap section and update:
data:
  db-host: "devsecops-dev-postgres.xxxx.us-east-1.rds.amazonaws.com"
  db-port: "5432"
  db-name: "devsecops_dev"
  redis-host: "devsecops-dev-redis.xxxx.cache.amazonaws.com"
  redis-port: "6379"
```

Repeat for:
- `notification-service/manifests.yaml`
- `analytics-service/manifests.yaml`

### Step 4: Update Secrets

Update `04-kubernetes/base/shared-secrets.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: rds-credentials
  namespace: devsecops
type: Opaque
stringData:
  username: dbadmin
  password: YOUR_ACTUAL_PASSWORD_HERE

---
apiVersion: v1
kind: Secret
metadata:
  name: redis-credentials
  namespace: devsecops
type: Opaque
stringData:
  auth-token: ""  # Leave empty if no auth_token configured
```

### Step 5: Apply Configuration

```bash
kubectl create namespace devsecops --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f 04-kubernetes/base/shared-secrets.yaml
kubectl apply -k 04-kubernetes/overlays/dev
```

---

## 🔍 Verify Configuration

### Check Services Are Running

```bash
kubectl get pods -n devsecops
```

Expected output:
```
NAME                                    READY   STATUS    RESTARTS   AGE
user-service-xxxxx-xxxxx                1/1     Running   0          2m
auth-service-xxxxx-xxxxx                1/1     Running   0          2m
notification-service-xxxxx-xxxxx        1/1     Running   0          2m
analytics-service-xxxxx-xxxxx           1/1     Running   0          2m
```

### Check Pod Logs for Database Connection

```bash
# User Service (Go)
kubectl logs -n devsecops -l app=user-service --tail=50

# Should see:
# Connected to PostgreSQL: devsecops-dev-postgres...
# Connected to Redis: devsecops-dev-redis...

# Auth Service (Node.js)
kubectl logs -n devsecops -l app=auth-service --tail=50

# Should see:
# Database connection established
# Redis client connected

# Notification Service (Python)
kubectl logs -n devsecops -l app=notification-service --tail=50

# Should see:
# Connected to database: devsecops_dev
# Celery connected to redis://...

# Analytics Service (Java)
kubectl logs -n devsecops -l app=analytics-service --tail=50

# Should see:
# HikariPool-1 - Start completed.
# Lettuce: Connecting to Redis...
```

### Test Database Connectivity

```bash
# Exec into a pod
kubectl exec -it -n devsecops deployment/user-service -- /bin/sh

# Test PostgreSQL connection (if psql available)
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT version();"

# Test Redis connection (if redis-cli available)
redis-cli -h $REDIS_HOST -p $REDIS_PORT ping
```

### Check ConfigMaps

```bash
# View ConfigMaps
kubectl get configmap -n devsecops
kubectl describe configmap user-service-config -n devsecops

# View Secrets (values will be base64 encoded)
kubectl get secrets -n devsecops
kubectl get secret rds-credentials -n devsecops -o yaml
```

---

## 📊 Environment Variables Reference

### User Service (Go)

| Variable | Source | Purpose |
|----------|--------|---------|
| `DB_HOST` | ConfigMap | RDS endpoint |
| `DB_PORT` | ConfigMap | RDS port (5432) |
| `DB_NAME` | ConfigMap | Database name |
| `DB_USER` | Secret | RDS username |
| `DB_PASSWORD` | Secret | RDS password |
| `REDIS_HOST` | ConfigMap | ElastiCache endpoint |
| `REDIS_PORT` | ConfigMap | Redis port (6379) |
| `REDIS_PASSWORD` | Secret | Redis auth token |

### Auth Service (Node.js/TypeScript)

| Variable | Source | Purpose |
|----------|--------|---------|
| `DB_HOST` | ConfigMap | RDS endpoint |
| `DB_PORT` | ConfigMap | RDS port |
| `DB_NAME` | ConfigMap | Database name |
| `DB_USER` | Secret | RDS username |
| `DB_PASSWORD` | Secret | RDS password |
| `REDIS_HOST` | ConfigMap | ElastiCache endpoint |
| `REDIS_PORT` | ConfigMap | Redis port |
| `REDIS_PASSWORD` | Secret | Redis auth token |

### Notification Service (Python)

| Variable | Source | Purpose |
|----------|--------|---------|
| `DB_HOST` | ConfigMap | RDS endpoint |
| `DB_PORT` | ConfigMap | RDS port |
| `DB_NAME` | ConfigMap | Database name |
| `DB_USER` | Secret | RDS username |
| `DB_PASSWORD` | Secret | RDS password |
| `REDIS_HOST` | ConfigMap | ElastiCache endpoint (Celery broker) |
| `REDIS_PORT` | ConfigMap | Redis port |
| `REDIS_PASSWORD` | Secret | Redis auth token |

### Analytics Service (Java/Spring Boot)

| Variable | Source | Purpose |
|----------|--------|---------|
| `SPRING_DATASOURCE_URL` | Constructed | JDBC connection string |
| `DB_HOST` | ConfigMap | RDS endpoint (used in URL) |
| `DB_PORT` | ConfigMap | RDS port (used in URL) |
| `DB_NAME` | ConfigMap | Database name (used in URL) |
| `SPRING_DATASOURCE_USERNAME` | Secret | RDS username |
| `SPRING_DATASOURCE_PASSWORD` | Secret | RDS password |
| `SPRING_DATA_REDIS_HOST` | ConfigMap | ElastiCache endpoint |
| `SPRING_DATA_REDIS_PORT` | ConfigMap | Redis port |
| `SPRING_DATA_REDIS_PASSWORD` | Secret | Redis auth token |

---

## 🗄️ Database Schema Initialization

### Option 1: Run Migrations Automatically

Each service includes database migrations:

**User Service (Go)**:
```go
// Auto-migrates on startup
db.AutoMigrate(&User{}, &Role{})
```

**Auth Service (TypeScript)**:
```bash
# Migrations in src/migrations/
kubectl exec -it -n devsecops deployment/auth-service -- npm run migrate
```

**Notification Service (Python)**:
```bash
# Flask-Migrate
kubectl exec -it -n devsecops deployment/notification-service -- flask db upgrade
```

**Analytics Service (Java)**:
```yaml
# application.yml
spring:
  jpa:
    hibernate:
      ddl-auto: update  # Auto-creates tables
```

### Option 2: Initialize Manually

```bash
# Connect to RDS
RDS_ENDPOINT=$(cd 03-infrastructure/terraform && terraform output -raw rds_endpoint)
RDS_USERNAME=$(cd 03-infrastructure/terraform && terraform output -raw rds_username)

# Run init script
kubectl run -it --rm psql-client \
  --image=postgres:15 \
  --restart=Never \
  --namespace=devsecops \
  -- psql -h $RDS_ENDPOINT -U $RDS_USERNAME -d devsecops_dev -f /scripts/init-db.sql
```

---

## 🔐 Security Best Practices

### 1. Use AWS Secrets Manager

✅ **Already Configured!**
- RDS password stored in Secrets Manager
- Retrieved automatically by Terraform
- Injected as Kubernetes Secret

### 2. Enable Encryption

✅ **Already Configured!**
- RDS encrypted at rest with KMS
- ElastiCache encrypted in transit (TLS)
- Secrets encrypted in etcd

### 3. Network Security

✅ **Already Configured!**
- RDS in private subnets only
- ElastiCache in private subnets only
- Security groups allow only EKS node access
- No public internet access

### 4. Rotate Credentials

```bash
# Rotate RDS password
cd 03-infrastructure/terraform
terraform taint aws_secretsmanager_secret_version.rds_password
terraform apply

# Update Kubernetes secret
./04-kubernetes/scripts/configure-rds-redis.sh dev
kubectl rollout restart deployment -n devsecops --all
```

---

## 🐛 Troubleshooting

### Issue: Pods Can't Connect to RDS

**Symptoms**:
```
Error: could not connect to server: Connection timed out
```

**Solutions**:

1. **Check Security Groups**:
```bash
# Verify EKS nodes can access RDS
cd 03-infrastructure/terraform
terraform output rds_security_group_id
terraform output eks_node_security_group_id

# Security group should allow 5432 from EKS nodes
```

2. **Verify Endpoints**:
```bash
# Check RDS is accessible
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
nc -zv $RDS_ENDPOINT 5432
```

3. **Check DNS Resolution**:
```bash
kubectl run -it --rm debug \
  --image=busybox \
  --restart=Never \
  --namespace=devsecops \
  -- nslookup $RDS_ENDPOINT
```

### Issue: Pods Can't Connect to ElastiCache

**Symptoms**:
```
Error: ECONNREFUSED or connection timeout to Redis
```

**Solutions**:

1. **Check Security Groups**:
```bash
# Verify EKS nodes can access ElastiCache
terraform output redis_security_group_id

# Security group should allow 6379 from EKS nodes
```

2. **Verify Endpoint**:
```bash
# Check Redis is accessible
REDIS_ENDPOINT=$(terraform output -raw redis_primary_endpoint)
nc -zv $REDIS_ENDPOINT 6379
```

3. **Test from Pod**:
```bash
kubectl run -it --rm redis-cli \
  --image=redis:7-alpine \
  --restart=Never \
  --namespace=devsecops \
  -- redis-cli -h $REDIS_ENDPOINT -p 6379 ping
```

### Issue: Wrong Database Credentials

**Symptoms**:
```
Error: password authentication failed for user "dbadmin"
```

**Solutions**:

1. **Verify Secret**:
```bash
kubectl get secret rds-credentials -n devsecops -o jsonpath='{.data.username}' | base64 -d
kubectl get secret rds-credentials -n devsecops -o jsonpath='{.data.password}' | base64 -d
```

2. **Update from Secrets Manager**:
```bash
cd 04-kubernetes/scripts
./configure-rds-redis.sh dev

# This re-fetches credentials
```

3. **Restart Pods**:
```bash
kubectl rollout restart deployment -n devsecops --all
```

### Issue: Database Not Initialized

**Symptoms**:
```
Error: relation "users" does not exist
```

**Solutions**:

1. **Run Migrations**:
```bash
# For each service
kubectl exec -it -n devsecops deployment/auth-service -- npm run migrate
kubectl exec -it -n devsecops deployment/notification-service -- flask db upgrade
```

2. **Check Auto-Migration Logs**:
```bash
kubectl logs -n devsecops -l app=user-service | grep -i migrate
kubectl logs -n devsecops -l app=analytics-service | grep -i hibernate
```

---

## 📊 Monitoring Database Connections

### CloudWatch Metrics

View RDS and ElastiCache metrics:

```bash
# RDS
aws rds describe-db-instances \
  --db-instance-identifier devsecops-dev-postgres \
  --query 'DBInstances[0].DBInstanceStatus'

# ElastiCache
aws elasticache describe-replication-groups \
  --replication-group-id devsecops-dev-redis \
  --query 'ReplicationGroups[0].Status'
```

### Kubernetes Metrics

```bash
# Connection pool metrics (if exposed)
kubectl exec -n devsecops deployment/user-service -- \
  curl localhost:8080/metrics | grep -i db

# Service health
kubectl get pods -n devsecops -o wide
kubectl top pods -n devsecops
```

---

## 🎯 Summary

### What You've Configured

✅ **All 4 microservices** connected to:
- AWS RDS PostgreSQL (Multi-AZ)
- AWS ElastiCache Redis (Multi-AZ)

✅ **Security**:
- Credentials from AWS Secrets Manager
- Encrypted connections
- Private subnet deployment
- Kubernetes Secrets for credential injection

✅ **High Availability**:
- Multi-AZ database deployment
- Read replicas ready (if needed)
- Automatic failover
- Connection pooling

### Connection Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│ Kubernetes  │────▶│   Security   │────▶│     RDS     │
│    Pods     │     │    Groups    │     │  (Private)  │
│   (EKS)     │     │              │     │  Subnet     │
└─────────────┘     └──────────────┘     └─────────────┘
       │
       │            ┌──────────────┐     ┌─────────────┐
       └───────────▶│   Security   │────▶│ ElastiCache │
                    │    Groups    │     │  (Private)  │
                    │              │     │  Subnet     │
                    └──────────────┘     └─────────────┘
```

---

## 📞 Need Help?

- **Script Issues**: Check `04-kubernetes/scripts/configure-rds-redis.sh`
- **Infrastructure**: See `03-infrastructure/README.md`
- **Kubernetes**: See `04-kubernetes/README.md`
- **Service Code**: Check `02-services/<service>/README.md`

---

**🎉 Your applications are now using AWS-managed RDS and ElastiCache!**

**Ready for production workloads with:**
- High availability
- Automatic backups
- Encryption at rest and in transit
- Multi-AZ redundancy
- Managed updates and patching

---

**Last Updated**: October 8, 2025  
**Status**: ✅ Production Ready
