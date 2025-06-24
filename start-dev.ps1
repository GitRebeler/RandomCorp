# Development deployment script for Docker Desktop
Write-Host "🚀 Starting RandomCorp in Development mode..." -ForegroundColor Green
Write-Host "📋 Using development configuration with local database" -ForegroundColor Yellow

# Stop any existing containers
docker-compose down

# Start development environment
docker-compose --env-file .env.dev up --build

Write-Host "✅ Development environment started!" -ForegroundColor Green
Write-Host "🌐 Frontend: http://localhost:3000" -ForegroundColor Cyan
Write-Host "🔌 API: http://localhost:8000" -ForegroundColor Cyan
Write-Host "🗄️ Database: localhost:1433" -ForegroundColor Cyan
