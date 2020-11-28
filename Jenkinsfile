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
          sshagent(credentials: ['kieker-irl-key']) {
              sh('''
                    #!/usr/bin/env bash
                    set +x
                    ## fetch old results
                    echo "Fetch old results file."
                    sftp -oStrictHostKeyChecking=no -i "${KEYSTORE}" "${UPDATE_SITE_URL}/all-results.json"
                    echo "Got file"
                    cat all-results.json

                    ## compile results into json
                    echo "Compile results"
                    frameworks/Kieker/scripts/compile-results/bin/compile-results "${BASE_DIR}/results-kieker/results-text.csv" "${BASE_DIR}/all-results.json"
                    echo "Done"

                    ## push results
                    echo "Push results back"
                    sftp -oStrictHostKeyChecking=no -i "${KEYSTORE}" "${UPDATE_SITE_URL}/all-results.json" <<< $'put all-results.json'
                    echo "Done"
                 ''')
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
