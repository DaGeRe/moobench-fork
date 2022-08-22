#FROM openjdk:13-jdk-alpine
FROM openjdk:17-jdk-alpine3.14 

RUN echo "jenkins:x:2030:100:guest:/home/jenkins:/sbin/nologin" >> /etc/passwd && \
    mkdir /home/jenkins && chmod 777 /home/jenkins && \ 
    apk update && \
    apk add git openssh zip R bash curl python3 py3-pip

