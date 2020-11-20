#!/usr/bin/env groovy

pipeline {

  agent {
    docker {
      image 'kieker/kieker-build:openjdk8'
      alwaysPull true
      args env.DOCKER_ARGS
    }
  }

  environment {
    DOCKER_ARGS = ''
  }

  options {
    buildDiscarder logRotator(artifactNumToKeepStr: '10')
    timeout(time: 150, unit: 'MINUTES')
    retry(1)
    parallelsAlwaysFailFast()
  }

  triggers {
    cron(env.BRANCH_NAME == 'master' ? '@daily' : '')
  }

  stages {
    stage('Initial Cleanup') {
       steps {
          sh './gradlew clean'
       }
    }

    stage('Compile') {
       steps {
          sh './gradlew compileJava'
       }
    }

    stage('Run Benchmark') {
       steps {
          sh 'frameworks/Kieker/scripts/run-benchmark.sh'
       }
       post {
         cleanup {
           deleteDir()
           cleanWs()
         }
       }
    }
  }
}
