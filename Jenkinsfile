#!/usr/bin/env groovy

pipeline {

  agent { 
     docker {
          image 'prefec2/moobench:latest'
          alwaysPull true
          args env.DOCKER_ARGS
     }
  }

  triggers {
    cron('0 1 * * *')
    upstream(upstreamProjects: 'kieker-dev/master', threshold: hudson.model.Result.SUCCESS)
  }

  environment {
    KEYSTORE = credentials('kieker-irl-key')
    UPDATE_SITE_URL = "sftp://repo@repo.se.internal/moobench"
    BASE_DIR = "frameworks/Kieker"

    DOCKER_ARGS = ''
  }

  options {
    buildDiscarder logRotator(artifactNumToKeepStr: '10')
    timeout(time: 4, unit: 'HOURS') 
    retry(1)
    parallelsAlwaysFailFast()
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
       steps {
          sshagent(credentials: ['kieker-irl-key']) {
             sh '''
                 cd ${BASE_DIR}
	         sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}/all-results.json
                 compile-results/bin/compile-results results-kieker/results-text.csv all-results.json
                 echo "put all-results.json" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
                 echo "put partial-results.json" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
                 echo "put relative-results.json" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
                '''
          }
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
