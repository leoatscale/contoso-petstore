using Microsoft.AspNetCore.Mvc;
using ContosoPetStore.Services;

namespace ContosoPetStore.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    private readonly IHealthCheckService _healthService;

    public HealthController(IHealthCheckService healthService)
    {
        _healthService = healthService;
    }

    /// <summary>
    /// Liveness probe for Kubernetes
    /// </summary>
    [HttpGet("live")]
    public ActionResult Live() => Ok(new { status = "alive" });

    /// <summary>
    /// Readiness probe for Kubernetes with detailed status
    /// </summary>
    [HttpGet("ready")]
    public ActionResult Ready()
    {
        var status = _healthService.GetStatus();
        return Ok(status);
    }
}
