# 🐳 Running OpenHands with Docker

This guide explains how to run OpenHands using Docker. There are **three main approaches**:

---

## 📋 Quick Overview

| Method | Use Case | Command |
|--------|----------|---------|
| **Docker Compose** | Run the full app (easiest) | `make docker-run` |
| **Docker Dev Container** | Develop inside Docker | `make docker-dev` |
| **Manual Docker Build** | Custom builds | See below |

---

## 🚀 Method 1: Docker Compose (Recommended for Running)

This is the **easiest way** to run OpenHands without installing dependencies on your host machine.

### Prerequisites
- Docker installed and running
- Docker Compose (usually comes with Docker Desktop)

### Steps

1. **Navigate to the OpenHands directory:**
   ```bash
   cd /media/aashikant/GAME\ Volume/aicode/OpenHands
   ```

2. **Run the application:**
   ```bash
   make docker-run
   ```

   Or with custom workspace:
   ```bash
   WORKSPACE_BASE=/path/to/your/workspace make docker-run
   ```

3. **Access the application:**
   - Frontend: http://localhost:3001
   - Backend API: http://localhost:3000

### What This Does
- Builds the Docker images if needed
- Starts both backend and frontend in containers
- Mounts your workspace directory
- Sets up proper user permissions

### Stopping the Application
Press `Ctrl+C` in the terminal, or run:
```bash
docker compose down
```

---

## 🛠️ Method 2: Docker Dev Container (Recommended for Development)

This method lets you **develop inside a Docker container** with all dependencies pre-installed.

### Prerequisites
- Docker installed and running

### Steps

1. **Start the dev container:**
   ```bash
   make docker-dev
   ```

   Or manually:
   ```bash
   cd containers/dev
   ./dev.sh
   ```

2. **You'll be inside the container:**
   ```bash
   root@93fc0005fcd2:/app#
   ```

3. **Now build and run as normal:**
   ```bash
   make build
   make run
   ```

### Features
- Your source code is mounted at `/app`
- Edit files on your host with your favorite IDE
- Changes are reflected immediately in the container
- Git credentials are mounted (read-only)

### Mapped Directories
```yaml
# From host to container (read-only)
- $HOME/.git-credentials:/root/.git-credentials:ro
- $HOME/.gitconfig:/root/.gitconfig:ro
- $HOME/.npmrc:/root/.npmrc:ro
```

### Rebuild the Dev Image
If you need to rebuild the dev container:
```bash
make docker-dev OPTIONS="--build"
```

### VSCode Integration
You can attach VSCode to the running container:
1. Install the "Dev Containers" extension
2. Click the green icon in the bottom-left corner
3. Select "Attach to Running Container"
4. Choose the OpenHands container

---

## 🔧 Method 3: Manual Docker Build

For custom builds or CI/CD pipelines.

### Build the Application Image

```bash
docker build -f containers/app/Dockerfile -t openhands:latest .
```

### Build the Sandbox Image

```bash
docker build -f containers/sandbox/Dockerfile -t openhands-sandbox:latest .
```

### Run the Application

```bash
docker run -d \
  --name openhands-app \
  -p 3000:3000 \
  -p 3001:3001 \
  -v $(pwd)/workspace:/app/workspace \
  -e LLM_API_KEY=your_api_key_here \
  -e LLM_MODEL=gpt-4o \
  openhands:latest
```

### Environment Variables

You can configure OpenHands with environment variables:

```bash
docker run -d \
  --name openhands-app \
  -p 3000:3000 \
  -p 3001:3001 \
  -v $(pwd)/workspace:/app/workspace \
  -e LLM_API_KEY=your_openai_api_key \
  -e LLM_MODEL=gpt-4o \
  -e LLM_BASE_URL=http://localhost:5001/v1 \
  -e BACKEND_HOST=0.0.0.0 \
  -e BACKEND_PORT=3000 \
  -e FRONTEND_PORT=3001 \
  openhands:latest
```

---

## 🔍 Docker Compose Configuration

OpenHands uses `docker-compose.yml` (in the root directory) for orchestration.

### Key Services

The compose file typically includes:
- **Backend Service**: FastAPI server
- **Frontend Service**: React application
- **Sandbox Service**: Isolated execution environment

### Customizing Docker Compose

You can override settings by creating a `docker-compose.override.yml`:

```yaml
version: '3.8'

services:
  backend:
    environment:
      - LLM_MODEL=gpt-4o
      - LLM_API_KEY=your_key_here
    ports:
      - "8000:3000"  # Custom port mapping
```

---

## 📊 Checking Docker Status

### View Running Containers
```bash
docker ps
```

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f frontend
```

### Check Resource Usage
```bash
docker stats
```

---

## 🐛 Troubleshooting

### Issue: "Cannot connect to Docker daemon"

**Solution:**
```bash
# Start Docker Desktop (macOS/Windows)
# Or start Docker service (Linux)
sudo systemctl start docker
```

### Issue: "Port already in use"

**Solution:**
```bash
# Find what's using the port
lsof -i :3000
lsof -i :3001

# Kill the process or use different ports
make docker-run BACKEND_PORT=8000 FRONTEND_PORT=8001
```

### Issue: "Permission denied" when accessing workspace

**Solution:**
```bash
# Set proper permissions
chmod -R 755 workspace/

# Or run with your user ID
SANDBOX_USER_ID=$(id -u) make docker-run
```

### Issue: Docker build fails

**Solution:**
```bash
# Clean up Docker cache
docker system prune -a

# Rebuild from scratch
docker compose build --no-cache
```

### Issue: Container exits immediately

**Solution:**
```bash
# Check logs for errors
docker compose logs

# Run in foreground to see errors
docker compose up
```

---

## 🔐 Security Considerations

### API Keys
- **Never commit API keys** to version control
- Use environment variables or `.env` files
- Add `.env` to `.gitignore`

### Network Exposure
```bash
# Local only (default)
make docker-run

# Expose to network (be careful!)
make run BACKEND_HOST=0.0.0.0 FRONTEND_HOST=0.0.0.0
```

### Workspace Isolation
- The workspace directory is mounted into the container
- Code execution happens in isolated sandboxes
- Be cautious about what code you let the agent execute

---

## 📦 Docker Images

### Official Images
OpenHands publishes images to GitHub Container Registry (GHCR):

```bash
# Pull the latest image
docker pull ghcr.io/openhands/openhands:latest

# Run the official image
docker run -d \
  -p 3000:3000 \
  -p 3001:3001 \
  -v $(pwd)/workspace:/app/workspace \
  ghcr.io/openhands/openhands:latest
```

### Image Tags
- `latest` - Latest stable release
- `main` - Latest from main branch
- `v0.x.x` - Specific version tags

---

## 🚀 Advanced: Multi-Architecture Builds

If you need to build for different architectures (e.g., ARM for Apple Silicon):

```bash
# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f containers/app/Dockerfile \
  -t openhands:multi-arch \
  .
```

---

## 🔄 Updating OpenHands in Docker

### Pull Latest Changes
```bash
# Stop containers
docker compose down

# Pull latest code
git pull origin main

# Rebuild and restart
make docker-run
```

### Clean Rebuild
```bash
# Remove old containers and images
docker compose down --rmi all

# Rebuild from scratch
make docker-run
```

---

## 📝 Quick Reference

### Essential Commands

```bash
# Start application
make docker-run

# Start dev container
make docker-dev

# Stop application
docker compose down

# View logs
docker compose logs -f

# Rebuild images
docker compose build

# Clean up everything
docker compose down --rmi all --volumes
docker system prune -a
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `BACKEND_HOST` | Backend host address | `127.0.0.1` |
| `BACKEND_PORT` | Backend port | `3000` |
| `FRONTEND_PORT` | Frontend port | `3001` |
| `WORKSPACE_BASE` | Workspace directory | `./workspace` |
| `LLM_MODEL` | LLM model name | `gpt-4o` |
| `LLM_API_KEY` | LLM API key | (required) |
| `LLM_BASE_URL` | Custom LLM endpoint | (optional) |

---

## 🎯 Next Steps

1. **Configure your LLM:**
   - Open http://localhost:3001
   - Go to Settings
   - Add your API key and select a model

2. **Start using OpenHands:**
   - Create a new conversation
   - Ask the agent to help with coding tasks

3. **Explore the workspace:**
   - Files created by the agent appear in `workspace/`
   - You can edit them directly on your host

---

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [OpenHands Documentation](https://docs.openhands.dev/)
- [Development Guide](../Development.md)
- [Architecture Guide](./architecture-guide.md)

---

**Need Help?** Join the [OpenHands Slack community](https://dub.sh/openhands)!
