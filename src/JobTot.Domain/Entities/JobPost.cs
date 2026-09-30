namespace JobTot.Domain.Entities;

public sealed class JobPost
{
    private JobPost() { }
    public JobPost(Guid companyId, string title, string description, string location,
        decimal? salaryMin, decimal? salaryMax, DateTimeOffset expiresAt)
    {
        if (companyId == Guid.Empty) throw new ArgumentException("Company is required.");
        CompanyId = companyId;
        Update(title, description, location, salaryMin, salaryMax, expiresAt);
    }

    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid CompanyId { get; private set; }
    public string Title { get; private set; } = string.Empty;
    public string Description { get; private set; } = string.Empty;
    public string Location { get; private set; } = string.Empty;
    public decimal? SalaryMin { get; private set; }
    public decimal? SalaryMax { get; private set; }
    public DateTimeOffset CreatedAt { get; private set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset ExpiresAt { get; private set; }
    public bool IsClosed { get; private set; }

    public void Update(string title, string description, string location,
        decimal? salaryMin, decimal? salaryMax, DateTimeOffset expiresAt)
    {
        if (IsClosed) throw new InvalidOperationException("Closed jobs cannot be edited.");
        if (string.IsNullOrWhiteSpace(title) || title.Trim().Length > 200)
            throw new ArgumentException("Title must contain 1-200 characters.");
        if (string.IsNullOrWhiteSpace(description) || description.Length > 10000)
            throw new ArgumentException("Description must contain 1-10000 characters.");
        if (string.IsNullOrWhiteSpace(location) || location.Trim().Length > 200)
            throw new ArgumentException("Location must contain 1-200 characters.");
        if (salaryMin < 0 || salaryMax < 0 || salaryMin > salaryMax ||
            salaryMin > 9999999999999999.99m || salaryMax > 9999999999999999.99m)
            throw new ArgumentException("Invalid salary range.");
        if (expiresAt <= DateTimeOffset.UtcNow) throw new ArgumentException("Expiry must be in the future.");
        Title = title.Trim(); Description = description; Location = location.Trim();
        SalaryMin = salaryMin; SalaryMax = salaryMax; ExpiresAt = expiresAt;
    }

    public void Close() => IsClosed = true;
}
