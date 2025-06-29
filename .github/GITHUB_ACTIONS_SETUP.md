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
- `GITHUB_TOKEN` - Automatically provided by GitHub Actions

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
- Creates Linode LKE cluster if it doesn't exist
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
- Push to `main` or `master` branch
- Pull requests to `main` or `master` branch

## Expected Runtime

- **First deployment**: ~15-20 minutes (includes cluster creation)
- **Subsequent deployments**: ~5-10 minutes (cluster already exists)

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

### Debugging Steps

1. Check the GitHub Actions logs for detailed error messages
2. Use `kubectl` commands in the workflow to inspect resources
3. Check Flux status: `flux get all`
4. Verify Helm releases: `helm list -A`

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

Monitor your Linode costs and adjust node types/counts as needed.
