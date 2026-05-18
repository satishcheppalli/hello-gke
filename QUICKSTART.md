# Hello GKE - Quick Start Guide

## 1. Build Application Locally

```bash
# Navigate to project directory
cd hello-gke

# Build with Gradle
gradle clean build

# Or use gradle wrapper
./gradlew clean build

# Run locally
gradle bootRun
```

Access: http://localhost:8080/api/hello

## 2. Build and Push Docker Image

```bash
# Set your GCP Project ID
export PROJECT_ID=your-gcp-project-id

# Make script executable
chmod +x scripts/build-and-push.sh

# Build and push to Google Container Registry
./scripts/build-and-push.sh $PROJECT_ID
```

## 3. Deploy to GKE

```bash
# Ensure kubectl is configured for your GKE cluster
gcloud container clusters get-credentials <cluster-name> --zone <zone>

# Make script executable
chmod +x scripts/deploy.sh

# Deploy to GKE
./scripts/deploy.sh $PROJECT_ID
```

## 4. Verify Deployment

```bash
# Check pods
kubectl get pods -l app=hello-gke

# Get service external IP
kubectl get svc hello-gke

# Test the application
curl http://<EXTERNAL_IP>/api/hello
```

## 5. View Logs

```bash
# Real-time logs
kubectl logs -f deployment/hello-gke

# Logs from specific pod
kubectl logs <pod-name>
```

## Key Endpoints

| Endpoint | Purpose |
|----------|---------|
| GET `/api/hello` | Returns "hello gke" message |
| GET `/` | Alias for `/api/hello` |
| GET `/actuator/health` | Health check endpoint |
| GET `/actuator/health/liveness` | Kubernetes liveness probe |
| GET `/actuator/health/readiness` | Kubernetes readiness probe |

## Configuration

Edit `src/main/resources/application.properties`:
- `app.message` - Main message (default: "hello gke")
- `app.version` - Application version
- `app.environment` - Environment name
- `server.port` - Server port (default: 8080)

## Docker Build (Manual)

```bash
# Build image
docker build -t gcr.io/$PROJECT_ID/hello-gke:latest .

# Push to GCR
docker push gcr.io/$PROJECT_ID/hello-gke:latest
```

## Kubernetes Manifests

- `k8s/deployment.yaml` - Deployment, Service, ConfigMap, ServiceAccount
- `k8s/hpa.yaml` - Horizontal Pod Autoscaler
- `k8s/ingress.yaml` - Ingress configuration

## Troubleshooting

```bash
# Check deployment status
kubectl describe deployment hello-gke

# Check pod events
kubectl describe pod <pod-name>

# Check service status
kubectl describe svc hello-gke

# Tail logs
kubectl logs -f deployment/hello-gke

# Get into pod shell (for debugging)
kubectl exec -it <pod-name> -- /bin/bash
```

## Clean Up

```bash
# Delete all resources
kubectl delete -f k8s/

# Or delete specific resource
kubectl delete deployment hello-gke
kubectl delete svc hello-gke
```

## Performance Monitoring

```bash
# Check HPA status
kubectl get hpa hello-gke-hpa

# View HPA details
kubectl describe hpa hello-gke-hpa

# Monitor resource usage
kubectl top pods -l app=hello-gke
kubectl top nodes
```

## Next Steps

1. ✅ Build the application: `gradle build`
2. ✅ Build Docker image: `./scripts/build-and-push.sh <PROJECT_ID>`
3. ✅ Deploy to GKE: `./scripts/deploy.sh <PROJECT_ID>`
4. ✅ Access via external IP or domain
5. ✅ Monitor with: `kubectl logs -f deployment/hello-gke`

## Resources

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Google Cloud GKE](https://cloud.google.com/kubernetes-engine/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Gradle Documentation](https://docs.gradle.org/)
