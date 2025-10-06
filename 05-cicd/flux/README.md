# Flux CD Configuration

This directory contains Flux CD configurations for GitOps continuous delivery in the DevSecOps project.

## Directory Structure

```
flux/
├── README.md                    # This file
├── sources/                     # Source definitions
│   ├── git-repository.yaml
│   ├── helm-repositories.yaml
│   └── oci-repositories.yaml
├── kustomizations/              # Kustomization definitions
│   ├── infrastructure.yaml
│   ├── apps.yaml
│   ├── monitoring.yaml
│   └── security.yaml
├── image-automation/            # Image update automation
│   ├── image-repository.yaml
│   ├── image-policy.yaml
│   └── image-update.yaml
├── notifications/               # Alert configurations
│   ├── providers.yaml
│   └── alerts.yaml
└── helm-releases/               # Helm release definitions
    ├── postgresql.yaml
    ├── redis.yaml
    └── ingress-nginx.yaml
```

## Setup Flux

Use the setup script in the 09-scripts directory:

```bash
cd 09-scripts
./09-setup-flux.sh <environment>
```

## Flux Features

Flux CD provides:

- [✓] Automated Git synchronization
- [✓] Multi-tenant support
- [✓] Image automation and updates
- [✓] Helm release management
- [✓] Health assessment
- [✓] Alerting and notifications
- [✓] Progressive delivery (Flagger)
- [✓] Policy enforcement

## Deploy with Flux

Use the deployment script:

```bash
cd 09-scripts
./deploy-with-flux.sh <environment>
```

## Flux Components

### Source Controller

Manages sources of truth:

- Git repositories
- Helm repositories
- OCI repositories
- S3 buckets

### Kustomize Controller

Applies Kustomize overlays and patches.

### Helm Controller

Manages Helm releases with values and dependencies.

### Notification Controller

Sends alerts to Slack, Teams, Discord, etc.

### Image Automation Controllers

- **Image Reflector**: Scans image repositories
- **Image Automation**: Updates manifests automatically

## GitRepository Source

Example Git repository source:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: devsecops-repo
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/khaledhawil/devsecops-project
  ref:
    branch: main
  secretRef:
    name: github-credentials
```

## Kustomization

Example kustomization for apps:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps-dev
  namespace: flux-system
spec:
  interval: 5m
  path: ./04-kubernetes/overlays/dev/apps
  prune: true
  sourceRef:
    kind: GitRepository
    name: devsecops-repo
  timeout: 5m
  wait: true
```

## Image Automation

### Image Repository

Scan Docker Hub for new images:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: frontend
  namespace: flux-system
spec:
  image: khaledhawil/frontend
  interval: 5m
```

### Image Policy

Define version selection policy:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImagePolicy
metadata:
  name: frontend
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: frontend
  policy:
    semver:
      range: '>=1.0.0'
```

### Image Update Automation

Automatically update manifests:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImageUpdateAutomation
metadata:
  name: dev-automation
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: devsecops-repo
  git:
    checkout:
      ref:
        branch: main
    commit:
      author:
        email: fluxcd@users.noreply.github.com
        name: FluxCD
      messageTemplate: 'Automated image update [ci skip]'
    push:
      branch: main
  update:
    path: ./04-kubernetes/overlays/dev
    strategy: Setters
```

## Notifications

### Slack Provider

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Provider
metadata:
  name: slack
  namespace: flux-system
spec:
  type: slack
  channel: flux-notifications
  secretRef:
    name: slack-webhook
```

### Alert

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Alert
metadata:
  name: flux-system
  namespace: flux-system
spec:
  providerRef:
    name: slack
  eventSeverity: info
  eventSources:
    - kind: GitRepository
      name: '*'
    - kind: Kustomization
      name: '*'
```

## Monitoring Flux

### Check Status

```bash
# Check all Flux components
flux check

# Get all sources
flux get sources all

# Get kustomizations
flux get kustomizations

# Get helm releases
flux get helmreleases --all-namespaces

# Get images
flux get images all
```

### View Logs

```bash
# All Flux logs
flux logs --all-namespaces --follow

# Specific controller
flux logs -n flux-system --kind=Kustomization --name=apps-dev
```

### Reconciliation

```bash
# Force reconcile
flux reconcile source git devsecops-repo
flux reconcile kustomization apps-dev

# Suspend/Resume
flux suspend kustomization apps-dev
flux resume kustomization apps-dev
```

## GitOps Workflow

1. Developer pushes code to Git
2. CI builds and pushes Docker image
3. Flux detects new image tag
4. Flux updates Kubernetes manifests in Git
5. Flux applies updated manifests to cluster
6. Health checks verify deployment
7. Notifications sent on success/failure

## Multi-Environment Setup

Directory structure for environments:

```
clusters/
├── dev/
│   ├── infrastructure/
│   ├── apps/
│   └── flux-system/
├── staging/
│   ├── infrastructure/
│   ├── apps/
│   └── flux-system/
└── prod/
    ├── infrastructure/
    ├── apps/
    └── flux-system/
```

Bootstrap each environment:

```bash
flux bootstrap github \
  --owner=khaledhawil \
  --repository=devsecops-project \
  --branch=main \
  --path=./clusters/dev \
  --personal
```

## Security

### SOPS Integration

Encrypt secrets with SOPS:

```bash
# Create key
age-keygen -o age.agekey

# Encrypt secret
sops --encrypt --age <public-key> secret.yaml > secret.enc.yaml

# Configure Flux
kubectl create secret generic sops-age \
  --from-file=age.agekey \
  -n flux-system
```

### Policy Enforcement

Use Kyverno or Gatekeeper with Flux:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: policies
spec:
  path: ./policies
  validation: client
  healthChecks:
    - apiVersion: kyverno.io/v1
      kind: ClusterPolicy
```

## Progressive Delivery with Flagger

Install Flagger:

```bash
flux install --components-extra=image-reflector-controller,image-automation-controller
```

Canary deployment:

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: frontend
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frontend
  service:
    port: 3000
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
      - name: request-success-rate
        thresholdRange:
          min: 99
      - name: request-duration
        thresholdRange:
          max: 500
```

## Helm Releases

Deploy applications with Helm:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: postgresql
  namespace: flux-system
spec:
  interval: 5m
  chart:
    spec:
      chart: postgresql
      version: '12.x'
      sourceRef:
        kind: HelmRepository
        name: bitnami
  values:
    auth:
      username: dbuser
      database: appdb
```

## Troubleshooting

### Reconciliation Fails

```bash
# Check kustomization status
flux get kustomizations

# View events
kubectl describe kustomization <name> -n flux-system

# Force reconcile
flux reconcile kustomization <name> --with-source
```

### Image Updates Not Working

```bash
# Check image repositories
flux get image repository

# Check image policies
flux get image policy

# View automation status
flux get image update
```

### Git Push Fails

Check GitHub token:

```bash
# Update token
kubectl create secret generic github-credentials \
  --from-literal=username=khaledhawil \
  --from-literal=password=<new-token> \
  -n flux-system \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Best Practices

1. Use Git as single source of truth
2. Separate infrastructure and application manifests
3. Use Kustomize overlays for environments
4. Implement proper RBAC
5. Encrypt secrets with SOPS
6. Monitor reconciliation status
7. Set up alerts for failures
8. Use semver for image policies
9. Test changes in dev first
10. Document your GitOps repository structure

## Comparison with Other Tools

| Feature | Flux | ArgoCD | Jenkins |
|---------|------|--------|---------|
| GitOps Native | ✓ | ✓ | - |
| Multi-tenancy | ✓ | ✓ | ✓ |
| Image Automation | ✓ | - | ✓ |
| UI | CLI only | Web UI | Web UI |
| Helm Support | ✓ | ✓ | ✓ |
| Progressive Delivery | Flagger | Argo Rollouts | Manual |

## Related Documentation

- [Main CI/CD README](../README.md)
- [ArgoCD Configuration](../argocd/README.md)
- [Jenkins Configuration](../jenkins/README.md)
- [GitHub Actions](../github-actions/README.md)
- [Setup Script](../../09-scripts/09-setup-flux.sh)
- [Deployment Script](../../09-scripts/deploy-with-flux.sh)

## Support

For Flux-specific issues:
- Flux Documentation: <https://fluxcd.io/docs/>
- GitHub: <https://github.com/fluxcd/flux2>
- Slack: <https://cloud-native.slack.com/#flux>

Username configured: khaledhawil
