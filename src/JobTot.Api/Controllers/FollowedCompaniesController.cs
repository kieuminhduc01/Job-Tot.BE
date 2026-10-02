using System.Security.Claims;
using JobTot.Application.Companies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace JobTot.Api.Controllers;

[ApiController]
[Route("api/candidate/followed-companies")]
[Authorize(Policy = CandidateAuthentication.Policy)]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class FollowedCompaniesController(ICompanyDirectoryRepository directory) : ControllerBase
{
    private Guid AccountId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<Guid>>> List(CancellationToken ct) => Ok(await directory.FollowedAsync(AccountId, ct));
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Follow(Guid id, CancellationToken ct)
    {
        await directory.SetFollowedAsync(AccountId, id, true, ct);
        return NoContent();
    }
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Unfollow(Guid id, CancellationToken ct)
    {
        await directory.SetFollowedAsync(AccountId, id, false, ct);
        return NoContent();
    }
}
