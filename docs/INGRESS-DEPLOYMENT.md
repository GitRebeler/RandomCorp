# RandomCorp Ingress-Based Deployment Guide

This guide explains how to deploy RandomCorp using NGINX Ingress Controller, which eliminates the need for the two-step build process.

## Benefits of Ingress-Based Deployment

✅ **Single deployment step** - No more rebuilding frontend after LoadBalancer IP assignment
✅ **Predictable URLs** - Use domain names instead of IP addresses
✅ **HTTPS support** - Easy SSL/TLS with Let's Encrypt
✅ **Better performance** - Same-origin requests eliminate CORS issues
✅ **Professional setup** - Production-ready configuration

## Quick Start

### Basic Deployment (Local Testing)

```powershell
# Deploy with default settings (uses randomcorp.local)
.\build-cluster-deploy-app-ingress.ps1
```

### Production Deployment

```powershell
# Deploy with custom domain
.\build-cluster-deploy-app-ingress.ps1 -Domain "randomcorp.com"

# Deploy with HTTPS
.\build-cluster-deploy-app-ingress.ps1 -Domain "randomcorp.com" -UseHTTPS -Email "admin@example.com"
```

### Step-by-Step Deployment

```powershell
# 1. Create LKE cluster (if needed)
.\infra\linode\create-lke-cluster.ps1

# 2. Setup NGINX Ingress Controller
.\infra\linode\setup-ingress.ps1 -Domain "randomcorp.local"

# 3. Build images with ingress configuration
.\build-lke-images.ps1 -ApiUrl "/api"

# 4. Deploy application
.\infra\linode\deploy-app.ps1
```

## Configuration Details

### Ingress Configuration

The ingress is configured with path-based routing:

- `/api/*` → RandomCorp API service
- `/*` → RandomCorp Frontend service

### API URL Configuration

With ingress, the frontend uses relative URLs:

```typescript
// Frontend configuration
REACT_APP_API_URL="/api"

// Results in API calls to:
// https://yourdomain.com/api/submit
// https://yourdomain.com/api/health
```

### HTTPS Setup

When using `-UseHTTPS`:

1. cert-manager is installed automatically
2. Let's Encrypt ClusterIssuer is created
3. TLS certificates are requested automatically
4. HTTPS redirect is enabled

## DNS Configuration

### For Local Testing (.local domains)

Add to your hosts file:
```
139.144.xxx.xxx randomcorp.local
```

**Windows:** `C:\Windows\System32\drivers\etc\hosts`
**Linux/Mac:** `/etc/hosts`

### For Production Domains

Create DNS A record:
```
randomcorp.com → 139.144.xxx.xxx
```

## Troubleshooting

### Check Ingress Controller Status

```powershell
kubectl get pods -n ingress-nginx
kubectl get service ingress-nginx-controller -n ingress-nginx
```

### Check Application Status

```powershell
kubectl get pods
kubectl get services
kubectl get ingress
```

### View Logs

```powershell
# Ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Application logs
kubectl logs deployment/randomcorp-api
kubectl logs deployment/randomcorp-frontend
```

### Common Issues

1. **"Connection refused" errors**
   - Check if ingress controller is running
   - Verify LoadBalancer IP is assigned

2. **404 errors for API calls**
   - Check ingress path configuration
   - Verify service names match ingress backend

3. **HTTPS certificate issues**
   - Check cert-manager pods are running
   - Verify ClusterIssuer is ready
   - Check certificate status: `kubectl get certificates`

## Migration from LoadBalancer Setup

If you're migrating from the old LoadBalancer setup:

1. **Update values.yaml:**
   ```yaml
   # Change from LoadBalancer to ClusterIP
   service:
     type: ClusterIP
   
   # Enable ingress
   ingress:
     enabled: true
   ```

2. **Rebuild images with new API URL:**
   ```powershell
   .\build-lke-images.ps1 -ApiUrl "/api"
   ```

3. **Deploy with ingress:**
   ```powershell
   .\build-cluster-deploy-app-ingress.ps1
   ```

## Advanced Configuration

### Custom Ingress Annotations

Edit `helm-charts/randomcorp/values.yaml`:

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/proxy-body-size: "8m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
```

### Multiple Domains

```yaml
ingress:
  hosts:
    - host: randomcorp.com
      paths: [...]
    - host: www.randomcorp.com
      paths: [...]
```

---

## Next Steps

After successful deployment:

1. Configure monitoring and logging
2. Set up automated backups
3. Configure CI/CD pipelines
4. Implement security policies

For more information, see the main [README.md](../README.md).
