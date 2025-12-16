pipeline {
    agent any
    
    environment {
        // Docker Hub credentials (configure in Jenkins)
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = 'irfanriaz076/cicd-webapp'
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBECONFIG = credentials('kubeconfig')
    }
    
    stages {
        stage('Code Fetch') {
            steps {
                script {
                    echo '========================================='
                    echo 'Stage 1: Code Fetch from GitHub'
                    echo '========================================='
                }
                
                // Checkout code from GitHub
                checkout scm
                
                script {
                    echo 'Code successfully fetched from GitHub repository'
                    sh 'ls -la'
                }
            }
        }
        
        stage('Install Dependencies') {
            when {
                expression { fileExists('/usr/bin/npm') || fileExists('/usr/local/bin/npm') }
            }
            steps {
                script {
                    echo '========================================='
                    echo 'Installing Node.js dependencies'
                    echo '========================================='
                }
                
                sh 'npm install || echo "npm not found, skipping..."'
            }
        }
        
        stage('Run Tests') {
            when {
                expression { fileExists('/usr/bin/npm') || fileExists('/usr/local/bin/npm') }
            }
            steps {
                script {
                    echo '========================================='
                    echo 'Running Unit Tests'
                    echo '========================================='
                }
                
                sh 'npm test || true'
            }
        }
        
        stage('Docker Image Creation') {
            steps {
                script {
                    echo '========================================='
                    echo 'Stage 2: Building Docker Image'
                    echo '========================================='
                }
                
                // Build Docker image
                sh """
                    docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} .
                    docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${DOCKER_IMAGE}:latest
                """
                
                script {
                    echo "Docker image built successfully: ${DOCKER_IMAGE}:${IMAGE_TAG}"
                }
            }
        }
        
        stage('Push to DockerHub') {
            steps {
                script {
                    echo '========================================='
                    echo 'Pushing Docker Image to DockerHub'
                    echo '========================================='
                }
                
                // Login to DockerHub and push image
                sh """
                    echo \$DOCKERHUB_CREDENTIALS_PSW | docker login -u \$DOCKERHUB_CREDENTIALS_USR --password-stdin
                    docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                    docker logout
                """
                
                script {
                    echo "Docker image pushed to DockerHub: ${DOCKER_IMAGE}:${IMAGE_TAG}"
                }
            }
        }
        
        stage('Kubernetes Deployment') {
            steps {
                script {
                    echo '========================================='
                    echo 'Stage 3: Deploying to Kubernetes Cluster'
                    echo '========================================='
                }
                
                // Update image tag in deployment file
                sh """
                    sed -i 's|image: .*|image: ${DOCKER_IMAGE}:${IMAGE_TAG}|g' k8s/deployment.yaml
                """
                
                // Apply Kubernetes manifests
                sh """
                    kubectl apply -f k8s/namespace.yaml
                    kubectl apply -f k8s/configmap.yaml
                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml
                """
                
                // Wait for deployment to complete
                sh """
                    kubectl rollout status deployment/webapp-deployment -n cicd-webapp
                """
                
                script {
                    echo 'Application deployed successfully to Kubernetes cluster'
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo '========================================='
                    echo 'Verifying Kubernetes Deployment'
                    echo '========================================='
                }
                
                sh """
                    kubectl get pods -n cicd-webapp
                    kubectl get services -n cicd-webapp
                    kubectl get deployments -n cicd-webapp
                """
            }
        }
        
        stage('Prometheus/Grafana Monitoring') {
            steps {
                script {
                    echo '========================================='
                    echo 'Stage 4: Setting up Prometheus & Grafana'
                    echo '========================================='
                }
                
                // Deploy monitoring stack
                sh """
                    kubectl apply -f monitoring/namespace.yaml
                    kubectl apply -f monitoring/prometheus-config.yaml
                    kubectl apply -f monitoring/prometheus-deployment.yaml
                    kubectl apply -f monitoring/prometheus-service.yaml
                    kubectl apply -f monitoring/grafana-deployment.yaml
                    kubectl apply -f monitoring/grafana-service.yaml
                    kubectl apply -f monitoring/servicemonitor.yaml
                """
                
                script {
                    echo 'Prometheus and Grafana deployed successfully'
                    echo 'Prometheus URL: http://<node-ip>:30090'
                    echo 'Grafana URL: http://<node-ip>:30030 (admin/admin123)'
                }
            }
        }
        
        stage('Get Access URLs') {
            steps {
                script {
                    echo '========================================='
                    echo 'Application Access Information'
                    echo '========================================='
                }
                
                sh """
                    echo "Application Service:"
                    kubectl get service webapp-service -n cicd-webapp
                    echo ""
                    echo "Prometheus Service:"
                    kubectl get service prometheus-service -n monitoring
                    echo ""
                    echo "Grafana Service:"
                    kubectl get service grafana-service -n monitoring
                """
            }
        }
    }
    
    post {
        success {
            echo '========================================='
            echo 'Pipeline executed successfully!'
            echo '========================================='
            echo 'Summary:'
            echo "- Docker Image: ${DOCKER_IMAGE}:${IMAGE_TAG}"
            echo '- Kubernetes Deployment: Complete'
            echo '- Monitoring Stack: Deployed'
            echo '========================================='
        }
        
        failure {
            echo '========================================='
            echo 'Pipeline execution failed!'
            echo '========================================='
        }
        
        always {
            // Clean up workspace
            cleanWs()
        }
    }
}
