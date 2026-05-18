# Helm Chart Quick Start Guide

## Complete Step-by-Step Guide for hello-gke Deployment

### Prerequisites
- ✅ Helm 3.x installed
- ✅ kubectl configured
- ✅ GKE cluster running
- ✅ Docker image pushed to GCR

---

## SECTION 1: SETUP & VALIDATION

### Step 1.1: Install Helm (if not already installed)
```bash
brew install helm
helm version
```

### Step 1.2: Verify Cluster Connection
```bash
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

### Step 1.3: Create Namespace (Optional)
```bash
kubectl create namespace hello-gke
```

---

## SECTION 2: HELM CHART VALIDATION

### Step 2.1: Validate Chart Syntax
```bash
helm lint helm/hello-gke/
```

Expected output:
```
1 chart(s) linted, 0 error(s)
```

### Step 2.2: Preview Generated Manifests
```bash
helm template hello-gke helm/hello-gke/ \
  --values helm/hello-gke/values.yaml
```

### Step 2.3: Dry-Run Installation
```bash
helm install hello-gke helm/hello-gke/ \
  --values helm/hello-gke/values.yaml \
  --dry-run \
  --debug
```

---

## SECTION 3: CONFIGURE FOR YOUR ENVIRONMENT

### Step 3.1: Get Your GCP Project ID
```bash
export PROJECT_ID=$(gcloud config get-value project)
echo "Project ID: $PROJECT_ID"
```

### Step 3.2: Update Configuration Files

**For Development:**
```bash
# Edit values-dev.yaml
cat helm/hello-gke/values-dev.yaml

# Update projectId
sed -i '' "s|your-dev-project-id|${PROJECT_ID}|g" helm/hello-gke/values-dev.yaml
```

**For Production:**
```bash
# Edit values-prod.yaml
cat helm/hello-gke/values-prod.yaml

# Update projectId
sed -i '' "s|your-prod-project-id|${PROJECT_ID}|g" helm/hello-gke/values-prod.yaml
```

### Step 3.3: Verify Image Exists in GCR
```bash
gcloud container images list --filter="name:hello-gke"
gcloud container images list-tags gcr.io/${PROJECT_ID}/hello-gke
```

---

## SECTION 4: INSTALL HELM RELEASE

### Step 4.1: Install to Development Environment
```bash
helm install hello-gke helm/hello-gke/ \
  --namespace default \
  --values helm/hello-gke/values-dev.yaml \
  --set global.projectId=${PROJECT_ID} \
  --wait \
  --timeout 5m
```

### Step 4.2: Install to Production Environment
```bash
helm install hello-gke-prod helm/hello-gke/ \
  --namespace default \
  --values helm/hello-gke/values-prod.yaml \
  --set global.projectId=${PROJECT_ID} \
  --set image.tag=v1.0.0 \
  --wait \
  --timeout 5m
```

### Step 4.3: Verify Installation
```bash
# List Helm releases
helm list

# Check release status
helm status hello-gke

# View release values
helm get values hello-gke

# Get installation notes
helm get notes hello-gke
```

---

## SECTION 5: VERIFY DEPLOYMENT

### Step 5.1: Check Kubernetes Resources
```bash
# List all resources
kubectl get all -l app.kubernetes.io/instance=hello-gke

# Check deployment
kubectl get deployment hello-gke

# Check pods
kubectl get pods -l app.kubernetes.io/name=hello-gke -o wide

# Check service
kubectl get svc hello-gke

# Check configmap
kubectl get configmap hello-gke-config
```

### Step 5.2: Monitor Pod Status
```bash
# Watch pods come up
kubectl get pods -l app.kubernetes.io/name=hello-gke --watch

# Describe a pod for events
kubectl describe pod <pod-name>

# View pod logs
kubectl logs -l app.kubernetes.io/name=hello-gke --tail=50 -f
```

### Step 5.3: Wait for LoadBalancer IP
```bash
# Get external IP (may take 1-2 minutes)
kubectl get svc hello-gke --watch

# Save IP for testing
export EXTERNAL_IP=$(kubectl get svc hello-gke \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "External IP: $EXTERNAL_IP"
```

---

## SECTION 6: TEST APPLICATION

### Step 6.1: Test Health Endpoints
```bash
# Test root endpoint
curl http://${EXTERNAL_IP}/

# Test API endpoint
curl http://${EXTERNAL_IP}/api/hello

# Test health check
curl http://${EXTERNAL_IP}/actuator/health

# Test liveness probe
curl http://${EXTERNAL_IP}/actuator/health/liveness

# Test readiness probe
curl http://${EXTERNAL_IP}/actuator/health/readiness
```

### Step 6.2: Pretty Print JSON
```bash
curl http://${EXTERNAL_IP}/ | jq .
curl http://${EXTERNAL_IP}/api/hello | jq .
```

### Step 6.3: Test with Port Forward (if ClusterIP service)
```bash
# Port forward to local machine
kubectl port-forward svc/hello-gke 8080:80 &

# Test locally
curl http://localhost:8080/

# Stop port forward
pkill -f "port-forward"
```

---

## SECTION 7: MANAGE RELEASES

### Step 7.1: View Release History
```bash
helm history hello-gke
helm history hello-gke --max 5
```

### Step 7.2: Upgrade Release

**Update Image:**
```bash
helm upgrade hello-gke helm/hello-gke/ \
  --namespace default \
  --values helm/hello-gke/values.yaml \
  --set image.tag=v1.0.1 \
  --wait
```

**Update Configuration:**
```bash
helm upgrade hello-gke helm/hello-gke/ \
  --namespace default \
  --values helm/hello-gke/values.yaml \
  --set app.replicaCount=5 \
  --wait
```

**Update Multiple Values:**
```bash
helm upgrade hello-gke helm/hello-gke/ \
  --namespace default \
  --values helm/hello-gke/values.yaml \
  --set image.tag=v1.0.1 \
  --set app.replicaCount=5 \
  --set app.properties.logLevel=DEBUG \
  --wait
```

### Step 7.3: Verify Upgrade
```bash
helm status hello-gke
kubectl get pods -l app.kubernetes.io/name=hello-gke -o wide
kubectl logs -l app.kubernetes.io/name=hello-gke --tail=30 -f
```

---

## SECTION 8: ROLLBACK RELEASE

### Step 8.1: View Available Revisions
```bash
helm history hello-gke
```

### Step 8.2: Rollback to Previous Version
```bash
# Rollback one version
helm rollback hello-gke

# Rollback to specific revision
helm rollback hello-gke 1

# Verify rollback
helm status hello-gke
helm history hello-gke
```

---

## SECTION 9: UNINSTALL RELEASE

### Step 9.1: Delete Release
```bash
helm uninstall hello-gke

# Delete with associated PVCs (if any)
helm uninstall hello-gke --no-hooks
```

### Step 9.2: Verify Uninstall
```bash
helm list
kubectl get all -l app.kubernetes.io/name=hello-gke
```

---

## SECTION 10: TROUBLESHOOTING

### Step 10.1: Check Release Status
```bash
helm status hello-gke
helm get manifest hello-gke
helm get values hello-gke
```

### Step 10.2: View Pod Logs
```bash
# View all pod logs
kubectl logs -l app.kubernetes.io/name=hello-gke --all-containers=true

# Follow logs in real-time
kubectl logs -l app.kubernetes.io/name=hello-gke -f

# View previous logs (if pod crashed)
kubectl logs -l app.kubernetes.io/name=hello-gke --previous
```

### Step 10.3: Describe Resources
```bash
# Describe deployment
kubectl describe deployment hello-gke

# Describe pod
kubectl describe pod <pod-name>

# Describe service
kubectl describe svc hello-gke

# Describe configmap
kubectl describe configmap hello-gke-config
```

### Step 10.4: Check Events
```bash
# Get cluster events
kubectl get events --sort-by='.lastTimestamp'

# Get events for specific pod
kubectl describe pod <pod-name>
```

### Step 10.5: Debug Commands
```bash
# Execute command in pod
kubectl exec -it <pod-name> -- /bin/sh

# Copy files from pod
kubectl cp <pod-name>:/app/logs ./local-logs

# Port forward for debugging
kubectl port-forward pod/<pod-name> 8080:8080
```

---

## SECTION 11: ADVANCED OPERATIONS

### Step 11.1: Create Multiple Releases

**Development:**
```bash
helm install hello-gke-dev helm/hello-gke/ \
  --namespace dev \
  --values helm/hello-gke/values-dev.yaml \
  --set global.projectId=${PROJECT_ID}
```

**Staging:**
```bash
helm install hello-gke-staging helm/hello-gke/ \
  --namespace staging \
  --values helm/hello-gke/values.yaml \
  --set global.projectId=${PROJECT_ID}
```

**Production:**
```bash
helm install hello-gke-prod helm/hello-gke/ \
  --namespace prod \
  --values helm/hello-gke/values-prod.yaml \
  --set global.projectId=${PROJECT_ID}
```

### Step 11.2: Blue-Green Deployment
```bash
# Deploy blue version
helm install hello-gke-blue helm/hello-gke/ \
  --set image.tag=v1.0.0

# Deploy green version
helm install hello-gke-green helm/hello-gke/ \
  --set image.tag=v1.0.1

# Switch traffic by patching service
kubectl patch svc hello-gke -p '{"spec":{"selector":{"version":"green"}}}'

# Delete old version
helm uninstall hello-gke-blue
```

### Step 11.3: Scale Deployment

**Manual Scaling:**
```bash
# Scale up
helm upgrade hello-gke helm/hello-gke/ \
  --set app.replicaCount=10

# Scale down
helm upgrade hello-gke helm/hello-gke/ \
  --set app.replicaCount=2
```

**Enable Autoscaling:**
```bash
helm upgrade hello-gke helm/hello-gke/ \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=5 \
  --set autoscaling.maxReplicas=20
```

---

## SECTION 12: COMMON COMMANDS REFERENCE

| Command | Purpose |
|---------|---------|
| `helm lint helm/hello-gke/` | Validate chart syntax |
| `helm template hello-gke helm/hello-gke/` | Generate manifests |
| `helm install hello-gke helm/hello-gke/ -f values.yaml` | Install release |
| `helm upgrade hello-gke helm/hello-gke/ -f values.yaml` | Upgrade release |
| `helm rollback hello-gke` | Rollback to previous |
| `helm uninstall hello-gke` | Delete release |
| `helm list` | List all releases |
| `helm status hello-gke` | Get release status |
| `helm history hello-gke` | View release history |
| `helm get values hello-gke` | Get release values |
| `helm get manifest hello-gke` | Get generated manifests |
| `helm get notes hello-gke` | Get release notes |

---

## SECTION 13: QUICK REFERENCE - Single Command Deployments

### Deploy to Development (Quickest)
```bash
export PROJECT_ID=$(gcloud config get-value project)

helm install hello-gke helm/hello-gke/ \
  --values helm/hello-gke/values-dev.yaml \
  --set global.projectId=${PROJECT_ID} \
  --wait --timeout 5m

# Get status
helm status hello-gke
kubectl get svc hello-gke
```

### Deploy to Production (Safe)
```bash
export PROJECT_ID=$(gcloud config get-value project)

# Dry-run first
helm install hello-gke-prod helm/hello-gke/ \
  --values helm/hello-gke/values-prod.yaml \
  --set global.projectId=${PROJECT_ID} \
  --dry-run --debug > /tmp/manifest.yaml

# Review manifest
cat /tmp/manifest.yaml

# Actually deploy
helm install hello-gke-prod helm/hello-gke/ \
  --values helm/hello-gke/values-prod.yaml \
  --set global.projectId=${PROJECT_ID} \
  --wait --timeout 10m
```

---

## Helm Chart File Structure

```
helm/hello-gke/
├── Chart.yaml                 # Chart metadata and version
├── values.yaml               # Default configuration
├── values-dev.yaml          # Development overrides
├── values-prod.yaml         # Production overrides
└── templates/
    ├── _helpers.tpl         # Template helper functions
    ├── deployment.yaml      # Application deployment
    ├── service.yaml         # Service definition
    ├── configmap.yaml       # Application config
    ├── serviceaccount.yaml  # RBAC service account
    ├── hpa.yaml            # Autoscaling policy
    └── NOTES.txt           # Post-install instructions
```

---

## What's Included in the Helm Chart

✅ **Deployment** - Spring Boot app with proper resource limits  
✅ **Service** - LoadBalancer for external access  
✅ **ConfigMap** - Application configuration management  
✅ **ServiceAccount** - RBAC support  
✅ **HPA** - Horizontal Pod Autoscaler  
✅ **Security** - Non-root user, read-only filesystem, dropped capabilities  
✅ **Health Checks** - Liveness and readiness probes  
✅ **Volumes** - Writable tmp and cache directories  
✅ **Logging** - Configurable log levels  

---

## Next Steps

1. ✅ Validate chart: `helm lint helm/hello-gke/`
2. ✅ Preview manifests: `helm template hello-gke helm/hello-gke/`
3. ✅ Install release: `helm install hello-gke helm/hello-gke/ -f values.yaml`
4. ✅ Verify deployment: `helm status hello-gke` and `kubectl get pods`
5. ✅ Test endpoints: `curl http://$EXTERNAL_IP/`
6. ✅ Upgrade when needed: `helm upgrade hello-gke helm/hello-gke/ -f values.yaml`

For detailed information, see **HELM_GUIDE.md**
