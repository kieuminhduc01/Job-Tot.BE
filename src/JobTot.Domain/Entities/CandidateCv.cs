namespace JobTot.Domain.Entities;

public sealed class CandidateCv : AuditableEntity
{
    public Guid CandidateId { get; set; }
    public CandidateProfile Candidate { get; set; } = null!;
    public Guid? CvTemplateId { get; set; }
    public CvTemplate? CvTemplate { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? FileUrl { get; set; }
    public string? ContentJson { get; set; }
    public bool IsDefault { get; set; }
    public ICollection<JobApplication> JobApplications { get; set; } = new List<JobApplication>();
}
