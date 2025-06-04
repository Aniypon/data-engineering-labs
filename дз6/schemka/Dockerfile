# Этап сборки
FROM openjdk:23-jdk-slim AS build

WORKDIR /app

COPY build.gradle .
COPY settings.gradle .
COPY gradlew .
COPY gradle gradle
COPY src src

RUN chmod +x gradlew
RUN ./gradlew build -x test

# Этап выполнения
FROM openjdk:23-jdk-slim

WORKDIR /app

COPY --from=build /app/build/libs/schemka-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8888

ENV SPRING_PROFILES_ACTIVE=docker

ENTRYPOINT ["java", "-jar", "app.jar"]
