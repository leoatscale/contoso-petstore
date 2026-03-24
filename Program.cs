using ContosoPetStore.Services;
using ContosoPetStore.Middleware;

var builder = WebApplication.CreateBuilder(args);

// Application Insights
builder.Services.AddApplicationInsightsTelemetry();

// Services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddSingleton<IPetService, PetService>();
builder.Services.AddSingleton<IHealthCheckService, HealthCheckService>();

// CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

var app = builder.Build();

// Middleware pipeline
app.UseSwagger();
app.UseSwaggerUI();
app.UseCors();
app.UseMiddleware<RequestLoggingMiddleware>();
app.MapControllers();

app.Run();
