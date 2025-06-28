# Setup NGINX Ingress Controller for RandomCorp LKE Deployment
# This script installs NGINX Ingress Controller and configures it for RandomCorp

param(
    [string]$Domain = "randomcorp.local",
    [switch]$UseHTTPS,
    [string]$Email = ""
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Setting up NGINX Ingress Controller for RandomCorp..." -ForegroundColor Green

# Check if kubectl is available
try {
    kubectl version --client | Out-Null
} catch {
    Write-Host "❌ kubectl not found. Please ensure kubectl is installed and configured." -ForegroundColor Red
    exit 1
}

# Add NGINX Ingress Helm repository
Write-Host "📦 Adding NGINX Ingress Helm repository..." -ForegroundColor Cyan
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>$null
helm repo update

# Install NGINX Ingress Controller
Write-Host "🔧 Installing NGINX Ingress Controller..." -ForegroundColor Cyan
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx `
  --namespace ingress-nginx `
  --create-namespace `
  --set controller.service.type=LoadBalancer `
  --set controller.service.externalTrafficPolicy=Local `
  --set controller.admissionWebhooks.enabled=false `
  --wait

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install NGINX Ingress Controller" -ForegroundColor Red
    exit 1
}

# Wait for LoadBalancer IP assignment
Write-Host "⏳ Waiting for LoadBalancer IP assignment..." -ForegroundColor Yellow
$attempts = 0
$maxAttempts = 30
do {
    $ingressIP = kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    if (-not $ingressIP -or $ingressIP -eq "") {
        Write-Host "  Attempt $($attempts + 1)/$maxAttempts - Waiting for LoadBalancer IP..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        $attempts++
    }
} while ((-not $ingressIP -or $ingressIP -eq "") -and $attempts -lt $maxAttempts)

if (-not $ingressIP -or $ingressIP -eq "") {
    Write-Host "❌ Failed to get LoadBalancer IP after $maxAttempts attempts" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Ingress Controller ready at IP: $ingressIP" -ForegroundColor Green

# Install cert-manager if HTTPS is requested
if ($UseHTTPS) {
    if ([string]::IsNullOrEmpty($Email)) {
        Write-Host "❌ Email is required for HTTPS/cert-manager setup" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "🔒 Installing cert-manager for HTTPS..." -ForegroundColor Cyan
    helm repo add jetstack https://charts.jetstack.io 2>$null
    helm repo update
    
    helm upgrade --install cert-manager jetstack/cert-manager `
      --namespace cert-manager `
      --create-namespace `
      --set installCRDs=true `
      --wait
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ cert-manager installed successfully" -ForegroundColor Green
        
        # Create ClusterIssuer for Let's Encrypt
        $clusterIssuerManifest = @"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $Email
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
"@
        
        $clusterIssuerManifest | kubectl apply -f -
        Write-Host "✅ Let's Encrypt ClusterIssuer created" -ForegroundColor Green
    } else {
        Write-Host "⚠️ cert-manager installation failed, continuing without HTTPS" -ForegroundColor Yellow
    }
}

# Output configuration information
Write-Host ""
Write-Host "🎉 NGINX Ingress Controller Setup Complete!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Configuration Details:" -ForegroundColor Cyan
Write-Host "  LoadBalancer IP: $ingressIP" -ForegroundColor White
Write-Host "  Domain: $Domain" -ForegroundColor White
if ($UseHTTPS) {
    Write-Host "  Protocol: HTTPS (with Let's Encrypt)" -ForegroundColor White
} else {
    Write-Host "  Protocol: HTTP" -ForegroundColor White
}
Write-Host ""

# DNS configuration guidance
if ($Domain -like "*.local") {
    Write-Host "📝 For local testing, add this to your hosts file:" -ForegroundColor Yellow
    Write-Host "   $ingressIP $Domain" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Windows: C:\Windows\System32\drivers\etc\hosts" -ForegroundColor Gray
    Write-Host "   Linux/Mac: /etc/hosts" -ForegroundColor Gray
} else {
    Write-Host "🌐 DNS Configuration Required:" -ForegroundColor Yellow
    Write-Host "   Create an A record for '$Domain' pointing to: $ingressIP" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Update your RandomCorp values.yaml to enable ingress" -ForegroundColor White
Write-Host "   2. Set ingress.hosts[0].host to '$Domain'" -ForegroundColor White
Write-Host "   3. Deploy RandomCorp with: helm upgrade --install randomcorp ./helm-charts/randomcorp" -ForegroundColor White
Write-Host ""

if ($UseHTTPS) {
    $protocol = "https"
} else {
    $protocol = "http"
}

Write-Host "🌟 After deployment, your app will be available at:" -ForegroundColor Green
Write-Host "   Frontend: $protocol`://$Domain/" -ForegroundColor Cyan
Write-Host "   API: $protocol`://$Domain/api/" -ForegroundColor Cyan
Write-Host "   API Docs: $protocol`://$Domain/api/docs" -ForegroundColor Cyan
Write-Host ""
