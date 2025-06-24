# RandomCorp Deployment Guide

This document explains how to deploy the RandomCorp application in different environments.

## Environment Configurations

### Development Environment (Docker Desktop)
**File**: `docker-compose.yml` or `docker-compose.dev.yml`
**Purpose**: Local development with hot reloading and development databases

**Key Features**:
- Port mapping: `3000:80` (Host port 3000 → Container nginx port 80)
- API URL: `http://localhost:8000` (accessible from browser)
- Local SQL Server database
- Development volumes mounted for hot reloading
- Debug mode enabled

**Start Command**:
```powershell
# Using convenience script
.\start-dev.ps1

# Or manually
docker-compose --env-file .env.dev up --build

# Or using explicit dev file
docker-compose -f docker-compose.dev.yml --env-file .env.dev up --build
```

**Access URLs**:
- Frontend: http://localhost:3000
- API: http://localhost:8000
- Database: localhost:1433

### Production Environment (LKE/Kubernetes)
**File**: `docker-compose.prod.yml`
**Purpose**: Production deployment optimized for Kubernetes

**Key Features**:
- Environment variables for external services
- No development volumes (everything baked into images)
- Production-ready database connections
- Configurable API URLs via environment variables

**Start Command**:
```powershell
# Using convenience script
.\start-prod.ps1

# Or manually
docker-compose -f docker-compose.prod.yml --env-file .env.prod up --build -d
```

## Port Mapping Explanation

### Why Different Port Mappings?

**Development (Docker Desktop)**:
- The React app is built and served by nginx inside the container
- Nginx runs on port 80 inside the container
- We map host port 3000 to container port 80: `3000:80`
- This allows `http://localhost:3000` to reach the nginx server

**LKE/Kubernetes**:
- Kubernetes handles service discovery and port mapping
- The port mapping in docker-compose.prod.yml is more for documentation
- Actual ports are managed by Kubernetes services and ingress controllers

## Environment Variables

### Development (.env.dev)
```
REACT_APP_API_URL=http://localhost:8000
DB_HOST=sqlserver
DB_PORT=1433
DB_NAME=RandomCorpDB
DB_USER=sa
DB_PASSWORD=RandomCorp123!
SA_PASSWORD=RandomCorp123!
DEBUG=true
```

### Production (.env.prod)
```
REACT_APP_API_URL=https://api.randomcorp.com
DB_HOST=your-production-db-host
DB_PORT=1433
DB_NAME=RandomCorpDB
DB_USER=your-production-user
DB_PASSWORD=your-production-password
SA_PASSWORD=your-production-password
DEBUG=false
```

## Frontend API Configuration

The frontend automatically uses the correct API URL based on the `REACT_APP_API_URL` environment variable:

```typescript
// src/config/api.ts
export const getApiBaseUrl = (): string => {
  return process.env.REACT_APP_API_URL || '';
};
```

During the Docker build process, this environment variable is baked into the React build, so the frontend knows where to send API requests.

## Troubleshooting

### Frontend Not Accessible
- Check port mapping: Should be `3000:80` for development
- Verify container is running: `docker-compose ps`
- Check nginx logs: `docker-compose logs frontend`

### API Communication Issues
- Verify API is accessible: `curl http://localhost:8000/health`
- Check CORS configuration in backend
- Verify environment variable is correctly set in frontend build

### Database Connection Issues
- Check database container health: `docker-compose ps`
- Verify environment variables match between services
- Check database logs: `docker-compose logs sqlserver`

## Best Practices

1. **Always use environment-specific files** for deployment
2. **Never commit production secrets** to version control
3. **Test both environments** before deploying to production
4. **Use the convenience scripts** for consistent deployments
5. **Monitor container health** with `docker-compose ps`

## Quick Commands

```powershell
# Start development environment
.\start-dev.ps1

# Start production environment
.\start-prod.ps1

# Stop all containers
docker-compose down

# View logs
docker-compose logs

# Check container status
docker-compose ps

# Rebuild without cache
docker-compose build --no-cache
```
