# Linode LKE Deployment for Random Corp

This directory contains scripts and configurations for deploying Random Corp to Linode Kubernetes Engine (LKE) using GitOps with Flux.

## Cost Comparison

| Platform | Configuration | Monthly Cost |
|----------|---------------|--------------|
| **Linode LKE** | 3x Nanode 1GB + Storage + LB | **$27/month** |
| **Linode LKE** | 3x Linode 2GB + Storage + LB | **$42/month** |
| Azure AKS | 2x Standard_B2s + Storage + LB | $90-94/month |
| Azure Container Apps | Consumption + Azure SQL | $20-30/month |

**Linode LKE offers the best balance of features and cost for Kubernetes!**

## Prerequisites

1. **Linode CLI**: Install and configure
   ```bash
   pip install linode-cli
   linode-cli configure
   ```

2. **kubectl**: Kubernetes command-line tool
   ```bash
   # Linux
   curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl && sudo mv kubectl /usr/local/bin/
   
   # macOS
   brew install kubectl
   
   # Windows
   choco install kubernetes-cli
   ```

3. **Flux CLI**: GitOps toolkit
   ```bash
   # Linux/macOS
   curl -s https://fluxcd.io/install.sh | sudo bash
   
   # macOS
   brew install fluxcd/tap/flux
   
   # Windows
   choco install flux
   ```

4. **GitHub Personal Access Token**: 
   - Create token with `repo` permissions
   - Save in `github-token.txt` file

## Deployment Process

### 1. Create LKE Cluster
```bash
chmod +x create-lke-cluster.sh
./create-lke-cluster.sh
```

This creates:
- 3-node LKE cluster with shared CPU instances
- Kubeconfig file: `kubeconfig-randomcorp.yaml`
- Total setup time: ~10 minutes

### 2. Configure kubectl
```bash
export KUBECONFIG=$(pwd)/kubeconfig-randomcorp.yaml
kubectl get nodes
```

### 3. Install Flux (GitOps)
```bash
# Update GITHUB_USER in the script first!
chmod +x install-flux.sh
./install-flux.sh
```

This sets up:
- Flux v2 controllers in the cluster
- GitOps monitoring of your repository
- Automatic deployment on git commits

### 4. Create Application Structure
```bash
chmod +x deploy-app.sh
./deploy-app.sh
```

This creates:
- Helm chart for Random Corp application
- Flux HelmRelease and GitRepository manifests
- Kubernetes deployments for API, Frontend, and SQL Server

### 5. Build and Push Images
```bash
# Update REGISTRY variable in the script first!
chmod +x build-and-push.sh
./build-and-push.sh
```

### 6. Update Configuration
Edit `helm-charts/randomcorp/values.yaml`:
```yaml
image:
  repository: your-registry/randomcorp  # Update this
frontend:
  image:
    repository: your-registry/randomcorp-frontend  # Update this
```

Edit `clusters/linode-lke/apps/randomcorp-source.yaml`:
```yaml
spec:
  url: https://github.com/your-username/RandomCorp  # Update this
```

### 7. Deploy via GitOps
```bash
git add .
git commit -m "Add Linode LKE deployment configuration"
git push origin master
```

Flux will automatically detect changes and deploy!

## Monitoring Deployment

```bash
# Watch Flux sync
flux get sources git
flux get helmreleases

# Watch pods
kubectl get pods -w

# Get service external IPs (LoadBalancers)
kubectl get services

# Check logs
kubectl logs -l app.kubernetes.io/component=api
```

## Architecture

```
GitHub Repository (master branch)
    ↓ (Flux monitors)
Linode LKE Cluster
    ├── flux-system namespace
    │   ├── source-controller (watches git)
    │   ├── helm-controller (manages helm releases)
    │   └── kustomize-controller
    └── default namespace
        ├── randomcorp-api (FastAPI)
        ├── randomcorp-frontend (React)
        ├── mssql-linux (SQL Server)
        └── NodeBalancer (Load Balancer)
```

## GitOps Benefits

1. **Declarative**: Infrastructure as Code
2. **Automated**: Push to git = automatic deployment  
3. **Auditable**: Git history shows all changes
4. **Rollback**: Easy to revert via git
5. **Secure**: Cluster pulls changes (no external access needed)

## Cost Breakdown (Recommended Setup)

- **LKE Control Plane**: $0
- **3x Linode 2GB nodes**: $30/month  
- **20GB Block Storage**: $2/month
- **NodeBalancer**: $10/month
- **Total**: $42/month

## Scaling

- **Horizontal Pod Autoscaler**: Automatically scales pods based on CPU
- **Cluster Autoscaler**: Add/remove nodes based on demand
- **Vertical Pod Autoscaler**: Adjust resource requests/limits

## Security Features

- **Network Policies**: Control pod-to-pod communication
- **RBAC**: Role-based access control
- **Pod Security Standards**: Enforce security policies
- **Secrets Management**: Kubernetes secrets for sensitive data

## Cleanup

```bash
# Delete cluster (saves money!)
linode-cli lke cluster-delete <CLUSTER_ID>

# Remove local files
rm kubeconfig-randomcorp.yaml
```

## Troubleshooting

### Flux not syncing
```bash
flux get sources git
flux logs
```

### Pods not starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### LoadBalancer pending
```bash
kubectl get events
# NodeBalancer creation takes 2-3 minutes
```

## Production Considerations

1. **Backup Strategy**: Regular SQL Server backups to Linode Object Storage
2. **Monitoring**: Prometheus + Grafana for metrics
3. **Logging**: ELK stack or Loki for centralized logs  
4. **SSL/TLS**: Cert-manager for automatic SSL certificates
5. **Secrets**: External secrets operator for secure secret management
6. **Multi-region**: Deploy across multiple Linode regions for HA
