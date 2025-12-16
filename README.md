# Jenkins CI/CD Pipeline Project

A comprehensive CI/CD pipeline implementation using Jenkins, Docker, Kubernetes, Prometheus, and Grafana for automated deployment and monitoring of a Node.js web application.

## 📋 Table of Contents
- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
- [Jenkins Configuration](#jenkins-configuration)
- [Pipeline Stages](#pipeline-stages)
- [Accessing the Application](#accessing-the-application)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## 🎯 Project Overview

This project implements a complete CI/CD pipeline that:
- Fetches code from GitHub
- Builds and tests a Node.js application
- Creates Docker images and pushes to DockerHub
- Deploys to Kubernetes cluster
- Sets up Prometheus and Grafana for monitoring

## 🏗️ Architecture

```
GitHub → Jenkins → Docker → DockerHub → Kubernetes → Prometheus/Grafana
```

**Components:**
- **Application**: Node.js + Express + MongoDB
- **CI/CD**: Jenkins (on AWS EC2)
- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **Monitoring**: Prometheus + Grafana

## 📦 Prerequisites

### AWS EC2 Instance Requirements
- **Instance Type**: t2.medium or larger (2 vCPU, 4GB RAM minimum)
- **OS**: Ubuntu 20.04 LTS or Amazon Linux 2
- **Storage**: 20GB minimum
- **Security Group Ports**:
  - 22 (SSH)
  - 8080 (Jenkins)
  - 80, 443 (HTTP/HTTPS)
  - 30000-32767 (Kubernetes NodePort range)

### Software Requirements
- Jenkins 2.400+
- Docker 20.10+
- Kubernetes cluster (minikube/kubeadm/EKS)
- kubectl CLI
- Git

## 📁 Project Structure

```
project/
├── app.js                      # Main application file
├── package.json                # Node.js dependencies
├── Dockerfile                  # Docker image configuration
├── .dockerignore              # Docker ignore file
├── docker-compose.yml         # Local development setup
├── Jenkinsfile                # Jenkins pipeline script
├── test/
│   └── app.test.js            # Unit tests
├── k8s/                       # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── mongodb-deployment.yaml
│   └── mongodb-service.yaml
├── monitoring/                # Monitoring configuration
│   ├── namespace.yaml
│   ├── prometheus-config.yaml
│   ├── prometheus-deployment.yaml
│   ├── prometheus-service.yaml
│   ├── grafana-deployment.yaml
│   ├── grafana-service.yaml
│   └── servicemonitor.yaml
└── README.md                  # This file
```

## 🚀 Setup Instructions

### Step 1: Launch AWS EC2 Instance

```bash
# Update the system
sudo apt update && sudo apt upgrade -y

# Install Java (required for Jenkins)
sudo apt install openjdk-11-jdk -y

# Verify Java installation
java -version
```

### Step 2: Install Jenkins

```bash
# Add Jenkins repository
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# Install Jenkins
sudo apt update
sudo apt install jenkins -y

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Access Jenkins at: `http://13.60.162.92:8080`

### Step 3: Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add Jenkins user to docker group
sudo usermod -aG docker jenkins
sudo usermod -aG docker $USER

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Restart Jenkins to apply group changes
sudo systemctl restart jenkins
```

### Step 4: Install Kubernetes (minikube for testing)

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start minikube
minikube start --driver=docker --cpus=2 --memory=4096

# Verify installation
kubectl get nodes
```

### Step 5: Create GitHub Repository

1. Create a new repository on GitHub
2. Initialize this project as a git repository:

```bash
cd /path/to/project
git init
git add .
git commit -m "Initial commit: Jenkins CI/CD Pipeline"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

### Step 6: Configure DockerHub

1. Create account at https://hub.docker.com
2. Create a repository named `cicd-webapp`
3. Note your username for Jenkins configuration

## 🔧 Jenkins Configuration

### Install Required Plugins

1. Navigate to: **Manage Jenkins → Manage Plugins → Available**
2. Install these plugins:
   - Git Plugin
   - GitHub Plugin
   - Docker Pipeline
   - Kubernetes CLI Plugin
   - Pipeline Plugin
   - Credentials Binding Plugin

### Configure Credentials

1. **DockerHub Credentials**:
   - Go to: **Manage Jenkins → Manage Credentials → Global → Add Credentials**
   - Kind: Username with password
   - ID: `dockerhub-credentials`
   - Username: Your DockerHub username
   - Password: Your DockerHub password/token

2. **Kubeconfig**:
   - Kind: Secret file
   - ID: `kubeconfig`
   - File: Upload your `~/.kube/config` file

3. **GitHub Token** (for webhook):
   - Kind: Secret text
   - ID: `github-token`
   - Secret: Your GitHub personal access token

### Create Jenkins Pipeline Job

1. Click **New Item**
2. Enter name: `CICD-WebApp-Pipeline`
3. Select: **Pipeline**
4. Click **OK**

**Configure the job:**

**General:**
- ✅ GitHub project: `https://github.com/YOUR_USERNAME/YOUR_REPO`

**Build Triggers:**
- ✅ GitHub hook trigger for GITScm polling

**Pipeline:**
- Definition: **Pipeline script from SCM**
- SCM: **Git**
- Repository URL: `https://github.com/YOUR_USERNAME/YOUR_REPO.git`
- Credentials: (select if private repo)
- Branch: `*/main`
- Script Path: `Jenkinsfile`

### Configure GitHub Webhook

1. Go to your GitHub repository
2. Navigate to: **Settings → Webhooks → Add webhook**
3. Payload URL: `http://<EC2-PUBLIC-IP>:8080/github-webhook/`
4. Content type: `application/json`
5. Events: **Just the push event**
6. ✅ Active
7. Click **Add webhook**

### Update Jenkinsfile

Before running the pipeline, update the following in `Jenkinsfile`:

```groovy
DOCKER_IMAGE = 'irfanriaz076/cicd-webapp'
```

Also update in `k8s/deployment.yaml`:

```yaml
image: irfanriaz076/cicd-webapp:latest
```

## 🔄 Pipeline Stages

The Jenkins pipeline consists of the following stages:

### 1. Code Fetch Stage
```groovy
- Checks out code from GitHub repository
- Triggered automatically via GitHub webhook
```

### 2. Install Dependencies
```groovy
- Runs npm install
- Prepares application for testing
```

### 3. Run Tests
```groovy
- Executes unit tests
- Continues on failure for demonstration
```

### 4. Docker Image Creation Stage
```groovy
- Builds Docker image from Dockerfile
- Tags image with build number and 'latest'
```

### 5. Push to DockerHub
```groovy
- Authenticates with DockerHub
- Pushes Docker image to registry
```

### 6. Kubernetes Deployment Stage
```groovy
- Applies Kubernetes manifests
- Deploys MongoDB
- Deploys web application
- Waits for rollout completion
```

### 7. Verify Deployment
```groovy
- Checks pod status
- Lists services
- Verifies deployment
```

### 8. Prometheus/Grafana Stage
```groovy
- Deploys Prometheus
- Deploys Grafana
- Configures monitoring
```

## 🌐 Accessing the Application

After successful deployment:

### Web Application
```bash
# Get the NodePort
kubectl get service webapp-service -n cicd-webapp

# Access URL
http://<NODE-IP>:30080
```

**API Endpoints:**
- `GET /` - Welcome message
- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics
- `GET /api/users` - Get all users
- `POST /api/users` - Create user
- `GET /api/users/:id` - Get user by ID
- `DELETE /api/users/:id` - Delete user

**Example Usage:**
```bash
# Health check
curl http://<NODE-IP>:30080/health

# Create user
curl -X POST http://<NODE-IP>:30080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'

# Get all users
curl http://<NODE-IP>:30080/api/users
```

### Prometheus Dashboard
```
URL: http://<NODE-IP>:30090
```

**Sample Queries:**
```promql
# HTTP request rate
rate(http_requests_total[5m])

# Request duration 95th percentile
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Memory usage
nodejs_heap_size_used_bytes / 1024 / 1024
```

### Grafana Dashboard
```
URL: http://<NODE-IP>:30030
Username: admin
Password: admin123
```

**Setup Steps:**
1. Login with credentials
2. Go to **Connections → Data Sources**
3. Verify Prometheus is connected
4. Go to **Dashboards → Import**
5. Import dashboard ID `1860` (Node Exporter Full)
6. Create custom dashboard for application metrics

## 📊 Monitoring

### Metrics Exposed by Application

The application exposes the following metrics at `/metrics`:

- `http_requests_total` - Total HTTP requests
- `http_request_duration_seconds` - Request duration histogram
- `nodejs_heap_size_used_bytes` - Node.js heap memory
- `nodejs_heap_size_total_bytes` - Total heap size
- `nodejs_external_memory_bytes` - External memory
- `process_cpu_user_seconds_total` - CPU usage

### Creating Grafana Dashboard

1. Login to Grafana
2. Click **+ → Dashboard**
3. Add panels with these queries:

**Request Rate:**
```promql
rate(http_requests_total{namespace="cicd-webapp"}[5m])
```

**Response Time:**
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{namespace="cicd-webapp"}[5m]))
```

**Memory Usage:**
```promql
nodejs_heap_size_used_bytes{namespace="cicd-webapp"} / 1024 / 1024
```

## 🐛 Troubleshooting

### Jenkins Build Fails

```bash
# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Check Docker permissions
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Docker Push Fails

```bash
# Verify credentials
docker login

# Check credentials in Jenkins
# Manage Jenkins → Manage Credentials
```

### Kubernetes Deployment Fails

```bash
# Check pod status
kubectl get pods -n cicd-webapp

# View pod logs
kubectl logs <pod-name> -n cicd-webapp

# Describe pod for events
kubectl describe pod <pod-name> -n cicd-webapp

# Check if image is pulled
kubectl describe pod <pod-name> -n cicd-webapp | grep -i image
```

### MongoDB Connection Issues

```bash
# Check MongoDB pod
kubectl get pods -n cicd-webapp | grep mongodb

# Check MongoDB logs
kubectl logs <mongodb-pod-name> -n cicd-webapp

# Verify service
kubectl get svc mongodb-service -n cicd-webapp
```

### Prometheus Not Scraping

```bash
# Check Prometheus pod
kubectl get pods -n monitoring

# Access Prometheus UI and check targets
http://<NODE-IP>:30090/targets

# Verify service annotations
kubectl describe svc webapp-service -n cicd-webapp
```

### Common Issues

**Issue**: Permission denied while trying to connect to Docker daemon
```bash
Solution:
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

**Issue**: Unable to connect to Kubernetes cluster
```bash
Solution:
# Copy kubeconfig to Jenkins
sudo cp ~/.kube/config /var/lib/jenkins/.kube/
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
```

**Issue**: GitHub webhook not triggering
```bash
Solution:
- Check webhook delivery in GitHub settings
- Verify Jenkins URL is accessible from internet
- Check firewall rules on EC2 instance
```

## 📝 Local Development

To run the application locally:

```bash
# Using Docker Compose
docker-compose up -d

# Access application
curl http://localhost:3000

# Stop services
docker-compose down
```

## 🔐 Security Best Practices

1. **Secrets Management**:
   - Use Kubernetes Secrets for sensitive data
   - Never commit credentials to Git
   - Rotate credentials regularly

2. **Jenkins Security**:
   - Enable authentication
   - Use role-based access control
   - Keep Jenkins updated

3. **Docker Security**:
   - Scan images for vulnerabilities
   - Use minimal base images
   - Run containers as non-root user

4. **Kubernetes Security**:
   - Use network policies
   - Enable RBAC
   - Limit resource usage

## 🎓 Learning Outcomes

Upon completion, you will have:

✅ Configured Jenkins on AWS EC2  
✅ Integrated Git with Jenkins using webhooks  
✅ Created Docker images and pushed to DockerHub  
✅ Deployed applications on Kubernetes  
✅ Set up monitoring with Prometheus and Grafana  
✅ Implemented a complete CI/CD pipeline  

## 📚 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

## 🤝 Contributing

Feel free to fork this project and submit pull requests for improvements.

## 📄 License

This project is licensed under the MIT License.

## 👤 Author

Your Name - Your Email

---

**Note**: Replace placeholders like `YOUR_USERNAME`, `YOUR_REPO`, `<EC2-PUBLIC-IP>`, and `<NODE-IP>` with actual values specific to your setup.
