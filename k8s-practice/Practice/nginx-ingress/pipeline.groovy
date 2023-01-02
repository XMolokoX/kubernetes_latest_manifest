pipeline {
    agent { label 'linux' }
    options {
        buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '5', daysToKeepStr: '10'))
    }
    environment {
        COMMIT_DATE = sh(
            script: "echo \$(date +'%Y%m%d')",
            returnStdout: true
        )
        image = "fe:${BUILD_NUMBER}-${COMMIT_DATE}"
        tag = "${BUILD_NUMBER}-${COMMIT_DATE}"
        ARTIFACT_REPOSITORY = "lab3acr.azurecr.io"
        DEPLOYBE_IMAGE = "${ARTIFACT_REPOSITORY}/${image}"
        DOCKERHUB_CREDENTIALS=credentials('docker_id')
        chartname = "fe"
    }
    stages {
        stage('Clone Code') {
            steps {
                git branch: 'main', credentialsId: 'git', url: 'http://13.93.127.138/root/module.git'
            }
        }
        stage('Deploy phpadmin') {
            steps {
                script {
					if (isUnix()) {
						sh '''
                           kubectl create secret docker-registry acr-secret --docker-server=lab3acr.azurecr.io --docker-username=lab3acr --docker-password=T63iZiox2k7oLPDGda/ZiZ7gSifMw5T7 --docker-email=ignorethis@email.com
                           cd ${WORKSPACE} && kubectl apply -f deployment-phppgadmin.yml
						'''
					} else {
                        bat '''
                          echo "Updating"

                        '''
					}
                }
            }
        }
		stage('Install Nginx Ingress') {
            steps {
                script {
					if (isUnix()) {
						sh '''
                            cd ${WORKSPACE}
                            helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
                            helm install nginx-ingress ingress-nginx/ingress-nginx -f controller.yml
						'''
					} else {
                        bat '''
                          echo "Updating"

                        '''
					}
                }
            }
        }
        stage('Install New Relic') {
            steps {
                script {
					if (isUnix()) {
						sh '''
                            cd ${WORKSPACE}
                            helm repo add newrelic https://helm-charts.newrelic.com
                            helm upgrade --install newrelic-bundle newrelic/nri-bundle -f new-relic.yml
						'''
					} else {
                        bat '''
                          echo "Updating"

                        '''
					}
                }
            }
        }
        stage('Deploy custom ingress') {
            steps {
                script {
					if (isUnix()) {
                        sh '''
                            cd ${WORKSPACE}/cert
                            kubectl create secret tls backend-tls --key="backend.key" --cert="backend.crt"
                            kubectl create secret tls php-tls --key="php.key" --cert="php.crt"
                            kubectl create secret tls frontend-tls --key="frontend.key" --cert="frontend.crt"
                            cd ${WORKSPACE} && kubectl apply -f ingress.yml
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
}