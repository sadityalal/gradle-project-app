# Multi-staged Dockerfile to Build application to get only .jar file which matters to run app

# Build inside Gradle image
FROM gradle:9-jdk17 AS builder
WORKDIR /app
COPY gradle-app ./
RUN ./gradlew clean fatJar --no-daemon

# Stage 2: Lightweight runtime
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=builder /app/build/libs/project-app-*-all.jar /app/app.jar

RUN useradd -u 10001 appuser
USER 10001

ENTRYPOINT ["java", "-jar", "/app/app.jar"]

