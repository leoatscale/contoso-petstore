# ============================================
# Stage 1: Build
# ============================================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore (layer caching)
COPY ContosoPetStore.csproj .
RUN dotnet restore

# Copy everything and build
COPY . .
RUN dotnet publish -c Release -o /app/publish --no-restore

# ============================================
# Stage 2: Runtime (minimal image)
# ============================================
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
WORKDIR /app

# Security: run as non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/api/health/live || exit 1

ENTRYPOINT ["dotnet", "ContosoPetStore.dll"]
