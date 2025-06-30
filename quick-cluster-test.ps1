#!/usr/bin/env pwsh
# Quick Cluster Test - Simple script to list clusters and test kubectl

param(
    [string]$ClusterName = "randomcorp-lke"
)

Write-Host "🔍 Listing LKE clusters..." -ForegroundColor Cyan
linode-cli lke clusters-list

Write-Host "`n📥 Getting kubeconfig for cluster: $ClusterName..." -ForegroundColor Cyan

# Get cluster ID
$clusters = linode-cli lke clusters-list --json | ConvertFrom-Json
$cluster = $clusters | Where-Object { $_.label -eq $ClusterName }

if (-not $cluster) {
    Write-Host "❌ Cluster '$ClusterName' not found!" -ForegroundColor Red
    exit 1
}

$clusterId = $cluster.id
Write-Host "✅ Found cluster ID: $clusterId" -ForegroundColor Green

# Get kubeconfig (it comes base64 encoded)
Write-Host "📦 Getting kubeconfig..." -ForegroundColor Cyan
$kubeconfigData = linode-cli lke kubeconfig-view $clusterId --json | ConvertFrom-Json
$kubeconfigContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($kubeconfigData.kubeconfig))

# Save to existing decoded kubeconfig file
$kubeconfigPath = ".\kubeconfig-randomcorp-lke-decoded.yaml"
$kubeconfigContent | Out-File -FilePath $kubeconfigPath -Encoding UTF8

# Set KUBECONFIG and test kubectl
$env:KUBECONFIG = $kubeconfigPath
Write-Host "🔧 KUBECONFIG set to: $kubeconfigPath" -ForegroundColor Green

Write-Host "`n🏃 Running kubectl get pods..." -ForegroundColor Cyan
kubectl get pods -A

Write-Host "`n✅ Done!" -ForegroundColor Green
