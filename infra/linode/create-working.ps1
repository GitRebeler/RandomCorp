# Working PowerShell script for Linode LKE cluster creation

Write-Host "Creating Linode LKE cluster..." -ForegroundColor Green
Write-Host "Node Type: g6-standard-1 (2GB Linode)"
Write-Host "Node Count: 3"
Write-Host "K8s Version: 1.31"
Write-Host "Monthly Cost: ~$42 (3 x $10 nodes + $12 load balancer/storage)"
Write-Host ""

# Create the cluster
Write-Host "Executing cluster creation command..." -ForegroundColor Yellow
linode-cli lke cluster-create --label "randomcorp-lke" --region "us-east" --k8s_version "1.31" --node_pools.type "g6-standard-1" --node_pools.count 3

Write-Host ""
Write-Host "Cluster creation initiated!" -ForegroundColor Green
Write-Host "Check status with: linode-cli lke clusters-list" -ForegroundColor Cyan
Write-Host "Download kubeconfig when ready with: linode-cli lke kubeconfig-view <CLUSTER_ID>" -ForegroundColor Cyan
