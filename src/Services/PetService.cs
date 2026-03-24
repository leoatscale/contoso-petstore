using ContosoPetStore.Models;

namespace ContosoPetStore.Services;

public interface IPetService
{
    IEnumerable<Pet> GetAll();
    Pet? GetById(int id);
    Pet Create(PetCreateRequest request);
    Pet? Update(int id, PetCreateRequest request);
    bool Delete(int id);
    IEnumerable<Pet> Search(string? species, decimal? maxPrice);
}

public class PetService : IPetService
{
    private readonly List<Pet> _pets = new()
    {
        new Pet { Id = 1, Name = "Buddy", Species = "Dog", Breed = "Golden Retriever", Age = 3, Price = 499.99m },
        new Pet { Id = 2, Name = "Whiskers", Species = "Cat", Breed = "Persian", Age = 2, Price = 299.99m },
        new Pet { Id = 3, Name = "Rex", Species = "Dog", Breed = "German Shepherd", Age = 4, Price = 599.99m },
        new Pet { Id = 4, Name = "Nemo", Species = "Fish", Breed = "Clownfish", Age = 1, Price = 29.99m },
        new Pet { Id = 5, Name = "Luna", Species = "Cat", Breed = "Siamese", Age = 1, Price = 349.99m },
    };

    private int _nextId = 6;

    public IEnumerable<Pet> GetAll() => _pets.Where(p => p.Available);

    public Pet? GetById(int id) => _pets.FirstOrDefault(p => p.Id == id);

    public Pet Create(PetCreateRequest request)
    {
        var pet = new Pet
        {
            Id = _nextId++,
            Name = request.Name,
            Species = request.Species,
            Breed = request.Breed,
            Age = request.Age,
            Price = request.Price
        };
        _pets.Add(pet);
        return pet;
    }

    public Pet? Update(int id, PetCreateRequest request)
    {
        var pet = GetById(id);
        if (pet == null) return null;

        pet.Name = request.Name;
        pet.Species = request.Species;
        pet.Breed = request.Breed;
        pet.Age = request.Age;
        pet.Price = request.Price;
        return pet;
    }

    public bool Delete(int id)
    {
        var pet = GetById(id);
        if (pet == null) return false;
        pet.Available = false;
        return true;
    }

    public IEnumerable<Pet> Search(string? species, decimal? maxPrice)
    {
        var query = _pets.Where(p => p.Available);
        if (!string.IsNullOrEmpty(species))
            query = query.Where(p => p.Species.Equals(species, StringComparison.OrdinalIgnoreCase));
        if (maxPrice.HasValue)
            query = query.Where(p => p.Price <= maxPrice.Value);
        return query;
    }
}
