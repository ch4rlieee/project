#!/bin/bash

###############################################################################
# Jenkins CI/CD Pipeline - Installation Script
# This script installs Jenkins, Docker, and Kubernetes on Ubuntu 20.04
###############################################################################

set -e

echo "======================================================================"
echo "Jenkins CI/CD Pipeline - Automated Installation"
echo "======================================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
    exit 1
fi

print_info "Starting installation..."

# Update system
print_info "Updating system packages..."
apt update && apt upgrade -y
print_success "System updated"

# Install essential tools
print_info "Installing essential tools..."
apt install -y curl wget git vim apt-transport-https ca-certificates software-properties-common
print_success "Essential tools installed"

# Install Java
print_info "Installing Java..."
apt install -y openjdk-11-jdk
java -version
print_success "Java installed"

# Install Jenkins
print_info "Installing Jenkins..."
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt update
apt install -y jenkins
systemctl start jenkins
systemctl enable jenkins
print_success "Jenkins installed and started"

# Install Docker
print_info "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh
systemctl start docker
systemctl enable docker
print_success "Docker installed"

# Add users to docker group
print_info "Configuring Docker permissions..."
usermod -aG docker jenkins
usermod -aG docker ubuntu
print_success "Docker permissions configured"

# Install kubectl
print_info "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
print_success "kubectl installed"

# Install minikube
print_info "Installing minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
print_success "minikube installed"

# Start minikube
print_info "Starting minikube cluster..."
su - ubuntu -c "minikube start --driver=docker --cpus=2 --memory=4096"
print_success "minikube cluster started"

# Configure kubectl for jenkins
print_info "Configuring kubectl for Jenkins..."
mkdir -p /var/lib/jenkins/.kube
cp /home/ubuntu/.kube/config /var/lib/jenkins/.kube/config
chown -R jenkins:jenkins /var/lib/jenkins/.kube
print_success "kubectl configured for Jenkins"

# Restart Jenkins
print_info "Restarting Jenkins..."
systemctl restart jenkins
print_success "Jenkins restarted"

# Get Jenkins initial password
JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)

echo ""
echo "======================================================================"
echo "Installation Complete!"
echo "======================================================================"
echo ""
print_success "All components installed successfully"
echo ""
echo "Access Information:"
echo "-------------------"
echo "Jenkins URL: http://$(curl -s ifconfig.me):8080"
echo "Initial Admin Password: $JENKINS_PASSWORD"
echo ""
echo "Services Status:"
echo "-------------------"
systemctl is-active --quiet jenkins && print_success "Jenkins: Running" || print_error "Jenkins: Not Running"
systemctl is-active --quiet docker && print_success "Docker: Running" || print_error "Docker: Not Running"
su - ubuntu -c "minikube status" > /dev/null 2>&1 && print_success "Minikube: Running" || print_error "Minikube: Not Running"
echo ""
echo "Next Steps:"
echo "-------------------"
echo "1. Open Jenkins: http://$(curl -s ifconfig.me):8080"
echo "2. Paste the initial admin password shown above"
echo "3. Install suggested plugins"
echo "4. Create admin user"
echo "5. Configure credentials (DockerHub, GitHub)"
echo "6. Create pipeline job"
echo ""
print_info "For detailed instructions, see JENKINS_SETUP.md"
echo "======================================================================"
