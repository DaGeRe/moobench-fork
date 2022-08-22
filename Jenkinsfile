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
    // upstream(upstreamProjects: 'kieker-dev/master', threshold: hudson.model.Result.SUCCESS)
  }

  environment {
    KEYSTORE = credentials('kieker-irl-key')
    UPDATE_SITE_URL = "sftp://repo@repo.se.internal/moobench"
    DOCKER_ARGS = ''
    BATCH_MODE = "yes"
  }

  options {
    buildDiscarder logRotator(artifactNumToKeepStr: '10')
    timeout(time: 20, unit: 'HOURS') 
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
          sh './setup.sh'
       }
    }

    stage('Run Benchmark') {
       steps {
          sh './frameworks/Kieker/python/benchmark.sh'
          sh './frameworks/Kieker/java/benchmark.sh'
 //         sh './frameworks/OpenTelemetry/benchmark.sh'
 //         sh './frameworks/inspectIT/benchmark.sh'

          sh 'cp frameworks/Kieker/python/results.yaml kieker-python-results.yaml'
          sh 'cp frameworks/Kieker/java/results.yaml kieker-java-results.yaml'
 //         sh 'cp frameworks/OpenTelemetry/results.yaml open-telementry-results.yaml'
 //         sh 'cp frameworks/inpsectIT/results.yaml inspect-it-results.yaml'

          stash includes: '*-results.yaml', name: 'yaml'
       }
    }
    
    stage('Upload') {
       steps {
          sshagent(credentials: ['kieker-irl-key']) {
             unstash 'yaml'
             sh '''
                 echo "put kieker-python-results.yaml" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
                 echo "put kieker-java-results.yaml" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
                 echo "put open-telementry-results.yaml" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
                 echo "put insepct-it-results.yaml" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
//	         sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}/all-results.json
//                 compile-results/bin/compile-results results-Kieker/results-text.csv all-results.json
//                 echo "put all-results.json" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
//                 echo "put partial-results.json" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
//                 echo "put relative-results.json" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
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
