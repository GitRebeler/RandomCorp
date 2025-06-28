# GitHub Copilot Instructions for RandomCorp

## Project Overview
RandomCorp is a modern web application built with:
- **Backend**: FastAPI (Python) with SQL Server database
- **Frontend**: React with TypeScript
- **Infrastructure**: Kubernetes deployment on Linode LKE
- **GitOps**: Flux CD for automated deployments
- **Containerization**: Docker with multi-stage builds

## Code Style and Standards

### Python (API)
- Use FastAPI with async/await patterns
- Follow PEP 8 style guidelines
- Use type hints for all function parameters and return values
- Implement proper error handling with custom exception classes
- Use Pydantic models for request/response validation
- Structure code with clear separation of concerns (routes, services, models)

### TypeScript/React (Frontend)
- Use functional components with React hooks
- Implement proper TypeScript interfaces and types
- Follow React best practices for state management
- Use consistent naming conventions (camelCase for variables, PascalCase for components)
- Implement proper error boundaries and loading states

### Docker
- Use multi-stage builds for optimization
- Follow security best practices (non-root users, minimal base images)
- Optimize layer caching for faster builds
- Include health checks in Dockerfiles

### Kubernetes/Helm
- Use semantic versioning for chart versions
- Implement proper resource limits and requests
- Follow Kubernetes security best practices
- Use ConfigMaps and Secrets appropriately
- Implement proper readiness and liveness probes

## Architecture Patterns

### API Design
- RESTful endpoints with proper HTTP methods
- Consistent response formats with proper status codes
- Implement pagination for list endpoints
- Use proper authentication and authorization
- Include comprehensive error handling

### Database
- Use async database operations with aioodbc
- Implement proper connection pooling
- Follow database naming conventions (snake_case)
- Use prepared statements to prevent SQL injection
- Implement proper transaction handling

### Deployment
- GitOps workflow with Flux CD
- Automated CI/CD with proper testing stages
- Environment-specific configurations
- Proper secret management
- Rolling deployments with zero downtime

## Security Considerations
- Never commit secrets or credentials
- Use environment variables for configuration
- Implement proper CORS policies
- Validate all user inputs
- Use HTTPS in production
- Implement rate limiting and authentication

## Development Workflow
- Use feature branches with descriptive names
- Write meaningful commit messages
- Include unit tests for new functionality
- Update documentation when needed
- Follow the existing project structure

## File Structure
```
RandomCorp/
├── api/                    # FastAPI backend
├── frontend/              # React frontend
├── helm-charts/           # Helm charts for Kubernetes
├── infra/                 # Infrastructure scripts
├── .github/               # GitHub workflows and configs
└── docs/                  # Project documentation
```

## Common Tasks
When suggesting code:
- Ensure compatibility with the existing codebase
- Follow the established patterns and conventions
- Include proper error handling and logging
- Consider performance and scalability
- Add appropriate comments for complex logic
- Suggest improvements for code maintainability

## Testing
- Write unit tests for business logic
- Include integration tests for API endpoints
- Test containerized applications
- Validate Kubernetes manifests
- Test deployment scripts

Remember to prioritize code quality, security, and maintainability in all suggestions.
