FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Kopeeri JAR fail
COPY build/libs/todo-service.jar app.jar

# Avalda port
EXPOSE 8081

# Käivita rakendus
CMD ["java", "-jar", "app.jar"]
