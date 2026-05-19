pipeline {
    agent any

    environment {
        // === CONFIGURE THESE ===
        APP_NAME        = 'my-app'
        IMAGE_REPO      = 'your-dockerhub-username/my-app'   // or registry.example.com/my-app
        REGISTRY        = 'https://index.docker.io/v1/'       // Docker Hub; change for private registry
        REGISTRY_CREDS  = 'dockerhub-credentials'             // Jenkins credential ID
        CONTAINER_PORT  = '8080'
        HOST_PORT       = '80'
        // ======================

        IMAGE_TAG       = "${IMAGE_REPO}:${BUILD_NUMBER}"
        IMAGE_LATEST    = "${IMAGE_REPO}:latest"
    }

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        // ──────────────────────────────────────────────
        // 1. CHECKOUT
        // ──────────────────────────────────────────────
        stage('Checkout') {
            steps {
                echo '📥 Checking out source code...'
                checkout scm
            }
        }

        // ──────────────────────────────────────────────
        // 2. BUILD
        // ──────────────────────────────────────────────
        stage('Build') {
            steps {
                echo '🔨 Building application...'
                // ── Adjust the command below to match your stack ──
                // Node.js
                sh 'npm ci'
                sh 'npm run build --if-present'

                // Java/Maven  → uncomment:
                // sh 'mvn clean package -DskipTests'

                // Python      → uncomment:
                // sh 'pip install -r requirements.txt'

                // Go          → uncomment:
                // sh 'go build ./...'
            }
        }

        // ──────────────────────────────────────────────
        // 3. TEST
        // ──────────────────────────────────────────────
        stage('Test') {
            steps {
                echo '🧪 Running tests...'
                // ── Adjust to your test runner ──
                sh 'npm test -- --watchAll=false'

                // Java/Maven  → uncomment:
                // sh 'mvn test'

                // Python      → uncomment:
                // sh 'pytest --junitxml=test-results.xml'

                // Go          → uncomment:
                // sh 'go test ./...'
            }
            post {
                always {
                    // Publish JUnit results if they exist
                    script {
                        if (fileExists('test-results.xml')) {
                            junit 'test-results.xml'
                        }
                        if (fileExists('coverage/lcov.info')) {
                            // optional: publish coverage report
                            publishHTML(target: [
                                reportDir  : 'coverage/lcov-report',
                                reportFiles: 'index.html',
                                reportName : 'Coverage Report'
                            ])
                        }
                    }
                }
            }
        }

        // ──────────────────────────────────────────────
        // 4. DOCKER BUILD & PUSH
        // ──────────────────────────────────────────────
        stage('Docker Build & Push') {
            steps {
                echo "🐳 Building Docker image: ${IMAGE_TAG}"
                script {
                    def image = docker.build("${IMAGE_TAG}")

                    docker.withRegistry("${REGISTRY}", "${REGISTRY_CREDS}") {
                        echo "📤 Pushing ${IMAGE_TAG}..."
                        image.push()

                        if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') {
                            echo "📤 Pushing ${IMAGE_LATEST}..."
                            image.push('latest')
                        }
                    }
                }
            }
        }

        // ──────────────────────────────────────────────
        // 5. DEPLOY  (runs only on main / master)
        // ──────────────────────────────────────────────
        stage('Deploy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                echo "🚀 Deploying container ${IMAGE_TAG}..."
                script {
                    // Stop & remove any existing container, then run the new one.
                    // Replace with kubectl / docker-compose / Ansible as needed.
                    sh """
                        docker stop ${APP_NAME} || true
                        docker rm   ${APP_NAME} || true

                        docker run -d \\
                            --name    ${APP_NAME} \\
                            --restart unless-stopped \\
                            -p ${HOST_PORT}:${CONTAINER_PORT} \\
                            ${IMAGE_TAG}
                    """

                    // ── Kubernetes alternative → uncomment: ──
                    // sh "kubectl set image deployment/${APP_NAME} ${APP_NAME}=${IMAGE_TAG} --record"
                    // sh "kubectl rollout status deployment/${APP_NAME}"

                    // ── Docker Compose alternative → uncomment: ──
                    // sh "IMAGE_TAG=${IMAGE_TAG} docker compose up -d"
                }
            }
        }

    } // end stages

    // ──────────────────────────────────────────────────
    // POST ACTIONS
    // ──────────────────────────────────────────────────
    post {
        success {
            echo "✅ Pipeline succeeded — ${IMAGE_TAG} is live."
        }
        failure {
            echo "❌ Pipeline failed. Check logs above."
            // Uncomment to send email:
            // mail to: 'team@example.com',
            //      subject: "FAILED: ${JOB_NAME} #${BUILD_NUMBER}",
            //      body:    "See ${BUILD_URL}"
        }
        always {
            echo '🧹 Cleaning workspace...'
            cleanWs()
        }
    }
}
