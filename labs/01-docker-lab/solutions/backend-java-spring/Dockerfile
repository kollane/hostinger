# Lihtne Dockerfile Todo Teenuse (Service) jaoks (Harjutus 1)
# Eeldab, et JAR fail on juba ehitatud (built): ./gradlew bootJar

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Kopeeri JAR fail
COPY build/libs/todo-service.jar app.jar

# Avalda port
EXPOSE 8081

# Käivita rakendus
CMD ["java", "-jar", "app.jar"]
