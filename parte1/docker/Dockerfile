FROM gradle:4.2.1-jdk8-alpine as build

USER root

ADD app /home/gradle/app

RUN chown -R gradle /home/gradle/

USER gradle

WORKDIR /home/gradle/app/

RUN gradle build --no-daemon

FROM openjdk:8-jre-slim

EXPOSE 8080

RUN mkdir /app

COPY --from=build /home/gradle/app/build/libs/app.jar /app/app.jar

ENTRYPOINT ["java", "-jar","/app/app.jar"]