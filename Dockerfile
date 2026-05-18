# Build stage
FROM eclipse-temurin:17-jdk-jammy as builder

WORKDIR /app
COPY . .

RUN apt-get update && apt-get install -y gradle && rm -rf /var/lib/apt/lists/*
RUN gradle build -x test

# Runtime stage
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Copy the JAR file from the builder stage
COPY --from=builder /app/build/libs/hello-gke.jar .

# Copy application properties
COPY --from=builder /app/src/main/resources/application.properties .

# Create non-root user for security
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD java -cp hello-gke.jar com.example.healthcheck.HealthCheck || exit 1

# Expose port
EXPOSE 8080

# Start application
ENTRYPOINT ["java", "-jar", "hello-gke.jar"]
