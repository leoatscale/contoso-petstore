namespace ContosoPetStore.Models;

public class Pet
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Species { get; set; } = string.Empty;
    public string Breed { get; set; } = string.Empty;
    public int Age { get; set; }
    public decimal Price { get; set; }
    public bool Available { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class PetCreateRequest
{
    public string Name { get; set; } = string.Empty;
    public string Species { get; set; } = string.Empty;
    public string Breed { get; set; } = string.Empty;
    public int Age { get; set; }
    public decimal Price { get; set; }
}
