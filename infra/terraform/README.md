# RandomCorp Terraform Infrastructure

This directory contains Terraform configuration for managing the RandomCorp LKE (Linode Kubernetes Engine) cluster infrastructure.

## 🎯 GitHub Actions Integration

**NEW**: The deployment workflow now uses Terraform for infrastructure management instead of direct API calls. This provides:

- ✅ **Infrastructure as Code**: All infrastructure is version controlled
- ✅ **Idempotent deployments**: Safe to run multiple times
- ✅ **State management**: Terraform tracks current infrastructure state
- ✅ **Better error handling**: More robust deployment process
- ✅ **Plan before apply**: See what changes will be made

The GitHub Actions workflow (`.github/workflows/deploy.yml`) automatically:
1. Configures Terraform with your secrets
2. Plans infrastructure changes
3. Applies changes only when needed
4. Generates kubeconfig for kubectl access
5. Deploys applications to the cluster

## 🚀 Quick Start

1. **Install Terraform**
   ```powershell
   # Using Chocolatey (Windows)
   choco install terraform
   
   # Or download from: https://www.terraform.io/downloads.html
   ```

2. **Configure Variables**
   ```powershell
   # Copy the example variables file
   Copy-Item terraform.tfvars.example terraform.tfvars
   
   # Edit terraform.tfvars and add your Linode API token
   # Get your token from: https://cloud.linode.com/profile/tokens
   ```

3. **Deploy Infrastructure**
   ```powershell
   # Deploy the cluster
   .\deploy-infrastructure.ps1
   
   # Or use the main deployment script
   cd ..\..
   .\build-cluster-deploy-app-ingress.ps1
   ```

## 📁 Files

- **`main.tf`** - Main Terraform configuration for LKE cluster
- **`variables.tf`** - Variable definitions
- **`outputs.tf`** - Output definitions  
- **`terraform.tfvars.example`** - Example variables file
- **`deploy-infrastructure.ps1`** - PowerShell wrapper script
- **`.gitignore`** - Git ignore file for Terraform

## 🔧 Configuration

### Default Configuration
- **Cluster Name**: `randomcorp-lke`
- **Region**: `us-east`
- **Kubernetes Version**: `1.29`
- **Node Type**: `g6-standard-2` (2 vCPUs, 4GB RAM)
- **Node Count**: 3 nodes
- **Autoscaling**: 3-5 nodes

### Customization
Edit `terraform.tfvars` to customize:
- Cluster name and region
- Node types and counts
- Autoscaling settings
- Tags and labels

## 🛠️ Usage

### Deploy Infrastructure
```powershell
# Basic deployment
.\deploy-infrastructure.ps1

# Show plan without applying
.\deploy-infrastructure.ps1 -Plan

# Force recreate (destroys existing cluster!)
.\deploy-infrastructure.ps1 -Force
```

### Destroy Infrastructure
```powershell
# Destroy the cluster
.\deploy-infrastructure.ps1 -Destroy
```

### Manual Terraform Commands
```powershell
# Initialize
terraform init

# Plan
terraform plan -var-file=terraform.tfvars

# Apply
terraform apply -var-file=terraform.tfvars

# Destroy
terraform destroy -var-file=terraform.tfvars
```

## 📋 Outputs

After deployment, Terraform provides:
- Cluster ID and status
- API endpoints
- Kubeconfig file location
- Node pool information

## 🔐 Security

- **Never commit `terraform.tfvars`** - Contains sensitive API tokens
- **Kubeconfig files are excluded** - Contains cluster access credentials
- **State files are local** - Consider remote state for production

## 🔄 Integration

This Terraform configuration integrates with:
- **Main deployment script**: `build-cluster-deploy-app-ingress.ps1`
- **Existing ingress setup**: `setup-ingress.ps1`  
- **Application deployment**: `deploy-app.ps1`
- **GitOps workflow**: Flux CD

## 🏗️ Architecture

```
RandomCorp Infrastructure
├── LKE Cluster (Terraform)
│   ├── 3x g6-standard-2 nodes
│   ├── Autoscaling (3-5 nodes)
│   └── Kubernetes 1.29
├── NGINX Ingress Controller
├── RandomCorp Application
│   ├── Frontend (React)
│   ├── API (FastAPI)
│   └── Database (SQL Server)
└── Flux CD (GitOps)
```

## 🔧 Troubleshooting

### Common Issues

1. **Terraform not found**
   - Install Terraform and ensure it's in PATH

2. **API token issues**
   - Verify token in `terraform.tfvars`
   - Check token permissions at Linode Cloud Manager

3. **Kubeconfig not found**
   - Terraform automatically generates kubeconfig
   - Check `~/.kube/randomcorp-lke-kubeconfig.yaml`

4. **State lock issues**
   - Remove `.terraform.lock.hcl` and run `terraform init`

### Support

- Check Terraform documentation: https://registry.terraform.io/providers/linode/linode/latest
- Linode LKE documentation: https://www.linode.com/products/kubernetes/
- RandomCorp main README: `../../README.md`
