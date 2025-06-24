# Random Corp Web Application

A modern web application built with React, Material UI, and FastAPI, styled similar to Microsoft Learn.

## Features

- **React Frontend**: Built with TypeScript and Material UI
- **Python API**: FastAPI backend for processing submissions
- **Microsoft Learn Styling**: Clean, modern design inspired by learn.microsoft.com
- **Docker Support**: Full containerization with Docker Compose
- **Form Validation**: Client and server-side validation
- **Responsive Design**: Works on desktop and mobile devices
- **Multi-Environment Support**: Separate configurations for development and production

## Quick Start

### Development (Docker Desktop)
```bash
# Using the convenience script
.\start-dev.ps1

# Or manually
docker-compose --env-file .env.dev up --build
```

### Production (LKE/Kubernetes)
```bash
# Using the convenience script
.\start-prod.ps1

# Or manually
docker-compose -f docker-compose.prod.yml --env-file .env.prod up --build -d
```

## Environment Configurations

The application supports multiple deployment environments:

- **Development** (`docker-compose.yml`): 
  - Frontend runs on `http://localhost:3000` (mapped from container port 80)
  - API runs on `http://localhost:8000`
  - Local SQL Server database
  - Hot reload for development
  
- **Production** (`docker-compose.prod.yml`):
  - Optimized for Kubernetes/LKE deployment
  - Environment variables for external database connection
  - No development volumes mounted
  - Production-ready configuration

## Project Structure

```
RandomCorp/
├── src/                    # React frontend source
│   ├── App.tsx            # Main application component
│   ├── index.tsx          # Application entry point
│   └── index.css          # Global styles
├── api/                   # Python API
│   ├── main.py           # FastAPI application
│   ├── requirements.txt  # Python dependencies
│   └── Dockerfile        # API Docker configuration
├── public/               # Static assets
├── package.json          # Frontend dependencies
├── Dockerfile           # Frontend Docker configuration
├── docker-compose.yml   # Development configuration
├── docker-compose.dev.yml   # Development configuration (explicit)
├── docker-compose.prod.yml  # Production configuration
├── .env.dev             # Development environment variables
├── .env.prod            # Production environment variables
├── start-dev.ps1        # Development startup script
├── start-prod.ps1       # Production startup script
└── README.md           # This file
```

## Quick Start with Docker

1. **Prerequisites**
   - Docker Desktop installed and running
   - Git (optional, for cloning)

2. **Run the application**
   ```bash
   docker-compose up --build
   ```

3. **Access the application**
   - Frontend: http://localhost:3000
   - API: http://localhost:8000
   - API Documentation: http://localhost:8000/docs

## Development Setup

### Frontend Development

1. **Install Node.js dependencies**
   ```bash
   npm install
   ```

2. **Start development server**
   ```bash
   npm start
   ```

3. **Available Scripts**
   - `npm start` - Start development server
   - `npm build` - Build for production
   - `npm test` - Run tests

### API Development

1. **Create virtual environment**
   ```bash
   cd api
   python -m venv venv
   venv\Scripts\activate  # Windows
   # source venv/bin/activate  # Linux/Mac
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the API**
   ```bash
   python main.py
   ```

## Technology Stack

### Frontend
- **React 18** - UI library
- **TypeScript** - Type safety
- **Material UI 5** - Component library
- **Emotion** - CSS-in-JS styling

### Backend
- **FastAPI** - Modern Python web framework
- **Pydantic** - Data validation
- **Uvicorn** - ASGI server

### DevOps
- **Docker** - Containerization
- **Docker Compose** - Multi-container orchestration

## API Endpoints

- `GET /` - Health check
- `GET /health` - Health status
- `POST /api/submit` - Submit first/last name
- `GET /api/stats` - API statistics
- `GET /docs` - Interactive API documentation

## Design Features

The application is styled to match Microsoft Learn with:

- **Color Scheme**: Microsoft blue (#0078d4) primary, grey secondary
- **Typography**: Segoe UI font family
- **Layout**: Clean, professional design with proper spacing
- **Components**: Material UI components with custom theming
- **Logo**: Grey "RC" logo representing Random Corp
- **Responsive**: Mobile-friendly design

## Docker Commands

### Build and run
```bash
docker-compose up --build
```

### Run in background
```bash
docker-compose up -d
```

### Stop services
```bash
docker-compose down
```

### View logs
```bash
docker-compose logs -f
```

### Rebuild specific service
```bash
docker-compose build frontend
docker-compose build api
```

## Environment Variables

### Frontend
- `REACT_APP_API_URL` - API base URL (default: http://localhost:8000)

### API
- `PYTHONUNBUFFERED` - Disable Python output buffering

## Troubleshooting

### Common Issues

1. **Port conflicts**
   - Ensure ports 3000 and 8000 are available
   - Modify ports in docker-compose.yml if needed

2. **Docker build issues**
   - Clear Docker cache: `docker system prune`
   - Rebuild images: `docker-compose build --no-cache`

3. **API connection issues**
   - Check that both services are running
   - Verify CORS configuration in API

### Development Tips

1. **Hot reload is enabled** for both frontend and API during development
2. **API documentation** is available at http://localhost:8000/docs
3. **Browser DevTools** can be used to debug the React application
4. **Logs** are available through `docker-compose logs`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is for demonstration purposes.

---

© 2025 Random Corp. Built with ❤️ using React and FastAPI.
