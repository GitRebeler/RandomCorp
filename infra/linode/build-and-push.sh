#!/bin/bash

# Build and push Docker images to a container registry
# Supports Docker Hub, Linode Container Registry, or other registries

set -e

# Configuration - UPDATE THESE!
REGISTRY="your-registry"  # e.g., "docker.io/yourusername" or "us-east-1.linodeobjects.com/your-registry"
API_IMAGE_NAME="randomcorp"
FRONTEND_IMAGE_NAME="randomcorp-frontend"
TAG="latest"

echo "🐳 Building and pushing Random Corp Docker images"
echo "Registry: $REGISTRY"
echo "API Image: $REGISTRY/$API_IMAGE_NAME:$TAG"
echo "Frontend Image: $REGISTRY/$FRONTEND_IMAGE_NAME:$TAG"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker."
    exit 1
fi

# Build API image
echo "🔨 Building API image..."
cd api
docker build -t "$REGISTRY/$API_IMAGE_NAME:$TAG" .
echo "✅ API image built successfully"

# Build Frontend image  
echo "🔨 Building Frontend image..."
cd ..
docker build -t "$REGISTRY/$FRONTEND_IMAGE_NAME:$TAG" .
echo "✅ Frontend image built successfully"

# Push images
echo "📤 Pushing images to registry..."

echo "📤 Pushing API image..."
docker push "$REGISTRY/$API_IMAGE_NAME:$TAG"
echo "✅ API image pushed successfully"

echo "📤 Pushing Frontend image..."
docker push "$REGISTRY/$FRONTEND_IMAGE_NAME:$TAG"
echo "✅ Frontend image pushed successfully"

echo ""
echo "🎉 All images built and pushed successfully!"
echo ""
echo "📋 Update these values in your Helm chart (helm-charts/randomcorp/values.yaml):"
echo "  image.repository: $REGISTRY/$API_IMAGE_NAME"
echo "  frontend.image.repository: $REGISTRY/$FRONTEND_IMAGE_NAME"
echo ""
echo "🚀 Ready to deploy with Flux!"
