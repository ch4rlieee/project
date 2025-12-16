# Jenkins Setup Guide

## AWS EC2 Instance Setup

### 1. Launch EC2 Instance

```bash
# Instance specifications:
- AMI: Ubuntu Server 20.04 LTS
- Instance Type: t2.medium (2 vCPU, 4GB RAM)
- Storage: 20GB GP2
- Security Group: Allow ports 22, 8080, 80, 443, 30000-32767
```

### 2. Connect to EC2 Instance

```bash
ssh -i your-key.pem ubuntu@<EC2-PUBLIC-IP>
```

### 3. Initial System Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git vim
```

## Jenkins Installation

### Install Java

```bash
# Install OpenJDK 11
sudo apt install -y openjdk-11-jdk

# Verify installation
java -version
javac -version

# Set JAVA_HOME
echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> ~/.bashrc
source ~/.bashrc
```

### Install Jenkins

```bash
# Add Jenkins repository key
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -

# Add Jenkins repository
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# Update package list
sudo apt update

# Install Jenkins
sudo apt install -y jenkins

# Start Jenkins service
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check Jenkins status
sudo systemctl status jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Access Jenkins

Open browser and navigate to: `http://<EC2-PUBLIC-IP>:8080`

### Initial Jenkins Configuration

1. **Unlock Jenkins**:
   - Paste the initial admin password
   - Click Continue

2. **Customize Jenkins**:
   - Select "Install suggested plugins"
   - Wait for plugins to install

3. **Create Admin User**:
   - Username: admin
   - Password: (choose a strong password)
   - Full name: Administrator
   - Email: your-email@example.com

4. **Instance Configuration**:
   - Jenkins URL: `http://<EC2-PUBLIC-IP>:8080/`
   - Click "Save and Finish"

## Install Required Jenkins Plugins

Navigate to: **Manage Jenkins → Manage Plugins → Available**

Install the following plugins:

```
✓ Git Plugin
✓ GitHub Plugin
✓ GitHub Integration Plugin
✓ Pipeline Plugin
✓ Docker Pipeline Plugin
✓ Docker Plugin
✓ Kubernetes Plugin
✓ Kubernetes CLI Plugin
✓ Credentials Binding Plugin
✓ Environment Injector Plugin
✓ Blue Ocean (optional, for better UI)
```

After installation, restart Jenkins:
```bash
sudo systemctl restart jenkins
```

## Docker Installation

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
sudo usermod -aG docker $USER
sudo usermod -aG docker jenkins

# Apply group changes (or logout and login)
newgrp docker

# Test Docker
docker --version
docker run hello-world

# Restart Jenkins to apply docker group
sudo systemctl restart jenkins
```

## Kubernetes Installation

### Option 1: Minikube (for testing)

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start minikube
minikube start --driver=docker --cpus=2 --memory=4096

# Verify
kubectl cluster-info
kubectl get nodes

# Copy kubeconfig for Jenkins
mkdir -p /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
```

### Option 2: kubeadm (for production)

```bash
# Install kubeadm, kubelet, kubectl
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Initialize cluster (master node)
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configure kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install CNI plugin (Flannel)
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

## Configure Jenkins Credentials

### 1. DockerHub Credentials

1. Go to: **Manage Jenkins → Manage Credentials**
2. Click on **(global)** domain
3. Click **Add Credentials**
4. Fill in:
   - Kind: **Username with password**
   - Scope: **Global**
   - Username: Your DockerHub username
   - Password: Your DockerHub password/token
   - ID: `dockerhub-credentials`
   - Description: DockerHub Credentials

### 2. Kubeconfig File

1. Go to: **Manage Jenkins → Manage Credentials**
2. Click **(global)** → **Add Credentials**
3. Fill in:
   - Kind: **Secret file**
   - Scope: **Global**
   - File: Upload `~/.kube/config`
   - ID: `kubeconfig`
   - Description: Kubernetes Config

### 3. GitHub Token (for webhook)

1. Create GitHub Personal Access Token:
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Generate new token with `repo` and `admin:repo_hook` permissions

2. Add to Jenkins:
   - Kind: **Secret text**
   - Scope: **Global**
   - Secret: Your GitHub token
   - ID: `github-token`
   - Description: GitHub Token

## Create Jenkins Pipeline

### 1. Create New Pipeline Job

1. Click **New Item**
2. Enter name: `CICD-WebApp-Pipeline`
3. Select **Pipeline**
4. Click **OK**

### 2. Configure Pipeline

**General Section:**
- Description: "CI/CD Pipeline for Web Application"
- ✅ GitHub project: `https://github.com/YOUR_USERNAME/YOUR_REPO`

**Build Triggers:**
- ✅ GitHub hook trigger for GITScm polling

**Pipeline Section:**
- Definition: **Pipeline script from SCM**
- SCM: **Git**
- Repository URL: `https://github.com/YOUR_USERNAME/YOUR_REPO.git`
- Credentials: (select if private repo)
- Branch Specifier: `*/main`
- Script Path: `Jenkinsfile`

Click **Save**

## Configure GitHub Webhook

### 1. Create Webhook

1. Go to your GitHub repository
2. Click **Settings** → **Webhooks** → **Add webhook**
3. Configure:
   - Payload URL: `http://<EC2-PUBLIC-IP>:8080/github-webhook/`
   - Content type: `application/json`
   - Secret: (leave empty for now)
   - SSL verification: Disable (if using HTTP)
   - Which events: **Just the push event**
   - ✅ Active

4. Click **Add webhook**

### 2. Test Webhook

1. Make a small change to README.md
2. Commit and push to GitHub
3. Check GitHub webhook delivery status
4. Jenkins should automatically trigger build

## Verify Installation

### Check Jenkins

```bash
# Jenkins status
sudo systemctl status jenkins

# Jenkins logs
sudo tail -f /var/lib/jenkins/jenkins.log
```

### Check Docker

```bash
# Docker status
sudo systemctl status docker

# Docker version
docker --version

# Test docker access
docker ps
```

### Check Kubernetes

```bash
# Cluster info
kubectl cluster-info

# Node status
kubectl get nodes

# All resources
kubectl get all --all-namespaces
```

## Firewall Configuration

### AWS Security Group

Ensure the following ports are open:

```
Port 22    - SSH
Port 8080  - Jenkins
Port 80    - HTTP
Port 443   - HTTPS
Port 30000-32767 - Kubernetes NodePort range
```

### UFW (if using Ubuntu firewall)

```bash
sudo ufw allow 22/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 30000:32767/tcp
sudo ufw enable
sudo ufw status
```

## Troubleshooting

### Jenkins Won't Start

```bash
# Check Java installation
java -version

# Check Jenkins status
sudo systemctl status jenkins

# View logs
sudo journalctl -u jenkins -f

# Restart Jenkins
sudo systemctl restart jenkins
```

### Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER
sudo usermod -aG docker jenkins

# Restart services
sudo systemctl restart docker
sudo systemctl restart jenkins

# Verify groups
groups jenkins
```

### Kubernetes Connection Failed

```bash
# Check cluster
kubectl cluster-info

# Verify config
cat ~/.kube/config

# Check permissions
ls -la ~/.kube/

# Copy config for Jenkins
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
```

## Next Steps

1. ✅ Push your code to GitHub
2. ✅ Update Jenkinsfile with your DockerHub username
3. ✅ Update k8s/deployment.yaml with your Docker image
4. ✅ Trigger pipeline by pushing to GitHub
5. ✅ Monitor build in Jenkins dashboard
6. ✅ Access application on NodePort
7. ✅ Check Prometheus and Grafana dashboards

## Useful Commands

```bash
# Jenkins commands
sudo systemctl start jenkins
sudo systemctl stop jenkins
sudo systemctl restart jenkins
sudo systemctl status jenkins

# Docker commands
docker ps
docker images
docker logs <container-id>
docker exec -it <container-id> bash

# Kubernetes commands
kubectl get pods -n cicd-webapp
kubectl get svc -n cicd-webapp
kubectl logs <pod-name> -n cicd-webapp
kubectl describe pod <pod-name> -n cicd-webapp
kubectl delete pod <pod-name> -n cicd-webapp

# Monitoring
kubectl get pods -n monitoring
kubectl port-forward -n monitoring svc/prometheus-service 9090:9090
kubectl port-forward -n monitoring svc/grafana-service 3000:3000
```

---

For detailed application usage and API documentation, refer to the main [README.md](README.md).
