# Database demo datasets

`demo-data.json` is a one-time database import file, not application runtime data.
Frontend and API contain no fallback copies of these records. The JSON import is
not served to browsers. Edit records in `dbo.DemoDatasets` to change previews.

From `src/JobTot.Api`, with the usual Development configuration:

```powershell
$env:ASPNETCORE_ENVIRONMENT='Development'
dotnet run -c CodexVerify -- --import-demo-data ../../database/demo-data.json
```

This command creates the table if needed, imports missing keys transactionally,
preserves existing records and exits without starting a web server. The EF migration
also creates the table idempotently, so provisioning and migrations can run in either
order. Normal API startup never populates or overwrites demo data.

Only explicitly public preview keys are exposed by `GET /api/demo-data/{key}`.
Do not store actual account credentials or private conversations in this table.
Real messages must use participant-authorized messaging tables and endpoints.
