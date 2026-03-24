# 🐾 Contoso Pet Store API

A .NET 8 REST API demonstrating the full GitHub + Azure DevOps lifecycle.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Code** | .NET 8, ASP.NET Core |
| **AI Pair Programming** | GitHub Copilot |
| **Source Control** | GitHub |
| **CI/CD** | GitHub Actions |
| **Security** | GitHub Advanced Security (CodeQL, Secret Scanning, Dependency Review) |
| **Container Registry** | Azure Container Registry |
| **Orchestration** | Azure Kubernetes Service |
| **Monitoring** | Azure Application Insights |

## Quick Start

```bash
# Run locally
dotnet run

# Build container
docker build -t petstore-api .
docker run -p 8080:8080 petstore-api

# Setup Azure infrastructure
chmod +x scripts/setup-azure.sh
./scripts/setup-azure.sh
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/pets` | List all pets |
| GET | `/api/pets/{id}` | Get pet by ID |
| POST | `/api/pets` | Create a pet |
| PUT | `/api/pets/{id}` | Update a pet |
| DELETE | `/api/pets/{id}` | Delete a pet |
| GET | `/api/pets/search?species=Dog&maxPrice=500` | Search pets |
| GET | `/api/health/live` | Liveness probe |
| GET | `/api/health/ready` | Readiness probe |
| GET | `/swagger` | Swagger UI |

<!-- first deploy -->
