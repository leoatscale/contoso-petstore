// =============================================================================
// ⚠️  THIS FILE EXISTS ONLY FOR DEMO PURPOSES
// It contains INTENTIONAL vulnerabilities for GitHub Advanced Security to detect
// DO NOT use in production!
// =============================================================================

using Microsoft.AspNetCore.Mvc;
using System.Data.SqlClient;

namespace ContosoPetStore.Controllers;

/// <summary>
/// DEMO ONLY: Controller with intentional security vulnerabilities
/// Used to demonstrate GHAS CodeQL detection capabilities
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class DemoVulnerabilitiesController : ControllerBase
{
    // ── Vulnerability 1: SQL Injection ──────────────────────────────────────
    // CodeQL will flag: cs/sql-injection
    [HttpGet("search-unsafe")]
    public ActionResult UnsafeSearch([FromQuery] string name)
    {
        var connectionString = "Server=localhost;Database=pets;";
        using var connection = new SqlConnection(connectionString);
        // BAD: Direct string concatenation in SQL query
        var query = "SELECT * FROM Pets WHERE Name = '" + name + "'";
        using var command = new SqlCommand(query, connection);
        return Ok("This endpoint has a SQL injection vulnerability");
    }

    // ── Vulnerability 2: Hardcoded Credentials ─────────────────────────────
    // Secret scanning will flag this
    [HttpGet("config")]
    public ActionResult GetConfig()
    {
        // BAD: Hardcoded connection string with credentials
        var connectionString = "Server=tcp:petstore-prod.database.windows.net,1433;Database=petsdb;User ID=adminuser;Password=P@ssw0rd!2024Prod;Encrypt=true;";
        // BAD: Hardcoded API key (high entropy secret)
        var apiKey = "ghp_ABCDef1234567890abcdefGHIJKLMNOP12";
        return Ok(new { status = "configured" });
    }

    // ── Vulnerability 3: Path Traversal ────────────────────────────────────
    // CodeQL will flag: cs/path-injection
    [HttpGet("file")]
    public ActionResult ReadFile([FromQuery] string filename)
    {
        // BAD: User input directly in file path
        var content = System.IO.File.ReadAllText("/data/" + filename);
        return Ok(content);
    }

    // ── Vulnerability 4: Log Injection ──────────────────────────────────────
    // CodeQL will flag: cs/log-forging
    [HttpPost("log")]
    public ActionResult LogMessage([FromBody] string message)
    {
        // BAD: Unsanitized user input in log
        Console.WriteLine("User message: " + message);
        return Ok();
    }
}
