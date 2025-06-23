#!/bin/bash

# Install Flux v2 on Linode LKE cluster
# This sets up GitOps for continuous deployment

set -e

# Configuration
GITHUB_USER="your-github-username"  # Change this!
GITHUB_REPO="RandomCorp"
GITHUB_TOKEN_FILE="github-token.txt"  # Create this file with your GitHub token
FLUX_NAMESPACE="flux-system"

echo "🔄 Installing Flux v2 for GitOps deployment"
echo ""

# Check prerequisites
if ! kubectl version --client > /dev/null 2>&1; then
    echo "❌ kubectl not found. Please install kubectl."
    exit 1
fi

if ! flux version --client > /dev/null 2>&1; then
    echo "📥 Installing Flux CLI..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -s https://fluxcd.io/install.sh | sudo bash
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install fluxcd/tap/flux
    else
        echo "❌ Please install Flux CLI manually: https://fluxcd.io/flux/installation/"
        exit 1
    fi
fi

# Check GitHub token
if [ ! -f "$GITHUB_TOKEN_FILE" ]; then
    echo "❌ GitHub token file not found: $GITHUB_TOKEN_FILE"
    echo "Create this file with your GitHub Personal Access Token"
    echo "Token needs 'repo' permissions"
    exit 1
fi

GITHUB_TOKEN=$(cat "$GITHUB_TOKEN_FILE")

# Check cluster connection
echo "🔍 Checking cluster connection..."
if ! kubectl get nodes > /dev/null 2>&1; then
    echo "❌ Cannot connect to cluster. Check your kubeconfig:"
    echo "export KUBECONFIG=\$(pwd)/kubeconfig-randomcorp.yaml"
    exit 1
fi

echo "✅ Connected to cluster:"
kubectl get nodes

# Pre-flight check
echo ""
echo "🧪 Running Flux pre-flight check..."
flux check --pre

# Bootstrap Flux
echo ""
echo "🚀 Bootstrapping Flux..."
flux bootstrap github \
    --owner="$GITHUB_USER" \
    --repository="$GITHUB_REPO" \
    --branch=main \
    --path=clusters/linode-lke \
    --personal \
    --token-auth

echo ""
echo "✅ Flux installed successfully!"
echo ""
echo "📁 Flux will monitor: clusters/linode-lke/ in your repository"
echo "🔄 Any changes to YAML files in that directory will be automatically deployed"
echo ""
echo "Next steps:"
echo "1. Commit the generated flux-system files to your repo"
echo "2. Create application manifests in clusters/linode-lke/"
echo "3. Use './deploy-app.sh' to set up the initial application structure"
