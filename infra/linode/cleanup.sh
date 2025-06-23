#!/bin/bash

# Delete Linode LKE cluster and cleanup resources
# Use this to save costs when not needed

set -e

# Configuration
CLUSTER_NAME="randomcorp-lke"

echo "🗑️ Cleaning up Linode LKE cluster: $CLUSTER_NAME"
echo ""

# Check if linode-cli is configured
if ! linode-cli --version > /dev/null 2>&1; then
    echo "❌ linode-cli not found. Please install and configure."
    exit 1
fi

# Find cluster ID
echo "🔍 Finding cluster..."
CLUSTER_ID=$(linode-cli lke clusters-list --text --no-header --format="id,label" | grep "$CLUSTER_NAME" | cut -f1)

if [ -z "$CLUSTER_ID" ]; then
    echo "❌ Cluster '$CLUSTER_NAME' not found"
    echo "Available clusters:"
    linode-cli lke clusters-list --text --no-header --format="id,label"
    exit 1
fi

echo "✅ Found cluster: $CLUSTER_NAME (ID: $CLUSTER_ID)"

# Confirm deletion
echo ""
echo "⚠️ This will permanently delete the cluster and all data!"
echo "💰 This will stop all recurring charges for this cluster."
echo ""
read -p "Are you sure you want to delete cluster '$CLUSTER_NAME'? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Deletion cancelled"
    exit 0
fi

# Delete the cluster
echo ""
echo "🗑️ Deleting cluster..."
linode-cli lke cluster-delete "$CLUSTER_ID"

echo "✅ Cluster deletion initiated"
echo ""
echo "🕐 The cluster and all resources will be deleted in a few minutes"
echo "💰 Billing will stop once deletion is complete"
echo ""
echo "🧹 Local cleanup:"
echo "  - Remove kubeconfig: rm kubeconfig-randomcorp.yaml"
echo "  - Remove from git: git rm -rf clusters/linode-lke/"
