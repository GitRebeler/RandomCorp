# GitHub Actions Setup for RandomCorp

This document explains how to set up GitHub Actions for automated deployment of RandomCorp to Linode LKE.

## Required GitHub Secrets

You need to configure the following secrets in your GitHub repository:

### 1. Docker Hub Credentials
- `DOCKER_USERNAME` - Your Docker Hub username
- `DOCKER_PASSWORD` - Your Docker Hub password or access token

### 2. Linode API Token
- `LINODE_TOKEN` - Your Linode API token with full access

### 3. GitHub Token (Automatic)
- `GH_TOKEN` - Automatically provided by GitHub Actions

## Setting Up GitHub Secrets

1. Go to your GitHub repository
2. Click on "Settings" tab
3. In the left sidebar, click "Secrets and variables" → "Actions"
4. Click "New repository secret" for each required secret

### Getting Your Linode API Token

1. Log in to [Linode Cloud Manager](https://cloud.linode.com/)
2. Click on your profile → "API Tokens"
3. Click "Create a Personal Access Token"
4. Give it a descriptive label like "RandomCorp GitHub Actions"
5. Set expiration (or no expiration for persistent deployment)
6. Grant the following permissions:
   - **Account**: Read/Write
   - **Domains**: Read/Write
   - **Events**: Read Only
   - **Images**: Read/Write
   - **IPs**: Read/Write
   - **Kubernetes**: Read/Write
   - **Linodes**: Read/Write
   - **NodeBalancers**: Read/Write
   - **Object Storage**: Read/Write
   - **StackScripts**: Read/Write
   - **Volumes**: Read/Write
7. Click "Create Token"
8. Copy the token immediately (you won't see it again)

### Getting Docker Hub Credentials

1. Log in to [Docker Hub](https://hub.docker.com/)
2. Go to Account Settings → Security
3. Click "New Access Token"
4. Give it a descriptive name like "RandomCorp GitHub Actions"
5. Select appropriate permissions (Read/Write for your repositories)
6. Click "Generate"
7. Copy the access token

## Workflow Features

The GitHub Actions workflow includes:

### 🏗️ Build Process
- Builds both API and Frontend Docker images
- Multi-platform builds (AMD64 and ARM64)
- Automatic image tagging with git SHA and branch
- Docker layer caching for faster builds

### 🚀 Infrastructure Management
- **Smart cluster detection**: Automatically detects existing LKE clusters
- **Conditional Terraform**: Only runs Terraform if cluster doesn't exist
- **Seamless integration**: Works with both new and existing clusters
- Installs NGINX Ingress Controller
- Sets up Flux CD for GitOps

### 📦 Deployment Process
- Updates Helm values with new image tags
- Commits changes back to repository
- Waits for Flux to reconcile and deploy
- Verifies deployment health

### 🔍 Verification
- Checks pod status
- Tests API health endpoints
- Provides access information
- Creates deployment summary

## Manual Trigger

You can manually trigger the deployment by:

1. Going to the "Actions" tab in your repository
2. Selecting "Deploy RandomCorp to LKE"
3. Clicking "Run workflow"
4. Optionally checking "Force rebuild all images"

## Automatic Triggers

The workflow automatically runs on:
- Push to `main` or `master` branch (excluding Helm values and documentation)
- Pull requests to `main` or `master` branch

### Loop Prevention
The workflow includes multiple safeguards to prevent infinite loops:
- **Path exclusions**: Ignores changes to `helm-charts/**/values.yaml`
- **Skip CI tags**: Automation commits include `[skip ci]` 
- **Smart detection**: Checks if previous commit was automation-generated
- **Documentation exclusions**: Ignores `.md` file changes

## Expected Runtime

- **First deployment (new cluster)**: ~15-20 minutes (includes cluster creation via Terraform)
- **Deployment to existing cluster**: ~3-5 minutes (skips Terraform entirely)
- **Subsequent deployments**: ~5-10 minutes (depends on cluster state)

## Troubleshooting

### Common Issues

1. **Linode API Token Issues**
   - Ensure token has all required permissions
   - Check token hasn't expired
   - Verify account has sufficient credits

2. **Docker Hub Issues**
   - Verify credentials are correct
   - Check repository permissions
   - Ensure rate limits aren't exceeded

3. **Kubernetes Issues**
   - Check cluster status in Linode Cloud Manager
   - Verify ingress controller is running
   - Check pod logs for errors

4. **NGINX 404 Issues (IP Access)**
   - **Root cause**: Ingress may not be properly configured for direct IP access
   - **Check ingress**: Run `kubectl get ingress -A` to verify ingress rules
   - **Check services**: Run `kubectl get services -A` to verify backend services
   - **Check pods**: Run `kubectl get pods -A` to ensure application pods are running
   - **Test with domain**: Try accessing via `http://randomcorp.local` (add to hosts file first)
   - **Backend health**: Test API directly: `curl http://INGRESS_IP/api/health`

5. **Terraform Issues**
   - **"Must be unique" error**: This is now avoided by checking for existing clusters first
   - **Skipped entirely**: If cluster exists, Terraform steps are automatically skipped
   - **Only runs when needed**: Terraform only executes for new cluster creation

5. **Pipeline Loop Prevention**
   - **Path exclusions**: Workflow ignores changes to `helm-charts/**/values.yaml` to prevent loops
   - **Skip CI commits**: Automation commits include `[skip ci]` to prevent re-triggering
   - **Smart detection**: Checks commit history to avoid unnecessary runs
   - **Documentation ignored**: Changes to `.md` files don't trigger deployments

### Existing Cluster Handling

The workflow intelligently handles existing LKE clusters:
- **Automatic detection**: Checks Linode API for clusters with matching names
- **Skip Terraform**: If cluster exists, bypasses all Terraform steps completely
- **Direct connection**: Downloads kubeconfig directly from Linode API
- **Zero conflicts**: No state management issues or "unique" errors
- **Fast deployment**: Existing clusters deploy 3x faster by skipping infrastructure setup

### Debugging Steps

1. Check the GitHub Actions logs for detailed error messages
2. Use `kubectl` commands in the workflow to inspect resources
3. Check Flux status: `flux get all`
4. Verify Helm releases: `helm list -A`

### Specific Issue: NGINX 404 on Direct IP Access

If you're getting 404 errors when accessing the ingress IP directly:

#### Quick Diagnosis
```bash
# 1. Check if ingress is deployed
kubectl get ingress -A

# 2. Check if services exist
kubectl get services -A

# 3. Check if pods are running
kubectl get pods -A

# 4. Check ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# 5. Test API endpoint directly
curl http://45.79.63.243/api/health
```

#### Common Solutions
1. **Use domain instead of IP**: Add `45.79.63.243 randomcorp.local` to your hosts file
2. **Wait for deployment**: Applications may still be starting up
3. **Check Flux sync**: Run `kubectl get helmrelease -A` to see deployment status
4. **Verify ingress rules**: The ingress should have both domain and IP-based rules

#### Expected Behavior
- `http://45.79.63.243/` → Frontend application
- `http://45.79.63.243/api/health` → API health check
- `http://randomcorp.local/` → Frontend (with hosts file entry)

## Security Considerations

- Secrets are encrypted and only accessible during workflow execution
- API tokens should have minimal required permissions
- Consider using short-lived tokens for enhanced security
- Regularly rotate access tokens

## Cost Optimization

The LKE cluster includes auto-scaling:
- **Minimum**: 3 nodes (g6-standard-2)
- **Maximum**: 10 nodes
- **Auto-scaling**: Based on resource usage

Monitor your Linode costs and adjust node types/counts as needed...
