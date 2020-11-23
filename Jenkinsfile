#!/usr/bin/env groovy

pipeline {

  agent { label "build-node8" }

  environment {
    KEYSTORE = credentials('kieker-irl-key')
    UPDATE_SITE_URL = "sftp://repo@repo.se.internal/var/www/html/moobench"

    DOCKER_ARGS = ''
  }

  options {
    buildDiscarder logRotator(artifactNumToKeepStr: '10')
    timeout(time: 4, unit: 'HOURS') 
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
          sh 'frameworks/Kieker/scripts/run-benchmark.sh ${KEYSTORE} ${UPDATE_SITE_URL}'
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
