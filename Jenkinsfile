#!/usr/bin/env groovy

pipeline {

  agent { 
     docker {
          image 'prefec2/moobench:latest'
          alwaysPull true
          args env.DOCKER_ARGS
     }
  }

  environment {
    KEYSTORE = credentials('kieker-irl-key')
    UPDATE_SITE_URL = "sftp://repo@repo.se.internal/var/www/html/moobench"
    BASE_DIR = "frameworks/Kieker/scripts"

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
          sh '${BASE_DIR}/run-benchmark.sh ${KEYSTORE} ${UPDATE_SITE_URL}'
       }
    }
    
    stage('Upload') {
       agent { label 'build-node4' }
       sshagent(credentials: ['kieker-irl-key']) {
          sh 'sftp -i ${KEYSTORE} ${UPDATE_SITE_URL}'
          sh '${BASE_DIR}/compile-results/bin/compile-results "${BASE_DIR}/results-kieker/results-text.csv" "${BASE_DIR}/all-results.json"'
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
