# Company directory

Frontend: `/companies`. The page reuses `AuthHeader` from login/profile, `AuthFooter`, `CareerTools`, and a shared `PageBreadcrumb` also used by profile. It is publicly accessible. A signed-in candidate sees their name linking to `/profile`; a guest sees login/register actions.

## Endpoints

| Method | URL | Behavior |
| --- | --- | --- |
| GET | `/api/companies` | Active companies, search/filter/sort/pagination |
| GET | `/api/companies/filters` | Global stats and province/industry filter options with counts |
| GET | `/api/companies/featured` | Up to four verified companies with open jobs, ranked by job count |
| GET | `/api/jobs?companyId={id}` | Company-specific open, unexpired jobs, shown in the jobs dialog |
| GET | `/api/candidate/followed-companies` | Current candidate's followed company IDs |
| PUT | `/api/candidate/followed-companies/{id}` | Follow a company; idempotent |
| DELETE | `/api/candidate/followed-companies/{id}` | Unfollow a company; idempotent |

Following requires the Candidate JWT policy and uses the existing FollowedCompany table. The candidate ID is derived from the authenticated account; the client cannot choose a different candidate. Unfollowing changes status and following again reactivates the existing unique company/candidate pair.

List parameters: `keyword` (up to 200 characters), `provinceId`, `industryId`, `CompanySizeMin`, `CompanySizeMax`, `verifiedOnly`, `hiringOnly`, `sort`, `page`, `pageSize`. Sort values are `relevant` (verified first, then job count), `jobs` and `name`, with stable name/ID tie breakers. Default page size is 10, maximum 100. Employee bounds are optional positive integers: for example `CompanySizeMin=501&CompanySizeMax=1000`, or `CompanySizeMin=1001` for more than 1000 employees. The minimum cannot exceed the maximum. A company's stored employee range must overlap the selected range. Unknown size is excluded by size filters. Invalid query values return 400.

Responses retain `id`, `name`, `description` and add `industry`, `province`, `address`, `sizeMin`, `sizeMax`, `logoUrl`, `coverUrl`, `isVerified`, `openJobCount`, `hiringTitles`. Verification means `Company.VerificationStatus == "Verified"`. Job counts/titles use the existing public Jobs table and exclude closed and expired posts. RecruitmentCampaign is not published through the existing Jobs API and is not counted. Images come from the related Media records; absent images use local visual placeholders. No fabricated ratings or metrics are added.

The frontend keeps filters and pagination in the URL, cancels superseded requests, renders loading/error/empty states, retries failures and uses JWT authorized requests for following. CV templates, editorial content, and tools reuse the existing ServiceNotice behavior when their service is not available.

The implementation uses existing tables and does not require a new migration or insert sample companies. If the database is empty, the page shows an empty state. Company/media/industry/province/verification records must be populated through the database or existing administration workflows; `POST /api/companies` continues to create a basic company.

## Verification

```powershell
# From BE/JobTot; separate configuration avoids Visual Studio's Debug DLL locks.
dotnet test tests/JobTot.Domain.Tests --configuration Jwt

# From FE
npm run check
npx playwright test tests/companies.spec.js
```

Restart the API in Visual Studio after rebuilding to expose the new endpoints. Frontend screenshots in `FE/test-results/companies-desktop.png` and `companies-mobile.png` use isolated test fixtures, not seeded production data.
