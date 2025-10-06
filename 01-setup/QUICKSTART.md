# Quick Start Guide

This guide will help you quickly set up your DevSecOps development environment.

## Prerequisites

- **Operating System**: Ubuntu 20.04 or later (other Linux distributions may work with modifications)
- **User Privileges**: Sudo access required
- **Hardware**: 
  - Minimum 8GB RAM
  - Minimum 50GB free disk space
  - Minimum 4 CPU cores
- **Network**: Active internet connection

## Installation Steps

### Step 1: Run Installation Script

The installation script will install all required tools automatically:

```bash
cd 01-setup
./install-tools.sh
```

**What it installs:**
- Docker & Docker Compose
- Kubernetes tools (kubectl, Helm, k9s)
- AWS CLI & eksctl
- Terraform
- Ansible
- Security tools (Trivy, Syft, Cosign, Grype)
- ArgoCD CLI
- GitHub CLI

**Duration**: 10-15 minutes depending on your internet speed

### Step 2: Log Out and Log Back In

This is required for Docker group permissions to take effect:

```bash
# Log out completely and log back in
# Or run in current session:
newgrp docker
```

### Step 3: Verify Installation

Run the verification script to ensure all tools are properly installed:

```bash
./verify-installation.sh
```

This will check:
- All tool installations
- Version compatibility
- System requirements
- Configuration status

### Step 4: Configure AWS

Set up your AWS credentials:

```bash
aws configure
```

You'll need:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., `us-east-1`)
- Default output format (suggest `json`)

### Step 5: Authenticate GitHub CLI

Set up GitHub authentication:

```bash
gh auth login
```

Follow the prompts to authenticate with GitHub.

## Verification Checklist

After installation, verify these items:

- [ ] Docker runs without sudo: `docker ps`
- [ ] kubectl is accessible: `kubectl version --client`
- [ ] AWS CLI configured: `aws sts get-caller-identity`
- [ ] GitHub CLI authenticated: `gh auth status`
- [ ] All security tools working: `trivy --version`

## Troubleshooting

### Docker Permission Denied

**Problem**: `permission denied while trying to connect to the Docker daemon socket`

**Solution**:
```bash
sudo usermod -aG docker $USER
newgrp docker
# Or log out and log back in
```

### AWS CLI Not Found

**Problem**: `aws: command not found`

**Solution**:
```bash
# Check PATH
echo $PATH | grep /usr/local/bin

# If missing, add to ~/.bashrc
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

### Terraform Version Issues

**Problem**: Terraform version too old

**Solution**:
```bash
# Remove old version
sudo apt-get remove terraform

# Reinstall
./install-tools.sh
```

### Network/Proxy Issues

If you're behind a corporate proxy:

```bash
# Set proxy environment variables
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
export NO_PROXY=localhost,127.0.0.1

# Add to Docker daemon
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://proxy.company.com:8080"
Environment="HTTPS_PROXY=http://proxy.company.com:8080"
Environment="NO_PROXY=localhost,127.0.0.1"
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
```

## Tool Versions

Current tested versions (as of script creation):

| Tool | Minimum Version | Tested Version |
|------|----------------|----------------|
| Docker | 20.10+ | 24.0+ |
| kubectl | 1.25+ | 1.28+ |
| Helm | 3.10+ | 3.13+ |
| AWS CLI | 2.0+ | 2.13+ |
| Terraform | 1.0+ | 1.6+ |
| Ansible | 2.12+ | 2.15+ |
| Trivy | 0.40+ | 0.47+ |

## Next Steps

Once setup is complete:

1. **Build Microservices**: `cd ../02-services`
2. **Review Architecture**: Check `../README.md`
3. **Set Up Infrastructure**: Later in `../03-infrastructure`

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS Documentation](https://docs.aws.amazon.com/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [DevSecOps Best Practices](../08-docs/)

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review the detailed README.md in this folder
3. Run verification script for detailed diagnostics
4. Check tool-specific documentation

---

**Setup Complete?** Move to services: `cd ../02-services/README.md`
