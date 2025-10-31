#!/bin/bash

# Saweria Payment Gateway Docker Deployment Script
# Usage: ./docker-deploy.sh [build|run|stop|restart|logs|clean]

set -e

# Configuration
IMAGE_NAME="saweria-payment-gateway"
CONTAINER_NAME="saweria-gateway-app"
HOST_PORT=8000
CONTAINER_PORT=8000

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
}

build_image() {
    log_info "Building Docker image: $IMAGE_NAME"
    docker build -t $IMAGE_NAME .
    log_success "Docker image built successfully!"
}

stop_container() {
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        log_info "Stopping running container: $CONTAINER_NAME"
        docker stop $CONTAINER_NAME
        log_success "Container stopped"
    fi
}

remove_container() {
    if docker ps -a -q -f name=$CONTAINER_NAME | grep -q .; then
        log_info "Removing container: $CONTAINER_NAME"
        docker rm $CONTAINER_NAME
        log_success "Container removed"
    fi
}

run_container() {
    log_info "Starting container: $CONTAINER_NAME"
    log_info "App will be available at: http://localhost:$HOST_PORT"
    log_info "API Documentation: http://localhost:$HOST_PORT/docs"

    docker run -d \
        --name $CONTAINER_NAME \
        --restart unless-stopped \
        -p $HOST_PORT:$CONTAINER_PORT \
        -e DEBUG=false \
        -e LOG_LEVEL=INFO \
        $IMAGE_NAME

    log_success "Container started!"
    log_info "Checking container status..."

    # Wait a moment for container to start
    sleep 3

    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        log_success "Container is running!"
        show_logs
    else
        log_error "Container failed to start. Check logs:"
        docker logs $CONTAINER_NAME
        exit 1
    fi
}

show_logs() {
    log_info "Container logs (last 20 lines):"
    echo "----------------------------------------"
    docker logs --tail 20 $CONTAINER_NAME
    echo "----------------------------------------"
    log_info "To follow logs: docker logs -f $CONTAINER_NAME"
}

show_status() {
    log_info "Container Status:"
    docker ps -f name=$CONTAINER_NAME --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        log_success "Container is running"
        log_info "App URL: http://localhost:$HOST_PORT"
        log_info "API Docs: http://localhost:$HOST_PORT/docs"
    else
        log_warning "Container is not running"
    fi
}

clean_images() {
    log_info "Cleaning up dangling images..."
    docker image prune -f
    log_success "Cleanup completed"
}

restart_container() {
    log_info "Restarting container..."
    stop_container
    run_container
}

deploy() {
    log_info "Starting full deployment..."
    build_image
    stop_container
    remove_container
    run_container
    log_success "Deployment completed!"
    log_info "🚀 App is running at: http://localhost:$HOST_PORT"
}

show_help() {
    echo "Saweria Payment Gateway Docker Deployment Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  deploy     - Full deployment (build + run)"
    echo "  build      - Build Docker image only"
    echo "  run        - Run container (stops existing first)"
    echo "  stop       - Stop running container"
    echo "  restart    - Restart container"
    echo "  logs       - Show container logs"
    echo "  status     - Show container status"
    echo "  clean      - Clean up dangling images"
    echo "  remove     - Remove container"
    echo "  help       - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 deploy          # Full deployment"
    echo "  $0 logs           # View logs"
    echo "  $0 restart        # Restart app"
    echo ""
}

# Main script
check_docker

case "${1:-deploy}" in
    "deploy")
        deploy
        ;;
    "build")
        build_image
        ;;
    "run")
        stop_container
        remove_container
        run_container
        ;;
    "stop")
        stop_container
        ;;
    "restart")
        restart_container
        ;;
    "logs")
        show_logs
        ;;
    "status")
        show_status
        ;;
    "clean")
        clean_images
        ;;
    "remove")
        stop_container
        remove_container
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
