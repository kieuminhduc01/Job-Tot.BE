namespace JobTot.Domain.Entities;

public sealed class CvTemplate : AuditableEntity
{
    public string Name { get; set; } = string.Empty;
    public Guid CategoryId { get; set; }
    public CvCategory Category { get; set; } = null!;
    public string? PreviewUrl { get; set; }
    public ICollection<CandidateCv> CandidateCvs { get; set; } = new List<CandidateCv>();
}
