# Information about Linode Container Registry options for Random Corp

Write-Host "=== Linode Container Registry Options ===" -ForegroundColor Green
Write-Host ""

Write-Host "1. LINODE CONTAINER REGISTRY (LCR) - Official" -ForegroundColor Cyan
Write-Host "   Status: Beta/Limited Availability" -ForegroundColor Yellow
Write-Host "   - Private registry integrated with Linode" 
Write-Host "   - Currently in beta - limited access"
Write-Host "   - Pricing: Free during beta, TBA for GA"
Write-Host "   - Request access: https://www.linode.com/products/container-registry/"
Write-Host ""

Write-Host "2. DOCKER HUB - Recommended for getting started" -ForegroundColor Cyan
Write-Host "   Cost: Free (public repos) / `$5/month (private repos)" -ForegroundColor Green
Write-Host "   - Most popular container registry"
Write-Host "   - Easy integration with LKE"
Write-Host "   - Already configured in your values.yaml"
Write-Host "   - Sign up: https://hub.docker.com"
Write-Host ""

Write-Host "3. GITHUB CONTAINER REGISTRY (ghcr.io)" -ForegroundColor Cyan
Write-Host "   Cost: Free" -ForegroundColor Green
Write-Host "   - Integrated with GitHub repos"
Write-Host "   - Private registries included"
Write-Host "   - Good for CI/CD with GitHub Actions"
Write-Host "   - URL: ghcr.io/gitrebeler/randomcorp"
Write-Host ""

Write-Host "4. SELF-HOSTED HARBOR ON LINODE" -ForegroundColor Cyan
Write-Host "   Cost: ~`$10-15/month (Linode + Object Storage)" -ForegroundColor Yellow
Write-Host "   - Full-featured enterprise registry"
Write-Host "   - Vulnerability scanning"
Write-Host "   - Complete control and privacy"
Write-Host "   - Uses Linode Object Storage as backend"
Write-Host ""

Write-Host "=== RECOMMENDATION FOR RANDOM CORP ===" -ForegroundColor Green
Write-Host ""
Write-Host "For getting started quickly:" -ForegroundColor Yellow
Write-Host "  Use Docker Hub (already configured)" -ForegroundColor Green
Write-Host "   - Fast setup"
Write-Host "   - Reliable and well-integrated"
Write-Host "   - Free public repos"
Write-Host ""
Write-Host "For production/enterprise:" -ForegroundColor Yellow
Write-Host "  Consider Linode Container Registry when available" -ForegroundColor Cyan
Write-Host "   - Better integration with Linode infrastructure"
Write-Host "   - Potentially lower latency"
Write-Host "   - Unified billing"
Write-Host ""

Write-Host "=== CURRENT SETUP ===" -ForegroundColor Cyan
Write-Host "Your values.yaml is configured for:" -ForegroundColor White
Write-Host "   - docker.io/gitrebeler/randomcorp" -ForegroundColor Gray
Write-Host "   - docker.io/gitrebeler/randomcorp-frontend" -ForegroundColor Gray
Write-Host ""
Write-Host "Ready to build and push:" -ForegroundColor Green
Write-Host "   .\setup-docker-hub.ps1" -ForegroundColor White

Write-Host ""
Write-Host "=== NEXT STEPS ===" -ForegroundColor Yellow
Write-Host "1. Build and push images: .\setup-docker-hub.ps1" -ForegroundColor White
Write-Host "2. Deploy to cluster: .\deploy-app.ps1" -ForegroundColor White
Write-Host "3. Setup GitOps: .\install-flux.ps1" -ForegroundColor White
