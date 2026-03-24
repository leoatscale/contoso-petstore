namespace ContosoPetStore.Services;

public interface IHealthCheckService
{
    HealthStatus GetStatus();
}

public class HealthCheckService : IHealthCheckService
{
    private readonly DateTime _startTime = DateTime.UtcNow;

    public HealthStatus GetStatus()
    {
        return new HealthStatus
        {
            Status = "Healthy",
            Uptime = DateTime.UtcNow - _startTime,
            Version = Environment.GetEnvironmentVariable("APP_VERSION") ?? "1.0.0",
            Environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production"
        };
    }
}

public class HealthStatus
{
    public string Status { get; set; } = "Healthy";
    public TimeSpan Uptime { get; set; }
    public string Version { get; set; } = "1.0.0";
    public string Environment { get; set; } = "Production";
}
