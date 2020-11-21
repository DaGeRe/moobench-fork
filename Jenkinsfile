#!/usr/bin/env groovy

pipeline {

  options {
      timeout(time: 4, unit: 'HOURS') 
  }

  agent { label "build-node8" }

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
          sh './gradlew build'
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
