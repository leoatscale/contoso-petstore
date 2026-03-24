using Microsoft.AspNetCore.Mvc;
using ContosoPetStore.Models;
using ContosoPetStore.Services;

namespace ContosoPetStore.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PetsController : ControllerBase
{
    private readonly IPetService _petService;
    private readonly ILogger<PetsController> _logger;

    public PetsController(IPetService petService, ILogger<PetsController> logger)
    {
        _petService = petService;
        _logger = logger;
    }

    /// <summary>
    /// Get all available pets
    /// </summary>
    [HttpGet]
    public ActionResult<IEnumerable<Pet>> GetAll()
    {
        _logger.LogInformation("Fetching all pets");
        return Ok(_petService.GetAll());
    }

    /// <summary>
    /// Get a pet by ID
    /// </summary>
    [HttpGet("{id}")]
    public ActionResult<Pet> GetById(int id)
    {
        var pet = _petService.GetById(id);
        if (pet == null)
        {
            _logger.LogWarning("Pet {PetId} not found", id);
            return NotFound(new { message = $"Pet with ID {id} not found" });
        }
        return Ok(pet);
    }

    /// <summary>
    /// Create a new pet listing
    /// </summary>
    [HttpPost]
    public ActionResult<Pet> Create([FromBody] PetCreateRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
            return BadRequest(new { message = "Pet name is required" });

        var pet = _petService.Create(request);
        _logger.LogInformation("Created pet {PetId}: {PetName}", pet.Id, pet.Name);
        return CreatedAtAction(nameof(GetById), new { id = pet.Id }, pet);
    }

    /// <summary>
    /// Update a pet listing
    /// </summary>
    [HttpPut("{id}")]
    public ActionResult<Pet> Update(int id, [FromBody] PetCreateRequest request)
    {
        var pet = _petService.Update(id, request);
        if (pet == null)
            return NotFound(new { message = $"Pet with ID {id} not found" });

        _logger.LogInformation("Updated pet {PetId}", id);
        return Ok(pet);
    }

    /// <summary>
    /// Delete (soft) a pet listing
    /// </summary>
    [HttpDelete("{id}")]
    public ActionResult Delete(int id)
    {
        if (!_petService.Delete(id))
            return NotFound(new { message = $"Pet with ID {id} not found" });

        _logger.LogInformation("Deleted pet {PetId}", id);
        return NoContent();
    }

    /// <summary>
    /// Search pets by species and/or max price
    /// </summary>
    [HttpGet("search")]
    public ActionResult<IEnumerable<Pet>> Search(
        [FromQuery] string? species,
        [FromQuery] decimal? maxPrice)
    {
        var results = _petService.Search(species, maxPrice);
        return Ok(results);
    }
}
