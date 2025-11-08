# Docker Deployment Examples

This directory contains Docker and Docker Compose examples for deploying the HGNC MCP server.

## Quick Start

### Basic Deployment

From the project root:

```bash
# Build and start the server
docker compose up -d

# Check logs
docker compose logs -f

# Access Swagger UI
open http://localhost:8080/__docs__/

# Test the server
docker compose --profile test up hgnc-test-client

# Stop the server
docker compose down
```

> **Note**: These examples use the modern `docker compose` command (Docker Compose V2, bundled with Docker). If you have the legacy standalone version, use `docker-compose` (with a hyphen) instead.

### Building the Docker Image

```bash
# Build the image
docker build -t hgnc-mcp:latest .

# Run the container
docker run -d \
  --name hgnc-mcp-server \
  -p 8080:8080 \
  -v hgnc-cache:/home/hgnc/.cache/hgnc \
  hgnc-mcp:latest

# Check logs
docker logs -f hgnc-mcp-server

# Stop and remove
docker stop hgnc-mcp-server
docker rm hgnc-mcp-server
```

## Advanced Deployments

### Production with Nginx Proxy

The advanced compose file includes an Nginx reverse proxy with rate limiting and HTTPS support:

```bash
cd examples/docker

# Start production stack
docker compose -f docker-compose.advanced.yml --profile production up -d

# Access via proxy
curl http://localhost/tools/info
```

### Development Mode

For development with hot reload:

```bash
cd examples/docker

# Start development server
docker compose -f docker-compose.advanced.yml --profile dev up

# Make changes to R code and restart container to reload
```

## Configuration

### Environment Variables

Set these in a `.env` file or pass via `-e` flag:

- `HGNC_PORT` - Port to expose (default: 8080)
- `HGNC_CACHE_DIR` - Cache directory path (default: /home/hgnc/.cache/hgnc)
- `R_LIBS_USER` - R library path (default: /usr/local/lib/R/site-library)

Example `.env` file:

```bash
HGNC_PORT=9090
TZ=America/New_York
```

### Volume Mounts

#### Cache Persistence

The cache volume persists HGNC data across container restarts:

```yaml
volumes:
  - hgnc-cache:/home/hgnc/.cache/hgnc
```

#### Pre-loaded Cache

To use a pre-downloaded cache:

```bash
# Download cache locally
mkdir -p data
# ... download hgnc_complete_set.txt to data/

# Mount as read-only
docker run -v $(pwd)/data:/home/hgnc/.cache/hgnc:ro hgnc-mcp:latest
```

## Health Checks

The container includes health checks that verify the server is responding:

```bash
# Check health status
docker inspect --format='{{.State.Health.Status}}' hgnc-mcp-server

# View health check logs
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' hgnc-mcp-server
```

## Resource Limits

Recommended resource limits:

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 4G
    reservations:
      cpus: '0.5'
      memory: 1G
```

## Networking

### Default Bridge Network

The default docker-compose setup uses a bridge network for container communication.

### Custom Networks

For integration with other services:

```yaml
networks:
  default:
    external: true
    name: my-network
```

## Security Considerations

1. **Non-root User**: Container runs as user `hgnc` (UID 1000)
2. **Read-only Filesystem**: Consider adding `read_only: true` with tmpfs mounts
3. **Network Isolation**: Use internal networks for backend services
4. **TLS/HTTPS**: Configure Nginx with SSL certificates for production
5. **Rate Limiting**: Nginx configuration includes rate limiting (10 req/s)
6. **Secrets Management**: Use Docker secrets or environment files for sensitive data

## Troubleshooting

### Container won't start

```bash
# Check logs
docker logs hgnc-mcp-server

# Inspect container
docker inspect hgnc-mcp-server

# Test R dependencies
docker run --rm hgnc-mcp:latest Rscript -e "library(hgnc.mcp); packageVersion('hgnc.mcp')"
```

### Port already in use

```bash
# Check what's using the port
lsof -i :8080

# Use a different port
docker run -p 9090:8080 hgnc-mcp:latest
```

### Cache not persisting

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect hgnc-cache

# Remove and recreate
docker compose down -v
docker compose up -d
```

### Out of memory

```bash
# Increase memory limit
docker update --memory="4g" hgnc-mcp-server

# Or in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 4G
```

## Performance Tuning

### Optimize R Startup

Pre-compile packages in the Docker image:

```dockerfile
RUN R -e "compiler::enableJIT(3); hgnc.mcp::load_hgnc_data()"
```

### Use Build Cache

Speed up rebuilds with BuildKit:

```bash
DOCKER_BUILDKIT=1 docker build -t hgnc-mcp:latest .
```

### Multi-stage Build

The Dockerfile uses multi-stage builds to minimize image size. Final image is ~500MB vs 1.2GB for single-stage build.

## CI/CD Integration

See `.github/workflows/docker-build.yml` for GitHub Actions example.

## Support

For issues and questions:
- GitHub: https://github.com/armish/hgnc.mcp/issues
- Documentation: See main README.md
