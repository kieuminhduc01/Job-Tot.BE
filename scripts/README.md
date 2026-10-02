# Company directory development data

`seed-company-directory.sql` inserts 100 fictional companies and 500 Jobs records (five per company), with 10 industries, all 34 official provincial units, salary ranges, descriptions, employee sizes, and related Media records.

Company names contain `(Demo)`, their descriptions identify them as fictional, and job descriptions explicitly state they are not real vacancies. Emails use `example.invalid`. `VerificationStatus = Verified` on 80 demo companies is simulated to exercise the UI, not a claim about actual verification.

Logo and cover SVG assets are in `FE/public/images/demo-companies`. Their Media URLs are relative frontend URLs, so they work without an external image service. Job expiration is 60–89 days after the initial insertion.

From `BE/JobTot`:

```powershell
sqlcmd -S '.\SQLEXPRESS' -d JobTot -E -C -b -f 65001 -i scripts/seed-company-directory.sql
```

The seed runs in one transaction, checks the target database name, and uses deterministic IDs plus application locks. Running it again inserts only missing companies/jobs; it does not overwrite their edits or reset expiration dates. The official Province catalog is normalized in place: the existing eight demo IDs are reused, their letter codes are replaced by official two-digit codes and names, and missing provincial units are inserted. No records or foreign-key references are deleted.

To update only provinces (without inserting companies/jobs):

```powershell
sqlcmd -S '.\SQLEXPRESS' -d JobTot -E -C -b -f 65001 -i scripts/seed-vietnam-provinces.sql
```

`vietnam-provinces.json` contains the 34 units (28 provinces and 6 centrally governed cities) with official names and codes under Decision 19/2025/QĐ-TTg, effective 1 July 2025. The sources are the [signed decision](https://chinhphu.vn/?classid=1&docid=214409&orggroupid=3&pageid=27160) and the [Government's code table](https://baochinhphu.vn/bang-danh-muc-va-ma-so-cua-34-tinh-thanh-moi-3321-don-vi-hanh-chinh-cap-xa-moi-102250704153652947.htm). Numeric codes remain strings so leading zeros are preserved. Duplicate matches stop the transaction rather than guessing which referenced ID to retain. This script is for this application's eight old demo rows; it is not a migration of arbitrary pre-merger 63-province data.

The company directory's location filter includes every active provincial unit, including locations with no companies yet.

To regenerate the SQL and SVG fixtures from their source (Python standard library only):

```powershell
python scripts/generate-company-directory-seed.py
```

View the data at `/companies`; company job buttons fetch the corresponding records from `/api/jobs?companyId={id}`. The current `/jobs` page still uses its pre-existing frontend sample collection; this seed does not change that page's data source.
