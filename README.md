# Hello GKE - Java Spring Boot Application

A Spring Boot application that displays "hello gke" when accessed via external URL. Built with Gradle, containerized with Docker, and deployed on Google Kubernetes Engine (GKE).

## Architecture

- **Framework**: Spring Boot 3.1.5
- **Language**: Java 17
- **Build Tool**: Gradle
- **Container Registry**: Google Container Registry (GCR)
- **Deployment**: Google Kubernetes Engine (GKE)

## Project Structure

```
hello-gke/
├── src/
│   └── main/
│       ├── java/com/example/
│       │   ├── HelloGkeApplication.java
│       │   ├── controller/
│       │   │   └── HelloController.java
│       │   ├── exception/
│       │   │   ├── ApplicationException.java
│       │   │   └── GlobalExceptionHandler.java
│       │   └── response/
│       │       └── ApiResponse.java
│       └── resources/
│           └── application.properties
├── k8s/
│   ├── deployment.yaml
│   ├── hpa.yaml
│   └── ingress.yaml
├── Dockerfile
├── build.gradle
├── .dockerignore
├── .gitignore
└── README.md
```

## Configuration

All configuration is managed through `src/main/resources/application.properties`:

```properties
app.message=hello gke           # Main message displayed
app.version=1.0.0               # Application version
app.environment=gke             # Environment name
server.port=8080                # Server port
logging.level.root=INFO         # Logging level
```

No hardcoded values in the Java code - all configuration is externalized.

## Building Locally

### Prerequisites
- Java 17+
- Gradle 8.0+
- Docker 20.10+

### Build Steps

1. **Clone the repository**
```bash
cd hello-gke
```

2. **Build with Gradle**
```bash
gradle clean build
```

3. **Run locally**
```bash
gradle bootRun
```

The application will be available at `http://localhost:8080/api/hello`

## Docker Build and Push

### Prerequisites
- Docker installed and running
- Google Cloud Project with GCR enabled
- `gcloud` CLI configured with appropriate permissions

### Build and Push Image

1. **Set your GCP Project ID**
```bash
export PROJECT_ID=gcp-poc-496714  #your-gcp-project-id
```

2. **Build Docker image**
```bash
docker build -t gcr.io/${PROJECT_ID}/hello-gke:latest .
```

3. **Push to Google Container Registry**
```bash
docker push gcr.io/${PROJECT_ID}/hello-gke:latest
```

4. **Verify image in GCR**
```bash
gcloud container images list --repository=gcr.io/${PROJECT_ID}
```

## GKE Deployment

### Prerequisites
- GKE cluster created and configured
- `kubectl` configured to access your GKE cluster
- Docker image pushed to GCR

### Deployment Steps

1. **Update deployment.yaml**
Replace `PROJECT_ID` with your actual GCP project ID:
```bash
sed -i 's/PROJECT_ID/your-gcp-project-id/g' k8s/deployment.yaml
```

2. **Apply Kubernetes manifests**
```bash
# Deploy application
kubectl apply -f k8s/deployment.yaml

# Deploy Horizontal Pod Autoscaler
kubectl apply -f k8s/hpa.yaml

# Deploy Ingress (optional, requires configured static IP)
kubectl apply -f k8s/ingress.yaml
```

3. **Verify deployment**
```bash
# Check pods
kubectl get pods -l app=hello-gke

# Check service
kubectl get svc hello-gke

# Check logs
kubectl logs -l app=hello-gke
```

4. **Access the application**
```bash
# Get external IP
kubectl get svc hello-gke

# Access via external IP
curl http://EXTERNAL_IP/api/hello
```

## API Endpoints

### 1. Hello Endpoint
**Request**
```bash
GET /api/hello
```

**Response (Success)**
```json
{
  "message": "hello gke",
  "version": "1.0.0",
  "environment": "gke",
  "success": true
}
```

**Response (Error)**
```json
{
  "success": false,
  "error": "Error message describing what went wrong"
}
```

### 2. Root Endpoint
**Request**
```bash
GET /
```
Same response as `/api/hello`

## Health Checks

The application provides health check endpoints for Kubernetes:

```bash
# Liveness probe (checks if app is running)
curl http://localhost:8080/actuator/health/liveness

# Readiness probe (checks if app is ready to serve traffic)
curl http://localhost:8080/actuator/health/readiness

# Full health details
curl http://localhost:8080/actuator/health
```

## Exception Handling

The application includes comprehensive exception handling:

- **ApplicationException**: Custom application exceptions with error codes
- **GlobalExceptionHandler**: Central exception handling with proper HTTP status codes
- **Logging**: All errors are logged for debugging and monitoring

### Exception Scenarios Handled:
- Missing configuration properties
- Application processing errors
- Resource not found (404)
- Generic unhandled exceptions (500)

## Security Features

- **Non-root User**: Container runs as non-root user (UID 1000)
- **Resource Limits**: CPU and memory limits configured
- **Security Context**: Read-only filesystem where possible
- **Health Probes**: Liveness and readiness probes for reliability
- **Capability Dropping**: All unnecessary Linux capabilities dropped

## Monitoring and Observability

The application includes Spring Boot Actuator endpoints:
- `/actuator/health` - Application health
- `/actuator/info` - Application information
- `/actuator/health/liveness` - Kubernetes liveness probe
- `/actuator/health/readiness` - Kubernetes readiness probe

## Auto-Scaling

The HPA (Horizontal Pod Autoscaler) is configured to:
- Scale based on CPU utilization (>70%)
- Scale based on memory utilization (>80%)
- Maintain minimum 3 replicas
- Scale up to maximum 10 replicas

## Troubleshooting

### Application won't start
```bash
# Check logs
kubectl logs <pod-name>

# Check pod events
kubectl describe pod <pod-name>
```

### Image not found in GCR
```bash
# Verify image exists
gcloud container images list --repository=gcr.io/${PROJECT_ID}

# Check image details
gcloud container images describe gcr.io/${PROJECT_ID}/hello-gke:latest
```

### Service not accessible
```bash
# Check service status
kubectl describe svc hello-gke

# Check ingress status
kubectl describe ingress hello-gke-ingress

# Check network policies
kubectl get networkpolicies
```

### Check application logs
```bash
# Real-time logs
kubectl logs -f deployment/hello-gke

# Logs from specific pod
kubectl logs <pod-name>

# Previous logs (if pod crashed)
kubectl logs <pod-name> --previous
```

## Performance Tuning

The application includes thread pool configuration:
- **Max threads**: 200
- **Min spare threads**: 10

These can be adjusted in `application.properties` as needed.

## Production Considerations

1. **Image Registry**: Use a dedicated GCR registry with appropriate IAM policies
2. **Secrets Management**: Use Kubernetes Secrets for sensitive data
3. **Network Policy**: Implement NetworkPolicy for pod-to-pod communication
4. **RBAC**: Configure Role-Based Access Control for service accounts
5. **Monitoring**: Set up Prometheus and Grafana for metrics collection
6. **Logging**: Integrate with Cloud Logging for centralized log aggregation
7. **Backup**: Regularly backup your GKE cluster configuration
8. **Security**: Use Binary Authorization and Pod Security Policies

## Development

### Running Tests
```bash
gradle test
```

### Building without tests
```bash
gradle build -x test
```

### Running with different profiles
```bash
gradle bootRun --args='--spring.profiles.active=dev'
```

## License

MIT License

## Support

For issues or questions, please check:
- Application logs: `kubectl logs`
- GKE cluster status: `gcloud container clusters describe <cluster-name>`
- GCR image status: `gcloud container images list`
