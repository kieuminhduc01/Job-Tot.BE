using System.Security.Claims;
using JobTot.Application.Profiles;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JobTot.Api.Controllers;

[ApiController]
[Route("api/candidate/profile")]
[Authorize(Policy = CandidateAuthentication.Policy)]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class CandidateProfileController(ICandidateProfileRepository repository) : ControllerBase
{
    private Guid AccountId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    [HttpGet]
    public async Task<ActionResult<CandidateProfileResponse>> Get(CancellationToken ct)
        => await repository.GetAsync(AccountId, ct) is { } p ? Ok(p) : NotFound();
    [HttpPut]
    public async Task<ActionResult<CandidateProfileResponse>> Put(CandidateProfileDocument document, CancellationToken ct)
        => await repository.SaveAsync(AccountId, document, ct) is { } p ? Ok(p) : NotFound();
    [HttpPost("cvs")]
    [RequestSizeLimit(6 * 1024 * 1024)]
    public async Task<ActionResult<ProfileCv>> Upload(IFormFile file, CancellationToken ct)
    {
        if (file.Length is <= 0 or > 5 * 1024 * 1024 || !string.Equals(Path.GetExtension(file.FileName), ".pdf", StringComparison.OrdinalIgnoreCase))
            return BadRequest(new ProblemDetails { Detail = "Chỉ chấp nhận PDF tối đa 5 MB." });
        using var buffer = new MemoryStream();
        await file.CopyToAsync(buffer, ct);
        var content = buffer.ToArray();
        if (content.Length < 5 || System.Text.Encoding.ASCII.GetString(content, 0, 5) != "%PDF-")
            return BadRequest(new ProblemDetails { Detail = "Nội dung tệp PDF không hợp lệ." });
        var name = Path.GetFileName(file.FileName);
        if (name.Length > 200) return BadRequest(new ProblemDetails { Detail = "Tên tệp quá dài." });
        return await repository.UploadCvAsync(AccountId, name, content, ct) is { } cv ? Ok(cv) : NotFound();
    }
    [HttpGet("cvs/{id:guid}")]
    public async Task<IActionResult> Download(Guid id, CancellationToken ct)
        => await repository.GetCvAsync(AccountId, id, ct) is { } cv ? File(cv.Content, "application/pdf", cv.Name) : NotFound();
}
