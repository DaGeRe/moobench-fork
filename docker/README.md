Build Docker Image
==================

docker build -t moobench .
docker tag moobench:latest prefec2/moobench:latest
docker login
docker push prefec2/moobench:latest

In case information or acces to the prefec2 account gets lost, you
need to create a new one. And modify the naming accordingly.
This must also be done in the Jenkinsfile.

