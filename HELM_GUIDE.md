# Helm Chart Guide for hello-gke Application

This guide provides comprehensive instructions for using Helm to deploy and manage the hello-gke Spring Boot application on Google Kubernetes Engine (GKE).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Helm Chart Structure](#helm-chart-structure)
3. [Installation Steps](#installation-steps)
4. [Deployment Workflows](#deployment-workflows)
5. [Configuration Management](#configuration-management)
6. [Upgrade and Rollback](#upgrade-and-rollback)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

---

## Prerequisites

### Required Tools
- Helm 3.x or higher
- kubectl 1.36+
- GKE cluster configured and accessible
- Docker image pushed to Google Container Registry (GCR)

### Verify Helm Installation
```bash
helm version
helm repo list
```

### Update Helm Repositories (Optional)
```bash
helm repo update
```

---

## Helm Chart Structure

```
helm/hello-gke/
├── Chart.yaml                 # Chart metadata
├── values.yaml               # Default configuration values
├── values-dev.yaml          # Development environment overrides
├── values-prod.yaml         # Production environment overrides
└── templates/
    ├── _helpers.tpl         # Helm template helpers
    ├── deployment.yaml      # Kubernetes Deployment
    ├── service.yaml         # Kubernetes Service
    ├── configmap.yaml       # Application configuration
    ├── serviceaccount.yaml  # Service Account for RBAC
    ├── hpa.yaml            # Horizontal Pod Autoscaler
    └── NOTES.txt           # Post-installation instructions
```

### Chart Configuration

**Chart.yaml** - Contains metadata:
- Chart name, version, and app version
- Description and keywords
- Maintainer information
- Dependencies (if any)

**values.yaml** - Default configuration:
- Image repository and tag
- Replica count
- Resource requests/limits
- Health check settings
- Service type and port configuration
- Security context settings
- Volume mounts and autoscaling configuration

---

## Installation Steps

### Step 1: Verify GKE Cluster Access

```bash
# Check cluster connectivity
kubectl cluster-info

# Get current context
kubectl config current-context

# List available namespaces
kubectl get namespaces
```

### Step 2: Create Namespace (Optional)

```bash
kubectl create namespace hello-gke
```

### Step 3: Validate Helm Chart

```bash
# Validate the chart syntax
helm lint helm/hello-gke/

# Check generated manifest (dry-run)
helm template hello-gke helm/hello-gke/ \
  --values helm/hello-gke/values.yaml \
  --namespace default
```

### Step 4: Update Configuration Values

Edit the appropriate values file and update:

**For Development:**
```bash
# Update values-dev.yaml
vim helm/hello-gke/values-dev.yaml

# Key settings:
# - global.projectId: your-dev-project-id
# - image.tag: latest
# - app.replicaCount: 1
```

**For Production:**
```bash
# Update values-prod.yaml
vim helm/hello-gke/values-prod.yaml

# Key settings:
# - global.projectId: your-prod-project-id
# - image.tag: v1.0.0 (use versioned tags)
# - app.replicaCount: 5
```

### Step 5: Install Helm Release

#### Development Environment
```bash
export PROJECT_ID=$(gcloud config get-value project)

helm install hello-gke helm/hello-gke/ \
  --namespace default \
  --values helm/hello-gke/values-dev.yaml \
  --set global.projectId=${PROJECT_ID} \
  --set image.tag=latest
```

#### Production Environment
```bash
export PROJECT_ID=$(gcloud config get-value project)
export IMAGE_VERSION=v1.0.0

helm install hello-gke helm/hello-gke/ \
  --namespace default \
  --values helm/hello-gke/values-prod.yaml \
  --set global.projectId=${PROJECT_ID} \
  --set image.tag=${IMAGE_VERSION} \
  --set app.replicaCount=5
```

### Step 6: Verify Installation

```bash
# List releases
helm list

# Get release status
helm status hello-gke

# Check deployed resources
kubectl get all -l app.kubernetes.io/instance=hello-gke

# View pod status
kubectl get pods -l app.kubernetes.io/name=hello-gke

# Check service and external IP
kubectl get svc hello-gke
```

### Step 7: Test the Application

```bash
# Get external IP
export EXTERNAL_IP=$(kubectl get svc hello-gke \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "External IP: $EXTERNAL_IP"

# Test endpoints
curl http://${EXTERNAL_IP}/
curl http://${EXTERNAL_IP}/api/hello
curl http://${EXTERNAL_IP}/actuator/health

# View logs
helm test hello-gke 2>/dev/null || kubectl logs -l app.kubernetes.io/name=hello-gke --tail=50 -f
```

---

## Deployment Workflows

### Quick Start - Single Command Deployment

```bash
export PROJECT_ID=$(gcloud config get-value project)

# Full deployment in one command
helm install hello-gke helm/hello-gke/ \
  --namespace default \
  --values helm/hello-gke/values.yaml \
  --set global.projectId=${PROJECT_ID} \
  --wait \
  --timeout 5m
```

### Multi-Environment Deployment

```bash
# Deploy to development
helm install hello-gke-dev helm/hello-gke/ \
  --namespace dev \
  --values helm/hello-gke/values-dev.yaml \
  --set global.projectId=my-dev-project

# Deploy to production
helm install hello-gke-prod helm/hello-gke/ \
  --namespace prod \
  --values helm/hello-gke/values-prod.yaml \
  --set global.projectId=my-prod-project
```

### Deployment with Custom Values

```bash
# Override specific values at command line
helm install hello-gke helm/hello-gke/ \
  --namespace default \
  --values helm/hello-gke/values.yaml \
  --set app.replicaCount=3 \
  --set image.tag=v1.0.1 \
  --set service.type=LoadBalancer \
  --set resources.limits.memory=1Gi
```

---

## Configuration Management

### View Current Configuration

```bash
# Get release values
helm get values hello-gke

# Get all release manifests
helm get manifest hello-gke

# Get release notes
helm get notes hello-gke

# Get release hooks
helm get hooks hello-gke
```

### Modify Configuration

```bash
# Edit values and upgrade (dry-run first)
helm upgrade hello-gke helm/hello-gke/ \
  --namespace default \
  --values helm/hello-gke/values.yaml \
  --dry-run --debug

# Apply the changes
helm upgrade hello-gke helm/hello-gke/ \
  --namespace default \
  --values helm/hello-gke/values.yaml
```

### Update Application Properties

Edit the appropriate values file and update the `app.properties` section:

```yaml
app:
  properties:
    message: "updated message"
    logLevel: "DEBUG"
    environment: "gke"
```

Then upgrade:
```bash
helm upgrade hello-gke helm/hello-gke/ \
  --values helm/hello-gke/values.yaml
```

---

## Upgrade and Rollback

### Upgrade Release

```bash
# Upgrade with new image version
helm upgrade hello-gke helm/hello-gke/ \
  --namespace default \
  --values helm/hello-gke/values.yaml \
  --set image.tag=v1.0.1 \
  --wait

# Verify upgrade
helm status hello-gke
helm history hello-gke
```

### Rollback Release

```bash
# View release history
helm history hello-gke

# Rollback to previous release
helm rollback hello-gke

# Rollback to specific revision
helm rollback hello-gke 2

# Verify rollback
helm status hello-gke
kubectl get pods -l app.kubernetes.io/name=hello-gke
```

### Blue-Green Deployment

```bash
# Install blue version
helm install hello-gke-blue helm/hello-gke/ \
  --namespace default \
  --set image.tag=v1.0.0

# Install green version
helm install hello-gke-green helm/hello-gke/ \
  --namespace default \
  --set image.tag=v1.0.1

# Switch traffic (update service selector)
kubectl patch svc hello-gke -p '{"spec":{"selector":{"version":"green"}}}'

# Delete old version
helm uninstall hello-gke-blue
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Release Not Deploying

```bash
# Check Helm release status
helm status hello-gke

# Check pod events
kubectl describe pod <pod-name>

# View pod logs
kubectl logs -l app.kubernetes.io/name=hello-gke --tail=100

# Check ConfigMap
kubectl get configmap hello-gke-config -o yaml
```

#### Issue 2: Image Pull Errors

```bash
# Verify image exists in GCR
gcloud container images list --filter="name:hello-gke"

# Check image pull policy
helm get values hello-gke | grep -A 2 image

# Update image reference
helm upgrade hello-gke helm/hello-gke/ \
  --set image.tag=latest \
  --set image.pullPolicy=Always
```

#### Issue 3: Pods Not Ready

```bash
# Check readiness probes
kubectl get pods -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")]}' \
  -l app.kubernetes.io/name=hello-gke

# Check pod events
kubectl describe pods -l app.kubernetes.io/name=hello-gke

# View application logs
kubectl logs -l app.kubernetes.io/name=hello-gke -f
```

#### Issue 4: Service Not Getting External IP

```bash
# Check service status
kubectl get svc hello-gke -o wide

# For LoadBalancer type services
kubectl describe svc hello-gke

# Check for pending state (GKE needs time to provision)
kubectl get svc hello-gke --watch
```

### Debug Commands

```bash
# Detailed dry-run before applying
helm template hello-gke helm/hello-gke/ \
  --namespace default \
  --values helm/hello-gke/values.yaml \
  --debug > manifest.yaml

# Check template rendering
helm template hello-gke helm/hello-gke/ \
  --show-only templates/deployment.yaml

# Validate YAML syntax
helm lint helm/hello-gke/ --strict

# List all resources that will be created
helm template hello-gke helm/hello-gke/ | kubectl apply --dry-run=client -f -
```

---

## Best Practices

### 1. Version Control

```bash
# Always use semantic versioning for charts
# Chart version in Chart.yaml: 1.0.0
# App version in Chart.yaml: 1.0.0

# Use version tags for images
# values-prod.yaml: image.tag: v1.0.0 (not 'latest')
```

### 2. Environment Separation

```bash
# Maintain separate values files
helm/hello-gke/
├── values.yaml        # Base configuration
├── values-dev.yaml    # Development
├── values-staging.yaml # Staging
└── values-prod.yaml   # Production

# Deploy with appropriate values file
helm install hello-gke helm/hello-gke/ \
  -f helm/hello-gke/values-${ENV}.yaml
```

### 3. Resource Management

```bash
# Always specify resource requests and limits
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"

# Use HPA for production
autoscaling:
  enabled: true
  minReplicas: 5
  maxReplicas: 20
```

### 4. Security

```bash
# Use non-root user
containerSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000

# Read-only root filesystem
readOnlyRootFilesystem: true

# Drop all capabilities
capabilities:
  drop:
    - ALL
```

### 5. Monitoring and Logging

```bash
# Enable health checks
healthChecks:
  liveness:
    enabled: true
  readiness:
    enabled: true

# Set appropriate log levels
app:
  properties:
    logLevel: "WARN"        # Production
    logLevelApp: "INFO"     # Application code
```

### 6. Documentation

```bash
# Keep README updated
# Document all custom values
# Include troubleshooting steps
# List dependencies clearly
```

### 7. Testing

```bash
# Lint chart before deployment
helm lint helm/hello-gke/

# Dry-run installation
helm install hello-gke helm/hello-gke/ \
  --dry-run --debug

# Test with different values
helm template hello-gke helm/hello-gke/ \
  -f values-dev.yaml > dev.yaml
helm template hello-gke helm/hello-gke/ \
  -f values-prod.yaml > prod.yaml
```

### 8. Release Management

```bash
# Always have a release naming convention
# Example: app-name-environment
# hello-gke-dev, hello-gke-staging, hello-gke-prod

# Tag releases in git
git tag -a hello-gke-1.0.0 -m "Release version 1.0.0"

# Keep change history
helm history hello-gke

# Document changes in CHANGELOG.md
```

---

## Advanced Helm Usage

### Using Helm Hooks

Helm supports lifecycle hooks for running scripts at specific points:

```yaml
# Pre-install hook (in templates/)
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "hello-gke.fullname" . }}-pre-install
  annotations:
    "helm.sh/hook": pre-install
spec:
  # Job definition
```

### Helm Secrets (Optional)

For sensitive data, consider using helm-secrets:

```bash
# Install helm-secrets plugin
helm plugin install https://github.com/jkroepke/helm-secrets

# Encrypt secrets
helm secrets enc secrets.yaml

# Deploy with encrypted secrets
helm install hello-gke helm/hello-gke/ \
  -f <(helm secrets dec secrets.yaml)
```

### Helm Dependencies

If your chart depends on other charts:

```bash
# Define in Chart.yaml
dependencies:
  - name: redis
    version: "17.x.x"
    repository: https://charts.bitnami.com/bitnami

# Update dependencies
helm dependency update helm/hello-gke/
```

---

## Summary of Commands

| Task | Command |
|------|---------|
| Validate Chart | `helm lint helm/hello-gke/` |
| Install | `helm install hello-gke helm/hello-gke/ -f values.yaml` |
| Upgrade | `helm upgrade hello-gke helm/hello-gke/ -f values.yaml` |
| Rollback | `helm rollback hello-gke` |
| Uninstall | `helm uninstall hello-gke` |
| List Releases | `helm list` |
| Get Values | `helm get values hello-gke` |
| Get Manifest | `helm get manifest hello-gke` |
| History | `helm history hello-gke` |
| Status | `helm status hello-gke` |

---

## Next Steps

1. Update `values.yaml` with your GCP project ID
2. Validate the chart with `helm lint`
3. Test with `helm template` and dry-run
4. Install to development environment
5. Test application endpoints
6. Upgrade to production with proper versioning
7. Monitor and maintain releases

For more information, visit: https://helm.sh/docs/
