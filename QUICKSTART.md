# Quick Start Guide

This guide will help you quickly deploy the CI/CD pipeline.

## Prerequisites Checklist

- [ ] AWS EC2 instance (t2.medium, Ubuntu 20.04)
- [ ] DockerHub account
- [ ] GitHub account
- [ ] SSH access to EC2 instance

## Quick Setup (15 minutes)

### 1. Launch EC2 Instance (2 min)

```bash
# Instance configuration:
- Type: t2.medium
- AMI: Ubuntu Server 20.04 LTS
- Storage: 20GB
- Security Group: Ports 22, 8080, 30000-32767
```

### 2. Install Everything (5 min)

```bash
# Connect to EC2
ssh -i your-key.pem ubuntu@<EC2-IP>

# Run installation script
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/scripts/install.sh
chmod +x install.sh
sudo ./install.sh
```

OR manually:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Java
sudo apt install -y openjdk-11-jdk

# Install Jenkins
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update && sudo apt install -y jenkins
sudo systemctl start jenkins && sudo systemctl enable jenkins

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo usermod -aG docker jenkins && sudo systemctl restart jenkins

# Install Kubernetes (minikube)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start --driver=docker --cpus=2 --memory=4096
```

### 3. Configure Jenkins (3 min)

```bash
# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Open browser: http://13.60.162.92:8080
# Paste password
# Install suggested plugins
# Create admin user
```

### 4. Add Credentials (2 min)

**Manage Jenkins → Manage Credentials → Add:**

1. **DockerHub**:
   - Kind: Username with password
   - ID: `dockerhub-credentials`
   - Username/Password: Your DockerHub credentials

2. **Kubeconfig**:
   ```bash
   # Copy kubeconfig
   sudo mkdir -p /var/lib/jenkins/.kube
   sudo cp ~/.kube/config /var/lib/jenkins/.kube/
   sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
   ```
   - Kind: Secret file
   - ID: `kubeconfig`
   - File: Upload `~/.kube/config`

### 5. Create Repository (1 min)

```bash
# Clone or create new repo
git clone <this-repo>
cd <repo>

# Update Jenkinsfile
# Change: DOCKER_IMAGE = 'YOUR_USERNAME/cicd-webapp'

# Update k8s/deployment.yaml
# Change: image: YOUR_USERNAME/cicd-webapp:latest

# Push to GitHub
git add .
git commit -m "Initial setup"
git push
```

### 6. Create Pipeline (1 min)

1. Jenkins → New Item → Pipeline → Name: `CICD-WebApp-Pipeline`
2. Configure:
   - GitHub project: `https://github.com/YOUR_USERNAME/YOUR_REPO`
   - ✅ GitHub hook trigger
   - Pipeline from SCM → Git → Repository URL
   - Script Path: `Jenkinsfile`
3. Save

### 7. Setup Webhook (1 min)

GitHub Repo → Settings → Webhooks → Add:
- URL: `http://13.60.162.92:8080/github-webhook/`
- Content type: `application/json`
- Events: Just the push event

## First Build

```bash
# Trigger build
git commit --allow-empty -m "Trigger build"
git push

# Watch build
# Jenkins → CICD-WebApp-Pipeline → Build Now
```

## Access Everything

After successful build:

```bash
# Get NodePort IP
kubectl get nodes -o wide

# Application
http://<NODE-IP>:30080

# Prometheus
http://<NODE-IP>:30090

# Grafana
http://<NODE-IP>:30030
# Username: admin
# Password: admin123
```

## Test Application

```bash
# Health check
curl http://<NODE-IP>:30080/health

# Create user
curl -X POST http://<NODE-IP>:30080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}'

# Get users
curl http://<NODE-IP>:30080/api/users

# Metrics
curl http://<NODE-IP>:30080/metrics
```

## Common Issues

### Jenkins can't access Docker
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Kubernetes connection failed
```bash
sudo cp ~/.kube/config /var/lib/jenkins/.kube/
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
```

### Pipeline fails at Docker push
```bash
# Verify credentials in Jenkins
# Manage Jenkins → Manage Credentials
# Check dockerhub-credentials
```

### Pods not starting
```bash
kubectl get pods -n cicd-webapp
kubectl describe pod <pod-name> -n cicd-webapp
kubectl logs <pod-name> -n cicd-webapp
```

## Verification Steps

```bash
# 1. Check all services
sudo systemctl status jenkins
sudo systemctl status docker
minikube status

# 2. Check Jenkins plugins
# Manage Jenkins → Manage Plugins → Installed

# 3. Check Kubernetes
kubectl get nodes
kubectl get pods --all-namespaces

# 4. Check credentials
# Manage Jenkins → Manage Credentials → Global

# 5. Test pipeline
# Make a change and push to GitHub
# Watch build trigger automatically
```

## Next Steps

1. ✅ Configure Grafana dashboards
2. ✅ Set up alerts in Prometheus
3. ✅ Add more test cases
4. ✅ Configure backup strategy
5. ✅ Set up SSL/TLS
6. ✅ Implement staging environment

## Resources

- Full documentation: [README.md](README.md)
- Jenkins setup: [JENKINS_SETUP.md](JENKINS_SETUP.md)
- Troubleshooting: Check logs in respective sections

## Support

If you encounter issues:
1. Check logs: `sudo journalctl -u jenkins -f`
2. Verify credentials in Jenkins
3. Check pod status: `kubectl get pods -n cicd-webapp`
4. Review webhook deliveries in GitHub

---

**Total Setup Time: ~15 minutes**

Happy deploying! 🚀
