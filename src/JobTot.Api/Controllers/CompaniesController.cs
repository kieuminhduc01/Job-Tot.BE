using System.ComponentModel.DataAnnotations;
using JobTot.Application;
using JobTot.Application.Companies;
using Microsoft.AspNetCore.Mvc;

namespace JobTot.Api.Controllers;

[ApiController]
[Route("api/companies")]
public sealed class CompaniesController(RecruitmentService service, ICompanyDirectoryRepository directory) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PageResult<CompanyListingDto>>> List([FromQuery] CompanySearch search, CancellationToken ct)
        => Ok(await directory.SearchAsync(search, ct));
    [HttpGet("filters")]
    public async Task<ActionResult<CompanyDirectoryMetadata>> Filters(CancellationToken ct)
        => Ok(await directory.MetadataAsync(ct));
    [HttpGet("featured")]
    public async Task<ActionResult<IReadOnlyList<CompanyListingDto>>> Featured(CancellationToken ct)
        => Ok((await directory.SearchAsync(new CompanySearch { VerifiedOnly = true, HiringOnly = true, Sort = "jobs", PageSize = 4 }, ct)).Items);
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
