## Project Context
This is the Contoso Pet Store API, a .NET 8 REST API for managing pet listings.

## Code Style
- Use C# 12 features (primary constructors, collection expressions)
- Follow Microsoft's .NET naming conventions
- Use async/await for all I/O operations
- Always use dependency injection
- Add XML doc comments on public methods

## Architecture
- Controllers handle HTTP, delegate to Services
- Services contain business logic
- Models are simple POCOs
- Use the Result pattern for error handling

## Security
- Never hardcode secrets; use Azure Key Vault or environment variables
- Always validate and sanitize user input
- Use parameterized queries for any database access
- Follow OWASP Top 10 guidelines

## Testing
- Use xUnit for unit tests
- Use FluentAssertions for readable assertions
- Aim for 80%+ code coverage on Services
