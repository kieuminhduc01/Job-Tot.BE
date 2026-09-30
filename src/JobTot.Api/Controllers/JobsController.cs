using JobTot.Application;
using Microsoft.AspNetCore.Mvc;

namespace JobTot.Api.Controllers;

[ApiController]
[Route("api/jobs")]
public sealed class JobsController(RecruitmentService service) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PageResult<JobDto>>> Search([FromQuery] JobSearch query, CancellationToken ct)
        => Ok(await service.SearchAsync(query, ct));
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<JobDto>> Get(Guid id, CancellationToken ct)
        => Ok(await service.GetAsync(id, ct));
    [HttpPost]
    public async Task<ActionResult<JobDto>> Create(CreateJobRequest request, CancellationToken ct)
    {
        var job = await service.CreateAsync(request, ct);
        return CreatedAtAction(nameof(Get), new { id = job.Id }, job);
    }
    [HttpPut("{id:guid}")]
    public async Task<ActionResult<JobDto>> Update(Guid id, SaveJobRequest request, CancellationToken ct)
        => Ok(await service.UpdateAsync(id, request, ct));
    [HttpPost("{id:guid}/close")]
    public async Task<IActionResult> Close(Guid id, CancellationToken ct)
    {
        await service.CloseAsync(id, ct);
        return NoContent();
    }
}
