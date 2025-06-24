# LKE (Linode Kubernetes Engine) Deployment Guide

This guide walks you through deploying RandomCorp to Linode Kubernetes Engine.

## Prerequisites

1. **LKE Cluster**: You should have an LKE cluster running
2. **kubectl**: Installed and configured on your local machine
3. **Helm**: Installed on your local machine
4. **Docker**: For building and pushing images
5. **Docker Hub Account**: For pushing images (or configure for your registry)

## Step-by-Step Deployment

### 1. Setup kubectl for LKE

```powershell
# Setup kubectl to connect to your LKE cluster
.\setup-kubectl.ps1
```

This script will:
- Find your kubeconfig file (`kubeconfig-randomcorp-lke.yaml` or `kubeconfig-randomcorp-lke-decoded.yaml`)
- Set the KUBECONFIG environment variable
- Test the connection to your cluster

### 2. Build and Push Docker Images

```powershell
# Build images with production configuration
.\build-lke-images.ps1
```

This script will:
- Prompt for the API URL (or use default placeholder)
- Build the API Docker image
- Build the Frontend Docker image with the correct API URL baked in
- Push both images to Docker Hub

**Important**: You may need to run this script twice:
1. First time: Use placeholder API URL to get initial deployment
2. Second time: Use actual LoadBalancer IP once services are created

### 3. Deploy to LKE

```powershell
# Deploy the application to LKE
.\deploy-lke.ps1
```

This script will:
- Update Helm dependencies
- Deploy the application using Helm
- Show service information
- Display LoadBalancer IPs (when available)

### 4. Get LoadBalancer IPs

```powershell
# Check LoadBalancer IPs and service status
.\get-lke-ips.ps1
```

This script will:
- Show all LoadBalancer IPs
- Test API health
- Provide guidance if frontend needs rebuilding with correct API URL

## Configuration Details

### API URL Handling

The frontend needs to know the API URL at build time. We handle this with a two-phase approach:

1. **Initial Deployment**: Use placeholder URL `http://api.randomcorp.lke`
2. **Update with Real IP**: Once LoadBalancer gets an IP, rebuild frontend with actual URL

### Kubernetes Services

- **Frontend Service**: LoadBalancer type, exposes port 80
- **API Service**: LoadBalancer type, exposes port 80 (maps to container port 8000)
- **Database Service**: ClusterIP type, internal access only

### Environment Variables

The API container receives these environment variables:
- `DB_HOST`: Points to SQL Server service
- `DB_PORT`: 1433
- `DB_NAME`: RandomCorpDB
- `DB_USER`: sa
- `DB_PASSWORD`: RandomCorp123!
- `DEBUG`: false

## Troubleshooting

### Images Not Found
```powershell
# Make sure you're logged into Docker Hub
docker login

# Check if images exist
docker images | findstr randomcorp
```

### LoadBalancer IPs Not Assigned
LoadBalancer IPs can take 2-5 minutes to be assigned. Keep checking:
```powershell
.\get-lke-ips.ps1
```

### Frontend Can't Reach API
This usually means the frontend was built with the wrong API URL:
```powershell
# Get the actual API IP
.\get-lke-ips.ps1

# Rebuild with correct API URL
.\build-lke-images.ps1
# Enter the actual API URL when prompted

# Redeploy
.\deploy-lke.ps1
```

### Pod Issues
```powershell
# Check pod status
kubectl get pods

# Check logs
kubectl logs -f deployment/randomcorp
kubectl logs -f deployment/randomcorp-frontend

# Describe problematic pods
kubectl describe pod <pod-name>
```

### Database Connection Issues
```powershell
# Check SQL Server pod
kubectl get pods | findstr mssql

# Check SQL Server logs
kubectl logs -f deployment/randomcorp-mssqlserver-2022
```

## Manual Commands

### Update Deployment
```powershell
# Update only the API
helm upgrade randomcorp ./helm-charts/randomcorp --set image.tag=new-tag

# Update only the frontend
helm upgrade randomcorp ./helm-charts/randomcorp --set frontend.image.tag=new-tag
```

### Scale Application
```powershell
# Scale to 3 replicas
kubectl scale deployment randomcorp --replicas=3
kubectl scale deployment randomcorp-frontend --replicas=3
```

### Access Services
```powershell
# Get all services
kubectl get services

# Get specific service details
kubectl describe service randomcorp
kubectl describe service randomcorp-frontend
```

## URLs After Deployment

Once deployed, you'll have:
- **Frontend**: `http://<frontend-loadbalancer-ip>`
- **API**: `http://<api-loadbalancer-ip>`
- **API Health**: `http://<api-loadbalancer-ip>/health`
- **API Docs**: `http://<api-loadbalancer-ip>/docs`

## Cost Optimization

To minimize costs:
1. Scale down replicas when not in use: `kubectl scale deployment randomcorp --replicas=1`
2. Use smaller node types in LKE
3. Consider using ClusterIP services with Ingress instead of LoadBalancers
4. Clean up when not needed: `helm uninstall randomcorp`
