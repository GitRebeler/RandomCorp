# RandomCorp Terraform Infrastructure Deployment Script
# This script manages LKE cluster infrastructure using Terraform

param(
    [switch]$Force,
    [switch]$Destroy,
    [switch]$Plan,
    [string]$VarsFile = "terraform.tfvars",
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Help {
    Write-Host "RandomCorp Terraform Infrastructure Script" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "This script manages the LKE cluster infrastructure using Terraform."
    Write-Host ""
    Write-Host "Usage: .\deploy-infrastructure.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Force      Force destroy and recreate infrastructure"
    Write-Host "  -Destroy    Destroy the infrastructure"
    Write-Host "  -Plan       Show execution plan without applying"
    Write-Host "  -VarsFile   Specify terraform.tfvars file (default: terraform.tfvars)"
    Write-Host "  -Help       Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\deploy-infrastructure.ps1                    # Deploy infrastructure"
    Write-Host "  .\deploy-infrastructure.ps1 -Plan             # Show plan only"
    Write-Host "  .\deploy-infrastructure.ps1 -Force            # Force recreate"
    Write-Host "  .\deploy-infrastructure.ps1 -Destroy          # Destroy infrastructure"
    Write-Host ""
}

if ($Help) {
    Show-Help
    exit 0
}

# Check if Terraform is installed
try {
    terraform version | Out-Null
} catch {
    Write-Host "❌ Terraform not found. Please install Terraform first." -ForegroundColor Red
    Write-Host "   Download from: https://www.terraform.io/downloads.html" -ForegroundColor Yellow
    exit 1
}

# Check if terraform.tfvars exists
if (-not (Test-Path $VarsFile)) {
    Write-Host "❌ Variables file '$VarsFile' not found." -ForegroundColor Red
    Write-Host "   Please copy terraform.tfvars.example to terraform.tfvars and configure it." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "🏗️ RandomCorp Terraform Infrastructure Management" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""

# Initialize Terraform
Write-Host "📦 Initializing Terraform..." -ForegroundColor Cyan
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform initialization failed" -ForegroundColor Red
    exit 1
}

# Handle different operations
if ($Plan) {
    Write-Host "📋 Creating execution plan..." -ForegroundColor Cyan
    terraform plan -var-file="$VarsFile"
    exit $LASTEXITCODE
}

if ($Destroy) {
    Write-Host "🗑️ Destroying infrastructure..." -ForegroundColor Red
    Write-Host "⚠️ This will permanently delete your LKE cluster!" -ForegroundColor Yellow
    $confirm = Read-Host "Type 'yes' to confirm destruction"
    if ($confirm -eq "yes") {
        terraform destroy -var-file="$VarsFile" -auto-approve
    } else {
        Write-Host "❌ Destruction cancelled" -ForegroundColor Yellow
        exit 1
    }
    exit $LASTEXITCODE
}

if ($Force) {
    Write-Host "🔄 Force recreating infrastructure..." -ForegroundColor Yellow
    Write-Host "⚠️ This will destroy and recreate your LKE cluster!" -ForegroundColor Yellow
    $confirm = Read-Host "Type 'yes' to confirm force recreation"
    if ($confirm -eq "yes") {
        Write-Host "🗑️ Destroying existing infrastructure..." -ForegroundColor Red
        terraform destroy -var-file="$VarsFile" -auto-approve
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Infrastructure destruction failed" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "❌ Force recreation cancelled" -ForegroundColor Yellow
        exit 1
    }
}

# Apply Terraform configuration
Write-Host "🚀 Applying Terraform configuration..." -ForegroundColor Cyan
terraform apply -var-file="$VarsFile" -auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform apply failed" -ForegroundColor Red
    exit 1
}

# Show outputs
Write-Host ""
Write-Host "✅ Infrastructure deployment complete!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Cluster Information:" -ForegroundColor Cyan
terraform output -json | ConvertFrom-Json | ForEach-Object {
    $_.PSObject.Properties | ForEach-Object {
        if ($_.Name -notmatch "sensitive|kubeconfig") {
            Write-Host "  $($_.Name): $($_.Value.value)" -ForegroundColor White
        }
    }
}

Write-Host ""
Write-Host "🔧 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Your kubeconfig has been saved to: ~/.kube/randomcorp-lke-kubeconfig.yaml" -ForegroundColor White
Write-Host "  2. Continue with the ingress setup and application deployment" -ForegroundColor White
Write-Host ""

$kubeconfigPath = (terraform output -raw kubeconfig_path)
Write-Host "💡 To use kubectl with this cluster:" -ForegroundColor Yellow
Write-Host "   `$env:KUBECONFIG = '$kubeconfigPath'" -ForegroundColor Cyan
Write-Host "   kubectl cluster-info" -ForegroundColor Cyan
Write-Host ""
