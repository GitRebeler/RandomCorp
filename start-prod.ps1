# Production deployment script
Write-Host "🚀 Starting RandomCorp in Production mode..." -ForegroundColor Green
Write-Host "📋 Using production configuration" -ForegroundColor Yellow

# Stop any existing containers
docker-compose -f docker-compose.prod.yml down

# Start production environment
docker-compose -f docker-compose.prod.yml --env-file .env.prod up --build -d

Write-Host "✅ Production environment started!" -ForegroundColor Green
Write-Host "🌐 Frontend: http://localhost:3000" -ForegroundColor Cyan
Write-Host "🔌 API: http://localhost:8000" -ForegroundColor Cyan
Write-Host "ℹ️ Running in detached mode. Use 'docker-compose -f docker-compose.prod.yml logs' to view logs" -ForegroundColor Yellow
