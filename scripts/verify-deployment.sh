#!/bin/bash

###############################################################################
# Deployment Verification Script
# Checks if all components are deployed and running correctly
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
echo "Deployment Verification"
echo "======================================================================"
echo ""

# Check Kubernetes cluster
print_info "Checking Kubernetes cluster..."
if kubectl cluster-info > /dev/null 2>&1; then
    print_success "Kubernetes cluster is accessible"
else
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

# Check namespaces
print_info "Checking namespaces..."
if kubectl get namespace cicd-webapp > /dev/null 2>&1; then
    print_success "Namespace 'cicd-webapp' exists"
else
    print_error "Namespace 'cicd-webapp' not found"
fi

if kubectl get namespace monitoring > /dev/null 2>&1; then
    print_success "Namespace 'monitoring' exists"
else
    print_error "Namespace 'monitoring' not found"
fi

echo ""
print_info "Application Components:"
echo "-------------------"

# Check MongoDB
MONGO_PODS=$(kubectl get pods -n cicd-webapp -l app=mongodb --no-headers 2>/dev/null | wc -l)
if [ "$MONGO_PODS" -gt 0 ]; then
    MONGO_READY=$(kubectl get pods -n cicd-webapp -l app=mongodb -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    if [ "$MONGO_READY" = "True" ]; then
        print_success "MongoDB: Running"
    else
        print_error "MongoDB: Not Ready"
    fi
else
    print_error "MongoDB: Not Deployed"
fi

# Check Web App
APP_PODS=$(kubectl get pods -n cicd-webapp -l app=webapp --no-headers 2>/dev/null | wc -l)
if [ "$APP_PODS" -gt 0 ]; then
    APP_READY=$(kubectl get pods -n cicd-webapp -l app=webapp -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -c "True")
    print_success "Web Application: $APP_READY/$APP_PODS pods ready"
else
    print_error "Web Application: Not Deployed"
fi

# Check Services
print_info "Checking services..."
if kubectl get svc webapp-service -n cicd-webapp > /dev/null 2>&1; then
    WEBAPP_PORT=$(kubectl get svc webapp-service -n cicd-webapp -o jsonpath='{.spec.ports[0].nodePort}')
    print_success "Web Application Service: Available on port $WEBAPP_PORT"
else
    print_error "Web Application Service: Not Found"
fi

echo ""
print_info "Monitoring Components:"
echo "-------------------"

# Check Prometheus
PROM_PODS=$(kubectl get pods -n monitoring -l app=prometheus --no-headers 2>/dev/null | wc -l)
if [ "$PROM_PODS" -gt 0 ]; then
    PROM_READY=$(kubectl get pods -n monitoring -l app=prometheus -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    if [ "$PROM_READY" = "True" ]; then
        PROM_PORT=$(kubectl get svc prometheus-service -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')
        print_success "Prometheus: Running on port $PROM_PORT"
    else
        print_error "Prometheus: Not Ready"
    fi
else
    print_error "Prometheus: Not Deployed"
fi

# Check Grafana
GRAFANA_PODS=$(kubectl get pods -n monitoring -l app=grafana --no-headers 2>/dev/null | wc -l)
if [ "$GRAFANA_PODS" -gt 0 ]; then
    GRAFANA_READY=$(kubectl get pods -n monitoring -l app=grafana -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    if [ "$GRAFANA_READY" = "True" ]; then
        GRAFANA_PORT=$(kubectl get svc grafana-service -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')
        print_success "Grafana: Running on port $GRAFANA_PORT"
    else
        print_error "Grafana: Not Ready"
    fi
else
    print_error "Grafana: Not Deployed"
fi

echo ""
print_info "Access URLs:"
echo "-------------------"

# Get Node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

if [ -n "$WEBAPP_PORT" ]; then
    echo "Web Application: http://$NODE_IP:$WEBAPP_PORT"
fi

if [ -n "$PROM_PORT" ]; then
    echo "Prometheus:      http://$NODE_IP:$PROM_PORT"
fi

if [ -n "$GRAFANA_PORT" ]; then
    echo "Grafana:         http://$NODE_IP:$GRAFANA_PORT (admin/admin123)"
fi

echo ""
print_info "Testing Application Endpoints:"
echo "-------------------"

if [ -n "$WEBAPP_PORT" ]; then
    # Test health endpoint
    if curl -s -o /dev/null -w "%{http_code}" "http://$NODE_IP:$WEBAPP_PORT/health" | grep -q "200"; then
        print_success "Health endpoint: OK"
    else
        print_error "Health endpoint: Failed"
    fi
    
    # Test metrics endpoint
    if curl -s "http://$NODE_IP:$WEBAPP_PORT/metrics" | grep -q "http_requests_total"; then
        print_success "Metrics endpoint: OK"
    else
        print_error "Metrics endpoint: Failed"
    fi
fi

echo ""
print_info "Pod Status:"
echo "-------------------"
echo "Application Pods:"
kubectl get pods -n cicd-webapp

echo ""
echo "Monitoring Pods:"
kubectl get pods -n monitoring

echo ""
echo "======================================================================"
print_success "Verification Complete!"
echo "======================================================================"
