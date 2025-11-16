# =====================================================
# Dockerfile - Todo Service (Java Spring Boot)
# =====================================================
# See on lihtne Dockerfile, mis eeldab, et JAR fail
# on juba builditud (./gradlew bootJar)
#
# Build:
#   docker build -t todo-service:1.0 .
#
# Run:
#   docker run -p 8081:8081 \
#     -e DB_HOST=postgres \
#     -e JWT_SECRET=your-secret \
#     todo-service:1.0
# =====================================================

# Base image: Eclipse Temurin JRE (OpenJDK alternative)
FROM eclipse-temurin:17-jre-alpine

# Metadata
LABEL maintainer="DevOps Training <devops@hostinger.com>"
LABEL description="Todo Service - Java Spring Boot Application"
LABEL version="1.0.0"

# Working directory
WORKDIR /app

# Copy JAR file from build/libs
COPY build/libs/todo-service.jar app.jar

# Create non-root user for security
RUN addgroup -S spring && adduser -S spring -G spring && \
    chown -R spring:spring /app

# Switch to non-root user
USER spring:spring

# Expose port
EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/health || exit 1

# JVM options for containerized environment
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# Run application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
