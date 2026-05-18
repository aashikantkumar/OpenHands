#!/bin/bash

# Navigate to the symlinked directory (avoids space-in-path issues)
cd ~/openhands || exit 1

# Start OpenHands with Docker
docker run -it \
    --pull=always \
    -e SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/runtime:0.30-nikolaik \
    -e LOG_ALL_EVENTS=true \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v ~/.openhands-state:/.openhands-state \
    -v "$(pwd)/config.toml":/app/config.toml \
    -p 3000:3000 \
    --add-host host.docker.internal:host-gateway \
    --name openhands-app-$(date +%Y%m%d%H%M%S) \
    openhands:latest
