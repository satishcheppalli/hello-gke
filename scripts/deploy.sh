#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Hello GKE Kubernetes Deployment Script ===${NC}"

# Check if PROJECT_ID is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: GCP Project ID is required${NC}"
    echo "Usage: ./scripts/deploy.sh <GCP_PROJECT_ID>"
    exit 1
fi

PROJECT_ID=$1

echo -e "${GREEN}Updating Kubernetes manifests with PROJECT_ID: ${PROJECT_ID}${NC}"

# Backup original files
cp k8s/deployment.yaml k8s/deployment.yaml.bak
cp k8s/deployment.yaml k8s/deployment.yaml.tmp

# Replace PROJECT_ID in deployment.yaml
sed -i.bak "s/PROJECT_ID/${PROJECT_ID}/g" k8s/deployment.yaml

echo -e "${GREEN}Applying Kubernetes manifests...${NC}"

# Apply deployment, service, configmap, and service account
echo -e "${YELLOW}Deploying Deployment, Service, ConfigMap, and ServiceAccount...${NC}"
kubectl apply -f k8s/deployment.yaml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Deployment applied successfully${NC}"
else
    echo -e "${RED}✗ Deployment failed${NC}"
    mv k8s/deployment.yaml.bak k8s/deployment.yaml
    exit 1
fi

# Apply HPA
echo -e "${YELLOW}Deploying Horizontal Pod Autoscaler...${NC}"
kubectl apply -f k8s/hpa.yaml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ HPA applied successfully${NC}"
else
    echo -e "${RED}✗ HPA deployment failed${NC}"
fi

# Apply Ingress
echo -e "${YELLOW}Deploying Ingress...${NC}"
kubectl apply -f k8s/ingress.yaml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Ingress applied successfully${NC}"
else
    echo -e "${RED}✗ Ingress deployment failed${NC}"
fi

echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo -e "${YELLOW}Verifying deployment status...${NC}"
echo ""

# Wait for deployment to be ready
kubectl rollout status deployment/hello-gke --timeout=5m

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Deployment is ready${NC}"
else
    echo -e "${YELLOW}⚠ Deployment status check timed out${NC}"
fi

echo ""
echo -e "${YELLOW}Deployment information:${NC}"
echo ""
echo "Pods:"
kubectl get pods -l app=hello-gke -o wide
echo ""
echo "Service:"
kubectl get svc hello-gke
echo ""
echo -e "${YELLOW}To access the application:${NC}"
EXTERNAL_IP=$(kubectl get svc hello-gke -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$EXTERNAL_IP" ]; then
    echo "External IP is pending. Check status with: kubectl get svc hello-gke"
else
    echo "curl http://${EXTERNAL_IP}/api/hello"
fi
echo ""
echo -e "${YELLOW}To view logs:${NC}"
echo "kubectl logs -f deployment/hello-gke"
echo ""
echo -e "${YELLOW}To check HPA status:${NC}"
echo "kubectl get hpa hello-gke-hpa"
