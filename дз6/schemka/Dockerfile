# Этап сборки
FROM eclipse-temurin:24-jdk-alpine AS build

WORKDIR /app

COPY build.gradle .
COPY settings.gradle .
COPY gradlew .
COPY gradle gradle
COPY src src

RUN chmod +x gradlew
RUN ./gradlew build -x test

# Этап выполнения
FROM eclipse-temurin:24-jre-alpine

WORKDIR /app

COPY --from=build /app/build/libs/schemka-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8888

ENV SPRING_PROFILES_ACTIVE=docker

ENTRYPOINT ["java", "-jar", "app.jar"]
