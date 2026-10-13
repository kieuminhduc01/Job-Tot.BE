using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace JobTot.Application.Profiles;

public sealed record DiscoveryMatch(int? Score, Guid? CampaignId, string? CampaignTitle,
    IReadOnlyList<string> Reasons, IReadOnlyList<string> MatchedSkills, IReadOnlyList<string> MissingSkills);

public sealed record DiscoveryCampaign(Guid Id, string Title, string? Department, Guid ProvinceId,
    string? Province, string? WorkMode, int? ExperienceMinYears, IReadOnlyList<DiscoveryCampaignSkill> Skills);

public sealed record DiscoveryCampaignSkill(string Name, bool Required);

/// <summary>Transparent, deterministic comparison of professional fields. No personal demographics are used.</summary>
public static class TalentDiscoveryMatching
{
    private static readonly HashSet<string> GenericRoleWords = new(StringComparer.Ordinal)
    {
        "nhan", "vien", "chuyen", "tuyen", "dung", "senior", "junior", "fresher", "intern", "staff", "the", "and", "of"
    };

    public static string Normalize(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return "";
        var builder = new StringBuilder();
        foreach (var c in value.Trim().ToLowerInvariant().Normalize(NormalizationForm.FormD))
        {
            if (CharUnicodeInfo.GetUnicodeCategory(c) == UnicodeCategory.NonSpacingMark) continue;
            builder.Append(c == 'đ' ? 'd' : c);
        }
        return Regex.Replace(builder.ToString().Normalize(NormalizationForm.FormC), @"\s+", " ");
    }

    public static DiscoveryMatch Compare(string? headline, string? desiredPosition, int? yearsExperience,
        Guid? provinceId, Guid? desiredProvinceId, IReadOnlyList<string> skills, DiscoveryCampaign campaign)
    {
        var reasons = new List<string>();
        var normalizedSkills = skills.Select(Normalize).ToHashSet(StringComparer.Ordinal);
        var campaignSkills = campaign.Skills.Where(s => !string.IsNullOrWhiteSpace(s.Name)).GroupBy(s => Normalize(s.Name))
            .Select(g => new DiscoveryCampaignSkill(g.First().Name, g.Any(s => s.Required))).ToArray();
        var matched = campaignSkills.Where(s => normalizedSkills.Contains(Normalize(s.Name))).ToArray();
        var missing = campaignSkills.Where(s => !normalizedSkills.Contains(Normalize(s.Name))).Select(s => s.Name).ToArray();
        double points = 0;
        double available = 25; // A campaign title always contributes role criteria.

        if (campaignSkills.Length > 0)
        {
            available += 55;
            points += 55d * matched.Sum(s => s.Required ? 2 : 1) / campaignSkills.Sum(s => s.Required ? 2 : 1);
            if (matched.Length > 0) reasons.Add($"Khớp {matched.Length}/{campaignSkills.Length} kỹ năng: {string.Join(", ", matched.Select(s => s.Name))}");
        }

        var campaignRole = RoleTokens(campaign.Title);
        var candidateRole = RoleTokens($"{headline} {desiredPosition}");
        var roleOverlap = campaignRole.Count == 0 ? 0 : (double)campaignRole.Count(candidateRole.Contains) / campaignRole.Count;
        points += 25 * roleOverlap;
        if (roleOverlap >= .5) reasons.Add("Định hướng nghề nghiệp phù hợp với vị trí tuyển dụng");

        if (campaign.ExperienceMinYears is > 0)
        {
            available += 10;
            if (yearsExperience.HasValue)
            {
                points += 10 * Math.Clamp((double)yearsExperience.Value / campaign.ExperienceMinYears.Value, 0, 1);
                if (yearsExperience >= campaign.ExperienceMinYears) reasons.Add($"Đáp ứng kinh nghiệm tối thiểu {campaign.ExperienceMinYears} năm");
            }
        }

        available += 10;
        if (campaign.WorkMode == "remote")
        {
            // Remote work does not require residence in the employer's province.
            points += 10;
            reasons.Add("Chiến dịch cho phép làm việc từ xa");
        }
        else if (provinceId == campaign.ProvinceId || desiredProvinceId == campaign.ProvinceId)
        {
            points += 10;
            reasons.Add("Địa điểm làm việc phù hợp");
        }

        return new((int)Math.Round(points * 100 / available, MidpointRounding.AwayFromZero), campaign.Id,
            campaign.Title, reasons, matched.Select(s => s.Name).ToArray(), missing);
    }

    private static HashSet<string> RoleTokens(string? value) => Regex.Split(Normalize(value), @"[^\p{L}\p{N}+#.]+")
        .Where(s => s.Length > 1 && !GenericRoleWords.Contains(s)).ToHashSet(StringComparer.Ordinal);
}
