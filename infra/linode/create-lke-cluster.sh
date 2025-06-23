#!/bin/bash

# Linode LKE Cluster Creation Script
# Requirements: linode-cli installed and configured

set -e

# Configuration
CLUSTER_NAME="randomcorp-lke"
REGION="us-east"  # Change as needed (us-central, eu-west, ap-south, etc.)
NODE_TYPE="g6-nanode-1"  # g6-nanode-1 ($5/mo) or g6-standard-1 ($10/mo)
NODE_COUNT=3
K8S_VERSION="1.27"  # Use latest stable version

echo "🚀 Creating Linode LKE cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo "Node Type: $NODE_TYPE"
echo "Node Count: $NODE_COUNT"
echo "Kubernetes Version: $K8S_VERSION"
echo ""

# Check if linode-cli is configured
if ! linode-cli --version > /dev/null 2>&1; then
    echo "❌ linode-cli not found. Please install and configure:"
    echo "pip install linode-cli"
    echo "linode-cli configure"
    exit 1
fi

# Create the LKE cluster
echo "📋 Creating LKE cluster..."
CLUSTER_ID=$(linode-cli lke cluster-create \
    --label "$CLUSTER_NAME" \
    --region "$REGION" \
    --k8s_version "$K8S_VERSION" \
    --node_pools.type "$NODE_TYPE" \
    --node_pools.count "$NODE_COUNT" \
    --text --no-header --format="id")

if [ -z "$CLUSTER_ID" ]; then
    echo "❌ Failed to create cluster"
    exit 1
fi

echo "✅ Cluster created with ID: $CLUSTER_ID"
echo "⏳ Waiting for cluster to be ready (this may take 5-10 minutes)..."

# Wait for cluster to be ready
while true; do
    STATUS=$(linode-cli lke cluster-view "$CLUSTER_ID" --text --no-header --format="status")
    if [ "$STATUS" = "ready" ]; then
        echo "✅ Cluster is ready!"
        break
    fi
    echo "⏳ Cluster status: $STATUS (waiting...)"
    sleep 30
done

# Download kubeconfig
echo "📥 Downloading kubeconfig..."
linode-cli lke kubeconfig-view "$CLUSTER_ID" --text --no-header > kubeconfig-randomcorp.yaml

# Set proper permissions
chmod 600 kubeconfig-randomcorp.yaml

echo ""
echo "🎉 LKE cluster created successfully!"
echo ""
echo "Next steps:"
echo "1. Export kubeconfig: export KUBECONFIG=\$(pwd)/kubeconfig-randomcorp.yaml"
echo "2. Verify cluster: kubectl get nodes"
echo "3. Install Flux: ./install-flux.sh"
echo "4. Deploy application: ./deploy-app.sh"
echo ""
echo "Cluster Details:"
echo "- Cluster ID: $CLUSTER_ID"
echo "- Name: $CLUSTER_NAME"
echo "- Region: $REGION"
echo "- Nodes: $NODE_COUNT x $NODE_TYPE"
echo "- Monthly Cost: ~\$$(($NODE_COUNT * 5 + 12)) (including NodeBalancer + storage)"
