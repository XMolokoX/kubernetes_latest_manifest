pipeline {
    agent { label 'master' }
    options {
        buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '5', daysToKeepStr: '10'))
    }
    environment {
        COMMIT_DATE = sh(
            script: "echo \$(date +'%Y%m%d')",
            returnStdout: true
        )
        gitUrl = "https://github.com/minhquan010710/Lab1.git"
        branch = "master"
        credentialsId = "minhquan010710"
        service = "lab1"
        be_image = "be:${BUILD_NUMBER}-${COMMIT_DATE}"

        fe_image = "fe:${BUILD_NUMBER}-${COMMIT_DATE}"
        tag = "${BUILD_NUMBER}-${COMMIT_DATE}"
        CREDENTIAL_ID = ""
        ARTIFACT_REPOSITORY = "minhquan0107"
        DEPLOYBE_IMAGE = "${ARTIFACT_REPOSITORY}/${be_image}"
        DEPLOYFE_IMAGE = "${ARTIFACT_REPOSITORY}/${fe_image}"
        DOCKERHUB_CREDENTIALS=credentials('docker_id')
    }
    stages {
        stage('Clone Code') {
            steps {
                script {
                    properties([pipelineTriggers([pollSCM('* * * * *')])])
                }
                //checkout([$class: 'GitSCM', branches: [[name: "*/$branch"]], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'CloneOption', depth: 0, noTags: false, reference: '', shallow: false, timeout: 30], [$class: 'RelativeTargetDirectory', relativeTargetDir: "$service"]], userRemoteConfigs: [[credentialsId: "$credentialsId", url: "$gitUrl"]]])
                git branch: 'master', credentialsId: 'minhquan010710', url: 'https://github.com/minhquan010710/Lab1.git'
            }
        }
        stage('Build Application') {
            steps {
                script {
					if (isUnix()) {
                        sh '''
                            echo "Build Backend"
                            cd ${WORKSPACE}/be && docker build -t ${be_image} .
                            echo "Build Frontend"
                            cd ${WORKSPACE}/fe && docker build -t ${fe_image} .
						'''
					} else {
                        bat '''
                            echo "Updating"
                        '''
					}
                }
            }
        }
        stage('Push image to registry') {
            steps {
                script {
					if (isUnix()) {
						sh '''
                           echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                           docker image tag ${be_image} ${DEPLOYBE_IMAGE}
                           docker push ${DEPLOYBE_IMAGE}
                           docker image tag ${fe_image} ${DEPLOYFE_IMAGE}
                           docker push ${DEPLOYFE_IMAGE}
						'''
					} else {
                        bat '''
                          echo "Updating"

                        '''
					}
                }
            }
        }
        stage('Deployment') {
            agent { label 'app' }
            steps {
                script {
					if (isUnix()) {
						sh '''
                           cd /home/app/
                           sed -i '/tag/d' ./lab1/values.yaml
                           echo "tag: "${tag}"" >> ./lab1/values.yaml
                           helm upgrade lab1 ./lab1/
						'''
					} else {
                        bat '''
                           echo "Updating"
                        '''
					}
                }
            }
        }
    }
    post {
       always {
            cleanWs()    
       }
    }      
}