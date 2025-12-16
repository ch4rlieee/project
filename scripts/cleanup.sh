#!/bin/bash

###############################################################################
# Cleanup Script
# Removes all deployed resources from Kubernetes
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

echo "======================================================================"
echo "Cleanup Script - Remove All Deployments"
echo "======================================================================"
echo ""

print_info "This will delete all deployed resources from Kubernetes"
read -p "Are you sure? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    print_info "Cleanup cancelled"
    exit 0
fi

# Delete application resources
print_info "Deleting application resources..."
kubectl delete namespace cicd-webapp --ignore-not-found=true
print_success "Application namespace deleted"

# Delete monitoring resources
print_info "Deleting monitoring resources..."
kubectl delete namespace monitoring --ignore-not-found=true
print_success "Monitoring namespace deleted"

# Wait for cleanup
print_info "Waiting for resources to be cleaned up..."
sleep 5

# Verify cleanup
echo ""
print_info "Verifying cleanup..."

if kubectl get namespace cicd-webapp 2>/dev/null; then
    print_error "Namespace 'cicd-webapp' still exists"
else
    print_success "Namespace 'cicd-webapp' removed"
fi

if kubectl get namespace monitoring 2>/dev/null; then
    print_error "Namespace 'monitoring' still exists"
else
    print_success "Namespace 'monitoring' removed"
fi

echo ""
print_success "Cleanup complete!"
echo ""
print_info "To redeploy, run the Jenkins pipeline again"
echo "======================================================================"
