using System.ComponentModel.DataAnnotations;
using JobTot.Application;
using Microsoft.AspNetCore.Mvc;

namespace JobTot.Api.Controllers;

[ApiController]
[Route("api/companies")]
public sealed class CompaniesController(RecruitmentService service) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PageResult<CompanyDto>>> List(CancellationToken ct,
        [FromQuery, Range(1, 1000000)] int page = 1, [FromQuery, Range(1, 100)] int pageSize = 20)
        => Ok(await service.GetCompaniesAsync(page, pageSize, ct));
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<CompanyDto>> Get(Guid id, CancellationToken ct)
        => Ok(await service.GetCompanyAsync(id, ct));
    [HttpPost]
    public async Task<ActionResult<CompanyDto>> Create(CreateCompanyRequest request, CancellationToken ct)
    {
        var company = await service.CreateCompanyAsync(request, ct);
        return CreatedAtAction(nameof(Get), new { id = company.Id }, company);
    }
}
