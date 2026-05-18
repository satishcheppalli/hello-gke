#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Hello GKE Build and Push Script ===${NC}"

# Check if PROJECT_ID is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: GCP Project ID is required${NC}"
    echo "Usage: ./scripts/build-and-push.sh <GCP_PROJECT_ID>"
    exit 1
fi

PROJECT_ID=$1
IMAGE_NAME="hello-gke"
TAG="latest"
FULL_IMAGE_NAME="gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}"

echo -e "${GREEN}Building Docker image: ${FULL_IMAGE_NAME}${NC}"

# Build the Docker image
docker build -t ${FULL_IMAGE_NAME} .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Docker image built successfully${NC}"
else
    echo -e "${RED}✗ Docker image build failed${NC}"
    exit 1
fi

echo -e "${GREEN}Pushing image to Google Container Registry...${NC}"

# Configure Docker authentication with gcloud
gcloud auth configure-docker

# Push the image
docker push ${FULL_IMAGE_NAME}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Image pushed successfully to ${FULL_IMAGE_NAME}${NC}"
else
    echo -e "${RED}✗ Failed to push image${NC}"
    exit 1
fi

echo -e "${GREEN}=== Build and Push Complete ===${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update k8s/deployment.yaml with your PROJECT_ID if not already done"
echo "2. Run: kubectl apply -f k8s/deployment.yaml"
echo "3. Run: kubectl get svc hello-gke to get the external IP"
