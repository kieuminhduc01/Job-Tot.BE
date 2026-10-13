# Employer talent discovery

`/api/employer/talent-discovery` requires an employer session and an active membership of an active company. Discovery includes active candidate accounts with login status `Active` and candidate readiness `looking` or `considering`; `paused` hides a profile from list, detail, saved collection and mutations. Existing legitimate applications remain available through the application workflow.

The candidate's account name, avatar and professional profile are available to employers. Discovery responses whitelist professional fields and omit email, phone, date of birth, gender, raw profile JSON and private CV documents. Globally saved talent entries do not expose contact details through existing talent/application lists. Employers can initiate the existing chat flow with `accountId`.

## Endpoints

- `GET /metadata`: company context, active running campaigns, provinces, visible skill names and collection statistics.
- `GET /`: paginated cards. Filters: `keyword`, `campaignId`, `provinceId` (residence or preferred work province), `skill`, `minYears`, `maxYears`, `minScore`, `readiness`. `collection` is `all`, `interested` or `saved`; `sort` is `match`, `newest` or `experience`. `pageSize` defaults to 9 and accepts 1–50.
- `GET /{candidateId}?campaignId=...`: one card, with professional experiences, education, certificates, projects and salary expectations inside `profile`.
- `PUT /{candidateId}/interest` with `{ "interested": true }`: company interest, independent of saved talents.
- `PUT /{candidateId}/saved` with `{ "saved": true }`: the existing company talent pool. Unsaving deactivates the entry and saving again restores the same ID and notes. Both writes are idempotent, company scoped and return `isInterested`, `isSaved`, `talentId`.

Cards contain `candidateId`, `accountId`, `profile`, `match`, `isInterested`, `isSaved`, `talentId`. `match` contains `score`, `campaignId`, `campaignTitle`, `reasons`, `matchedSkills`, `missingSkills`. A foreign, paused, expired or non-running selected campaign returns 404.

## Matching

This is a deterministic professional comparison, not an AI prediction of a candidate's future success. Criteria weights are skills 55, position 25, minimum experience 10 and work location 10. Skills and experience criteria are counted only when configured on the campaign; required skills receive twice the weight of optional skills. Skill matching ignores case and Vietnamese accents. Position comparison uses significant words in the headline and desired position. Remote campaigns do not require the candidate to reside in the campaign province. Unknown experience receives no experience points; free-form experience periods are not converted into invented years. Age, gender and other demographics never contribute.

Without a selected campaign, each profile is compared with the company's ongoing `Running` campaigns and shows the best match. A score of 70 or higher contributes to the recommended count. If the company has no current running campaign, scores are null and discovery/search/saving continue to work.

## Database deployment

The additive EF migration `20261011125002_AddEmployerCandidateInterest` creates only `EmployerCandidateInterests`, with a unique company/candidate index. It does not modify candidate profiles or existing talent-pool entries.

After stopping the local backend, run the usual EF migration command from `BE/JobTot`:

```powershell
dotnet ef database update --project src/JobTot.Infrastructure --startup-project src/JobTot.Api
```

For a database with unrelated pending historical migrations, review and apply `database/talent-discovery.sql` to deploy only this new table. That idempotent script also records this migration in an existing EF migration history. Restart the backend to load the new endpoints.

## Validation

Discovery endpoints return 499 only when the action/request cancellation token is canceled. Canceled requests do not become a 500 response; independent cancellation and other database failures still propagate. Candidate reads use split queries so the profile JSON is not duplicated for each relational skill. The frontend waits 180 ms before requesting changed list filters and still aborts superseded requests.

`TalentDiscoveryCancellationTests` covers pre-canceled requests, cancellation during candidate queries and preservation of unrelated failures. When Visual Studio is configured to break when `TaskCanceledException`/`OperationCanceledException` is **thrown**, it can still pause at EF's throw before the controller catches it. To avoid stopping on normal canceled requests, clear the **Thrown** check for these exception types in Exception Settings; keep debugging unhandled exceptions. Do not remove cancellation tokens or return an empty successful result to hide cancellation.

`EmployerTalentDiscoveryTests` exercises ranking, filters, authorization, paused/locked-account privacy, professional detail whitelisting, no-campaign behavior, independent interest/save persistence, idempotence, company isolation and privacy in the existing talent list. Regression coverage verifies that re-saving through the applicant screen restores the original talent ID/notes/readiness, and that campaign assignment rejects paused/locked profiles and detects existing sourced applications without a visibility filter. `EmployerCandidatesTests` covers compatibility with application-based saved talents.

Candidate matching currently reads the visible professional pool and ranks it in memory to support free-form skills in the profile JSON. For large deployments, professional skills and experience should be normalized and searchable with database indexes before distributing matching across large candidate pools.
