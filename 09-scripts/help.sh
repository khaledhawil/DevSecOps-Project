#!/bin/bash
# Quick reference for all available scripts

cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                     DevSecOps Scripts - Quick Reference                      ║
╚══════════════════════════════════════════════════════════════════════════════╝

🚀 MAIN DEPLOYMENT SCRIPTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

./00-deploy-all.sh <env>           → Deploy entire project (all-in-one)
./01-start-local.sh                → Start local development environment
./02-run-tests.sh [service]        → Run all tests
./03-build-images.sh [service]     → Build Docker images
./04-scan-security.sh [options]    → Security scanning
./05-deploy-infrastructure.sh <env>→ Deploy AWS infrastructure
./06-deploy-kubernetes.sh <env>    → Deploy to Kubernetes
./07-setup-gitops.sh <env>         → Setup ArgoCD

🛠️  UTILITY SCRIPTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

./push-images.sh [username]        → Push images to Docker Hub
./stop-local.sh                    → Stop local services
./clean-all.sh                     → Clean all local resources
./health-check.sh [env]            → Check service health
./view-logs.sh [env] [service]     → View logs
./run-smoke-tests.sh [env]         → Run smoke tests
./setup-prerequisites.sh           → Install required tools
./validate-project.sh              → Validate project setup

📋 ENVIRONMENT OPTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

<env>        → dev | staging | prod | local
[service]    → user-service | auth-service | notification-service | 
               analytics-service | frontend | all

⚡ QUICK COMMANDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Local Development:
  ./01-start-local.sh && ./health-check.sh local

Build & Scan:
  ./03-build-images.sh && ./04-scan-security.sh

Full AWS Deployment:
  ./00-deploy-all.sh dev

Step-by-Step Deployment:
  ./05-deploy-infrastructure.sh dev
  ./06-deploy-kubernetes.sh dev
  ./07-setup-gitops.sh dev

📚 DOCUMENTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

README.md              → Complete documentation
QUICKSTART.md          → Quick start guide
SCRIPTS-SUMMARY.md     → Detailed script descriptions
.env.example           → Configuration template

💡 TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• Run ./validate-project.sh to verify setup
• Use --help flag on scripts for more options
• Check logs/ directory for execution logs
• All scripts use color-coded output for clarity
• Production deployments require confirmation

🔑 CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Username configured: khaledhawil (Docker Hub & GitHub)

To customize:
  cp .env.example .env
  # Edit .env with your values
  export DOCKER_USERNAME=your-username
  export GITHUB_USERNAME=your-username

╚══════════════════════════════════════════════════════════════════════════════╝
EOF
