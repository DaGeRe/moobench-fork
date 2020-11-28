FROM openjdk:13-jdk-alpine

RUN echo "jenkins:x:2030:100:guest:/dev/null:/sbin/nologin" >> /etc/passwd && \
    apk update && \
    apk add git openssh zip R bash

