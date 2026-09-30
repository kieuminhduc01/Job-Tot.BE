using JobTot.Domain.Entities;

namespace JobTot.Domain.Tests;

public sealed class JobPostTests
{
    [Theory]
    [InlineData(-1, 100)]
    [InlineData(200, 100)]
    public void RejectsInvalidSalary(decimal min, decimal max)
        => Assert.Throws<ArgumentException>(() => Create(min, max));
    [Fact]
    public void CannotEditClosedJob()
    {
        var job = Create();
        job.Close();
        Assert.Throws<InvalidOperationException>(() => job.Update("New title", "Description", "Hanoi",
            null, null, DateTimeOffset.UtcNow.AddDays(1)));
    }
    [Fact]
    public void RejectsExpiredJob()
        => Assert.Throws<ArgumentException>(() => new JobPost(Guid.NewGuid(), "Developer", "Description",
            "Hanoi", null, null, DateTimeOffset.UtcNow.AddDays(-1)));
    [Fact]
    public void AllowsNegotiableSalaryAndTrimsTitle()
    {
        var job = Create();
        Assert.Null(job.SalaryMin);
        Assert.Equal("Developer", job.Title);
        Assert.False(job.IsClosed);
    }
    private static JobPost Create(decimal? min = null, decimal? max = null)
        => new(Guid.NewGuid(), " Developer ", "Description", "Hanoi", min, max, DateTimeOffset.UtcNow.AddDays(30));
}
