# Kubernetes Manifests

This directory contains all Kubernetes manifests for deploying the DevSecOps microservices platform to EKS.

## 📁 Directory Structure

```
04-kubernetes/
├── README.md                    # This file
├── base/                        # Base Kubernetes manifests (environment-agnostic)
│   ├── kustomization.yaml      # Base kustomize configuration
│   ├── namespace.yaml          # Namespace definition
│   ├── user-service/           # User service manifests
│   ├── auth-service/           # Auth service manifests
│   ├── notification-service/   # Notification service manifests
│   ├── analytics-service/      # Analytics service manifests
│   ├── frontend/               # Frontend manifests
│   └── ingress/                # Shared ingress configuration
├── overlays/                   # Environment-specific configurations
│   ├── dev/                    # Development environment
│   ├── staging/                # Staging environment
│   └── prod/                   # Production environment
└── scripts/                    # Helper scripts
    ├── deploy.sh               # Deployment script
    └── cleanup.sh              # Cleanup script
```

## 🎯 Architecture Overview

### Microservices
1. **User Service** (Go) - Port 8080
2. **Auth Service** (Node.js) - Port 3000
3. **Notification Service** (Python) - Port 5000
4. **Analytics Service** (Java) - Port 8081
5. **Frontend** (React) - Port 80

### Shared Resources
- **PostgreSQL** (RDS) - Shared database
- **Redis** (ElastiCache) - Shared cache
- **Ingress Controller** - AWS Load Balancer Controller
- **Service Mesh** - Optional (Istio/Linkerd)

## 📦 Kubernetes Resources

Each service includes:

### Core Resources
- **Deployment** - Application workload
- **Service** - Internal service discovery
- **ConfigMap** - Configuration data
- **Secret** - Sensitive data (encrypted)
- **ServiceAccount** - IRSA for AWS access

### Scaling & Reliability
- **HorizontalPodAutoscaler (HPA)** - Auto-scaling based on CPU/memory
- **PodDisruptionBudget (PDB)** - Maintain availability during disruptions
- **ResourceQuotas** - Limit resource consumption
- **LimitRange** - Default resource limits

### Security
- **NetworkPolicy** - Network isolation
- **PodSecurityPolicy** - Pod security standards
- **RBAC** - Role-based access control

### Monitoring
- **ServiceMonitor** - Prometheus metrics collection
- **PodMonitor** - Pod-level metrics

## 🚀 Deployment

### Prerequisites

1. **EKS Cluster Ready**:
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name devsecops-dev-eks
   kubectl get nodes
   ```

2. **AWS Load Balancer Controller Installed**:
   ```bash
   helm repo add eks https://aws.github.io/eks-charts
   helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
     -n kube-system \
     --set clusterName=devsecops-dev-eks
   ```

3. **Secrets Created**:
   ```bash
   # Create secrets from AWS Secrets Manager
   kubectl create secret generic rds-credentials \
     --from-literal=password=$(aws secretsmanager get-secret-value \
       --secret-id devsecops-dev-rds-password \
       --query SecretString --output text)
   
   kubectl create secret generic redis-credentials \
     --from-literal=auth-token=$(aws secretsmanager get-secret-value \
       --secret-id devsecops-dev-redis-auth-token \
       --query SecretString --output text)
   ```

### Deploy to Development

```bash
cd 04-kubernetes

# Review what will be applied
kubectl kustomize overlays/dev

# Apply the configuration
kubectl apply -k overlays/dev

# Watch deployment progress
kubectl get pods -n devsecops-dev -w
```

### Deploy to Staging

```bash
# Apply staging configuration
kubectl apply -k overlays/staging

# Verify deployment
kubectl get all -n devsecops-staging
```

### Deploy to Production

```bash
# Apply production configuration with caution
kubectl apply -k overlays/prod

# Monitor rollout
kubectl rollout status deployment/user-service -n devsecops-prod
kubectl rollout status deployment/auth-service -n devsecops-prod
kubectl rollout status deployment/notification-service -n devsecops-prod
kubectl rollout status deployment/analytics-service -n devsecops-prod
kubectl rollout status deployment/frontend -n devsecops-prod
```

## 🔄 Updates & Rollbacks

### Update Service

```bash
# Update image tag
cd overlays/dev
kustomize edit set image user-service=<ecr-repo>/user-service:v1.2.0

# Apply update
kubectl apply -k overlays/dev

# Monitor rollout
kubectl rollout status deployment/user-service -n devsecops-dev
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/user-service -n devsecops-dev

# Rollback to specific revision
kubectl rollout undo deployment/user-service -n devsecops-dev --to-revision=2

# Check rollout history
kubectl rollout history deployment/user-service -n devsecops-dev
```

## 🔍 Verification

### Check Service Health

```bash
# Get all resources
kubectl get all -n devsecops-dev

# Check pod logs
kubectl logs -f deployment/user-service -n devsecops-dev

# Check service endpoints
kubectl get endpoints -n devsecops-dev

# Test service connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n devsecops-dev -- \
  curl http://user-service:8080/health
```

### Check Ingress

```bash
# Get ingress address
kubectl get ingress -n devsecops-dev

# Test endpoints
INGRESS_URL=$(kubectl get ingress main-ingress -n devsecops-dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$INGRESS_URL/api/users/health
curl http://$INGRESS_URL/api/auth/health
curl http://$INGRESS_URL/api/notifications/health
curl http://$INGRESS_URL/api/analytics/health
curl http://$INGRESS_URL/
```

### Check Metrics

```bash
# Get HPA status
kubectl get hpa -n devsecops-dev

# Get resource usage
kubectl top pods -n devsecops-dev
kubectl top nodes

# Check PDB status
kubectl get pdb -n devsecops-dev
```

## 🛠️ Troubleshooting

### Pod Not Starting

```bash
# Describe pod to see events
kubectl describe pod <pod-name> -n devsecops-dev

# Check logs
kubectl logs <pod-name> -n devsecops-dev --previous

# Check events
kubectl get events -n devsecops-dev --sort-by='.lastTimestamp'
```

### Service Not Accessible

```bash
# Check service
kubectl get svc user-service -n devsecops-dev

# Check endpoints
kubectl get endpoints user-service -n devsecops-dev

# Test from another pod
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n devsecops-dev -- \
  curl -v http://user-service:8080/health
```

### Database Connection Issues

```bash
# Check secrets
kubectl get secret rds-credentials -n devsecops-dev -o yaml

# Check ConfigMap
kubectl get configmap user-service-config -n devsecops-dev -o yaml

# Test connection from pod
kubectl exec -it <pod-name> -n devsecops-dev -- sh
# Inside pod:
nc -zv <rds-endpoint> 5432
```

### High Resource Usage

```bash
# Check resource usage
kubectl top pods -n devsecops-dev

# Check resource limits
kubectl describe pod <pod-name> -n devsecops-dev | grep -A5 Limits

# Adjust HPA
kubectl patch hpa user-service -n devsecops-dev -p '{"spec":{"maxReplicas":10}}'
```

## 📊 Monitoring

### Prometheus Metrics

All services expose metrics at `/metrics`:
- User Service: http://user-service:8080/metrics
- Auth Service: http://auth-service:3000/metrics
- Notification Service: http://notification-service:5000/metrics
- Analytics Service: http://analytics-service:8081/actuator/prometheus

### Grafana Dashboards

Access Grafana (after installing monitoring stack):
```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
```

Open http://localhost:3000 and import dashboards:
- Kubernetes Cluster Overview
- Pod Resource Usage
- Application Metrics

## 🔐 Security Best Practices

1. **Use IRSA** - IAM roles for service accounts
2. **Network Policies** - Restrict pod-to-pod communication
3. **Security Contexts** - Run as non-root user
4. **Pod Security Standards** - Enforce restricted policies
5. **Secret Encryption** - Use AWS Secrets Manager
6. **Image Scanning** - Scan containers for vulnerabilities
7. **RBAC** - Least privilege access

## 🎯 Environment Differences

### Development
- 1 replica per service
- Lower resource limits
- Faster scaling response
- Public ingress for testing
- Debug logging enabled

### Staging
- 2 replicas per service
- Production-like resources
- Moderate scaling
- Internal ingress
- Info logging

### Production
- 3+ replicas per service
- High resource limits
- Aggressive auto-scaling
- Private ingress with TLS
- Warn/Error logging only
- PodDisruptionBudget enforced

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize Documentation](https://kustomize.io/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## 🆘 Support

For issues:
1. Check pod logs: `kubectl logs -f <pod-name> -n devsecops-dev`
2. Check events: `kubectl get events -n devsecops-dev --sort-by='.lastTimestamp'`
3. Describe resources: `kubectl describe <resource> <name> -n devsecops-dev`
4. Review service health endpoints
5. Check CloudWatch logs for AWS resources
