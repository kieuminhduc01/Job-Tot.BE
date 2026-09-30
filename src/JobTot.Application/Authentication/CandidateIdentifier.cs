using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;

namespace JobTot.Application.Authentication;

public sealed record CandidateIdentifier(string? Email, string? Phone)
{
    public static CandidateIdentifier Parse(string value)
    {
        value = value.Trim();
        if (value.Contains('@'))
        {
            if (value.Length > 320 || !new EmailAddressAttribute().IsValid(value))
                throw new ArgumentException("Email không hợp lệ.");
            return new(value.ToLowerInvariant(), null);
        }

        // Vietnamese mobile numbers: 09..., +849..., 849... share one identity.
        var phone = Regex.Replace(value, @"[\s().-]", "");
        if (phone.StartsWith("+84")) phone = "0" + phone[3..];
        else if (phone.StartsWith("84")) phone = "0" + phone[2..];
        if (!Regex.IsMatch(phone, @"\A0[35789][0-9]{8}\z"))
            throw new ArgumentException("Nhập email hoặc số điện thoại di động Việt Nam hợp lệ.");
        return new(null, "+84" + phone[1..]);
    }
}
