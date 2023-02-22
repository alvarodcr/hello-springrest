FROM gradle:jdk11-alpine AS build
WORKDIR /opt/springrest
COPY . .
RUN gradle build

FROM amazoncorretto:11-alpine
WORKDIR /opt/springest/
COPY --from=build /opt/springrest/build/libs/rest-service-0.0.1-SNAPSHOT.jar .
EXPOSE 8080
CMD ["java", "-jar", "rest-service-0.0.1-SNAPSHOT.jar"]
