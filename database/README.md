> Historical reference: standalone SQL seed/export files and test suites were removed at the project owner's request. Commands referencing those deleted files are no longer available. Application source and EF migrations are retained; existing SQL Server data is unchanged.

# SQL Server preview data

Application preview content is stored in `JobTot.dbo.DemoDatasets` and read through
`GET /api/demo-data/{key}`. No JSON data files are loaded at runtime.

The local JobTot database has been populated with all four public preview datasets.
For another database, apply EF migrations first, then run:

```powershell
sqlcmd -S .\SQLEXPRESS -d JobTot -E -C -b -f 65001 -i database/preview-data.sql
```

Run from the backend root. The script is transactional and inserts missing keys only;
existing database edits are preserved. Application startup does not seed data.
`preview-data.sql` is a provisioning script; the running application reads SQL Server.

Only explicitly public preview keys are exposed. Account profiles and conversations
continue to use their existing authorized database tables and endpoints. Never put
private conversations or credentials in public preview content.
