pipeline {
    agent any

    environment {
        APP_NAME       = 'my-app'
        IMAGE_REPO     = 'your-dockerhub-username/my-app'
        REGISTRY       = 'https://index.docker.io/v1/'
        REGISTRY_CREDS = 'dockerhub-credentials'
        CONTAINER_PORT = '8080'
        HOST_PORT      = '80'
        IMAGE_TAG      = "${IMAGE_REPO}:${BUILD_NUMBER}"
        IMAGE_LATEST   = "${IMAGE_REPO}:latest"
    }

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Building application...'
                sh 'npm ci'
                sh 'npm run build --if-present'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'npm test -- --watchAll=false'
            }
        }

        stage('Docker Build and Push') {
            steps {
                echo "Building Docker image: ${IMAGE_TAG}"
                script {
                    def image = docker.build("${IMAGE_TAG}")
                    docker.withRegistry("${REGISTRY}", "${REGISTRY_CREDS}") {
                        image.push()
                        if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') {
                            image.push('latest')
                        }
                    }
                }
            }
        }

        stage('Deploy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                echo "Deploying container ${IMAGE_TAG}..."
                sh """
                    docker stop ${APP_NAME} || true
                    docker rm   ${APP_NAME} || true
                    docker run -d \
                        --name    ${APP_NAME} \
                        --restart unless-stopped \
                        -p ${HOST_PORT}:${CONTAINER_PORT} \
                        ${IMAGE_TAG}
                """
            }
        }

    }

    post {
        success {
            echo "Pipeline succeeded - ${IMAGE_TAG} is live."
        }
        failure {
            echo "Pipeline failed. Check logs above."
        }
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
    }
}
