GKERegion='us-central1-a'

void CreateCluster(String CLUSTER_PREFIX) {
    withCredentials([string(credentialsId: 'GCP_PROJECT_ID', variable: 'GCP_PROJECT'), file(credentialsId: 'gcloud-key-file', variable: 'CLIENT_SECRET_FILE')]) {
        sh """
            export KUBECONFIG=/tmp/$CLUSTER_NAME-${CLUSTER_PREFIX}
            source $HOME/google-cloud-sdk/path.bash.inc
            gcloud auth activate-service-account --key-file $CLIENT_SECRET_FILE
            gcloud config set project $GCP_PROJECT
            gcloud container clusters create --zone=${GKERegion} $CLUSTER_NAME-${CLUSTER_PREFIX} --cluster-version=1.18 --machine-type=n1-standard-4 --preemptible --num-nodes=3 --network=jenkins-vpc --subnetwork=jenkins-${CLUSTER_PREFIX} --no-enable-autoupgrade
            kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user jenkins@"$GCP_PROJECT".iam.gserviceaccount.com
        """
   }
}
void ShutdownCluster(String CLUSTER_PREFIX) {
    withCredentials([string(credentialsId: 'GCP_PROJECT_ID', variable: 'GCP_PROJECT'), file(credentialsId: 'gcloud-key-file', variable: 'CLIENT_SECRET_FILE')]) {
        sh """
            export KUBECONFIG=/tmp/$CLUSTER_NAME-${CLUSTER_PREFIX}
            source $HOME/google-cloud-sdk/path.bash.inc
            gcloud auth activate-service-account --key-file $CLIENT_SECRET_FILE
            gcloud config set project $GCP_PROJECT
            gcloud container clusters delete --zone $GKERegion $CLUSTER_NAME-${CLUSTER_PREFIX}
        """
   }
}
void pushArtifactFile(String FILE_NAME) {
    echo "Push $FILE_NAME file to S3!"

    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'AMI/OVF', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
        sh """
            touch ${FILE_NAME}
            S3_PATH=s3://percona-jenkins-artifactory/\$JOB_NAME/\$(git rev-parse --short HEAD)
            aws s3 ls \$S3_PATH/${FILE_NAME} || :
            aws s3 cp --quiet ${FILE_NAME} \$S3_PATH/${FILE_NAME} || :
        """
    }
}

void popArtifactFile(String FILE_NAME) {
    echo "Try to get $FILE_NAME file from S3!"

    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'AMI/OVF', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
        sh """
            S3_PATH=s3://percona-jenkins-artifactory/\$JOB_NAME/\$(git rev-parse --short HEAD)
            aws s3 cp --quiet \$S3_PATH/${FILE_NAME} ${FILE_NAME} || :
        """
    }
}

TestsReport = '| Test name  | Status |\r\n| ------------- | ------------- |'
testsReportMap  = [:]
testsResultsMap = [:]

void makeReport() {
    for ( test in testsReportMap ) {
        TestsReport = TestsReport + "\r\n| ${test.key} | ${test.value} |"
    }
}

void setTestsresults() {
    testsResultsMap.each { file ->
        pushArtifactFile("${file.key}")
    }
}

void runTest(String TEST_NAME, String CLUSTER_PREFIX) {
    def retryCount = 0
    waitUntil {
        try {
            echo "The $TEST_NAME test was started!"
            testsReportMap[TEST_NAME] = 'failed'
            popArtifactFile("${env.GIT_BRANCH}-${env.GIT_SHORT_COMMIT}-$TEST_NAME")

            timeout(time: 90, unit: 'MINUTES') {
                sh """
                    if [ -f "${env.GIT_BRANCH}-${env.GIT_SHORT_COMMIT}-$TEST_NAME" ]; then
                        echo Skip $TEST_NAME test
                    else
                        export KUBECONFIG=/tmp/$CLUSTER_NAME-${CLUSTER_PREFIX}
                        source $HOME/google-cloud-sdk/path.bash.inc
                        ./e2e-tests/$TEST_NAME/run
                    fi
                """
            }
            testsReportMap[TEST_NAME] = 'passed'
            testsResultsMap["${env.GIT_BRANCH}-${env.GIT_SHORT_COMMIT}-$TEST_NAME"] = 'passed'
            return true
        }
        catch (exc) {
            if (retryCount >= 2) {
                currentBuild.result = 'FAILURE'
                return true
            }
            retryCount++
            return false
        }
    }

    echo "The $TEST_NAME test was finished!"
}

void installRpms() {
    sh '''
        sudo yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm || true
        sudo percona-release enable-only tools
        sudo yum install -y percona-xtrabackup-80 jq | true
    '''
}

def skipBranchBulds = true
if ( env.CHANGE_URL ) {
    skipBranchBulds = false
}

pipeline {
    environment {
        CLOUDSDK_CORE_DISABLE_PROMPTS = 1
        CLEAN_NAMESPACE = 1
        GIT_SHORT_COMMIT = sh(script: 'git describe --always --dirty', , returnStdout: true).trim()
        VERSION = "${env.GIT_BRANCH}-${env.GIT_SHORT_COMMIT}"
        CLUSTER_NAME = sh(script: "echo jenkins-psmdb-${GIT_SHORT_COMMIT} | tr '[:upper:]' '[:lower:]'", , returnStdout: true).trim()
        AUTHOR_NAME  = sh(script: "echo ${CHANGE_AUTHOR_EMAIL} | awk -F'@' '{print \$1}'", , returnStdout: true).trim()
    }
    agent {
        label 'docker'
    }
    stages {
        stage('Prepare') {
            when {
                expression {
                    !skipBranchBulds
                }
            }
            steps {
                stash includes: 'vendor/**', name: 'vendorFILES'
                installRpms()
                script {
                    if ( AUTHOR_NAME == 'null' )  {
                        AUTHOR_NAME = sh(script: "git show -s --pretty=%ae | awk -F'@' '{print \$1}'", , returnStdout: true).trim()
                    }
                    for (comment in pullRequest.comments) {
                        println("Author: ${comment.user}, Comment: ${comment.body}")
                        if (comment.user.equals('JNKPercona')) {
                            println("delete comment")
                            comment.delete()
                        }
                    }
                }
                sh '''
                    if [ ! -d $HOME/google-cloud-sdk/bin ]; then
                        rm -rf $HOME/google-cloud-sdk
                        curl https://sdk.cloud.google.com | bash
                    fi

                    source $HOME/google-cloud-sdk/path.bash.inc
                    gcloud components install alpha
                    gcloud components install kubectl

                    curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
                    curl -s -L https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz \
                        | sudo tar -C /usr/local/bin --strip-components 1 --wildcards -zxvpf - '*/oc'

                    curl -s -L https://github.com/mitchellh/golicense/releases/latest/download/golicense_0.2.0_linux_x86_64.tar.gz \
                        | sudo tar -C /usr/local/bin --wildcards -zxvpf -

                    sudo sh -c "curl -s -L https://github.com/mikefarah/yq/releases/download/3.3.2/yq_linux_amd64 > /usr/local/bin/yq"
                    sudo chmod +x /usr/local/bin/yq
                '''
                withCredentials([file(credentialsId: 'cloud-secret-file', variable: 'CLOUD_SECRET_FILE')]) {
                    sh '''
                        cp $CLOUD_SECRET_FILE ./e2e-tests/conf/cloud-secret.yml
                    '''
                }
            }
        }
        stage('Build docker image') {
            when {
                expression {
                    !skipBranchBulds
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'hub.docker.com', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh '''
                        DOCKER_TAG=perconalab/percona-postgresql-operator:$VERSION
                        docker_tag_file='./results/docker/TAG'
                        mkdir -p $(dirname ${docker_tag_file})
                        echo ${DOCKER_TAG} > "${docker_tag_file}"
                            sg docker -c "
                                docker login -u '${USER}' -p '${PASS}'
                                export RELEASE=0
                                export IMAGE=\$DOCKER_TAG
                                ./e2e-tests/build
                                docker logout
                            "
                        sudo rm -rf ./build
                    '''
                }
                stash includes: 'results/docker/TAG', name: 'IMAGE'
                archiveArtifacts 'results/docker/TAG'
            }
        }
    }
    post {
        always {
            script {
                setTestsresults()
                if (currentBuild.result != null && currentBuild.result != 'SUCCESS') {
                    slackSend channel: '#cloud-dev-ci', color: '#FF0000', message: "[${JOB_NAME}]: build ${currentBuild.result}, ${BUILD_URL} owner: @${AUTHOR_NAME}"
                }
                if (env.CHANGE_URL) {
                    for (comment in pullRequest.comments) {
                        println("Author: ${comment.user}, Comment: ${comment.body}")
                        if (comment.user.equals('JNKPercona')) {
                            println("delete comment")
                            comment.delete()
                        }
                    }
                    makeReport()
                    unstash 'IMAGE'
                    def IMAGE = sh(returnStdout: true, script: "cat results/docker/TAG").trim()
                    TestsReport = TestsReport + "\r\n\r\ncommit: ${env.CHANGE_URL}/commits/${env.GIT_COMMIT}\r\nimage: `${IMAGE}`\r\n"
                    pullRequest.comment(TestsReport)

                    withCredentials([string(credentialsId: 'GCP_PROJECT_ID', variable: 'GCP_PROJECT'), file(credentialsId: 'gcloud-key-file', variable: 'CLIENT_SECRET_FILE')]) {
                        sh '''
                            source $HOME/google-cloud-sdk/path.bash.inc
                            gcloud auth activate-service-account --key-file $CLIENT_SECRET_FILE
                            gcloud config set project $GCP_PROJECT
                            gcloud container clusters delete --zone $GKERegion $CLUSTER_NAME-basic $CLUSTER_NAME-scaling $CLUSTER_NAME-selfhealing $CLUSTER_NAME-backups || true
                            sudo docker rmi -f \$(sudo docker images -q) || true

                            sudo rm -rf $HOME/google-cloud-sdk
                        '''
                    }
                }
            }
            sh '''
                sudo docker rmi -f \$(sudo docker images -q) || true
                sudo rm -rf ./*
                sudo rm -rf $HOME/google-cloud-sdk
            '''
            deleteDir()
        }
    }
}