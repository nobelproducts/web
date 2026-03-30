#!/bin/bash

set -e  # Exit on any error

DOCKER_IMAGE_FILES=(
    "./images/dragon-screen-web.tar"
    "./images/fenix-screen-web.tar"
    "./images/gustex-screen-web.tar"
    "./images/hotprint-screen-web.tar"
    "./images/turbo-screen-web.tar"
    "./images/flash-screen-web.tar"
)

DOCKER_COMPOSE_FILE="./docker-compose.yml"

load_docker_images() {
    echo "Loading specified Docker images..."

    for DOCKER_IMAGE_FILE in "${DOCKER_IMAGE_FILES[@]}"; do
        echo "Processing Docker image file: $DOCKER_IMAGE_FILE..."

        if [ -f "$DOCKER_IMAGE_FILE" ]; then
            echo "Loading Docker image from $DOCKER_IMAGE_FILE..."
            if docker load -i "$DOCKER_IMAGE_FILE"; then
                echo "Docker image $DOCKER_IMAGE_FILE loaded successfully."
            else
                echo "Error loading Docker image: $DOCKER_IMAGE_FILE"
                exit 1
            fi
        else
            echo "Docker image file not found: $DOCKER_IMAGE_FILE"
            echo "Available files in images directory:"
            ls -la ./images/ || echo "Images directory not found"
            exit 1
        fi
    done
}

run_docker_compose() {
    echo "Starting Docker Compose with file $DOCKER_COMPOSE_FILE..."
    if [ -f "$DOCKER_COMPOSE_FILE" ]; then
        if docker compose -f "$DOCKER_COMPOSE_FILE" up -d; then
            echo "Docker Compose started successfully."
        else
            echo "Error starting Docker Compose."
            exit 1
        fi
    else
        echo "Docker Compose file not found: $DOCKER_COMPOSE_FILE"
        exit 1
    fi
}

load_docker_images
run_docker_compose
