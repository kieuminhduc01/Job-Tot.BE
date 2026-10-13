using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using JobTot.Application.Authentication;
using JobTot.Domain.Entities;
using JobTot.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace JobTot.Domain.Tests;
public sealed class AccountMessagesTests
{
    [Fact]
    public async Task MessageReadsPersistAcrossDevicesAndCannotReadAnotherConversation()
    {
        await using var factory = new Factory();
        using var sender = factory.CreateClient();
        using var reader = factory.CreateClient();
        using var secondDevice = factory.CreateClient();
        using var outsider = factory.CreateClient();
        await Register(sender, "read-sender");
        var readerId = await Register(reader, "read-reader");
        await Register(outsider, "read-outsider");
        secondDevice.DefaultRequestHeaders.Authorization = reader.DefaultRequestHeaders.Authorization;
        var conversation = await sender.PostAsJsonAsync("/api/candidate/messages", new { accountId = readerId });
        var id = (await conversation.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();
        var sent = await sender.PostAsJsonAsync($"/api/candidate/messages/{id}", new { text = "Hello", clientMessageId = Guid.NewGuid() });
        var messageId = (await sent.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetInt64();
        var header = await secondDevice.GetFromJsonAsync<JsonElement>("/api/candidate/header");
        Assert.Equal(1, header.GetProperty("unreadConversationCount").GetInt32());
        var input = new { messageIds = new[] { messageId } };
        Assert.Equal(HttpStatusCode.NotFound, (await outsider.PutAsJsonAsync($"/api/candidate/messages/{id}/read", input)).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await reader.PutAsJsonAsync($"/api/candidate/messages/{id}/read", input)).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await secondDevice.PutAsJsonAsync($"/api/candidate/messages/{id}/read", input)).StatusCode);
        header = await secondDevice.GetFromJsonAsync<JsonElement>("/api/candidate/header");
        Assert.Equal(0, header.GetProperty("unreadConversationCount").GetInt32());
        await sender.PostAsJsonAsync($"/api/candidate/messages/{id}", new { text = "New message", clientMessageId = Guid.NewGuid() });
        header = await secondDevice.GetFromJsonAsync<JsonElement>("/api/candidate/header");
        Assert.Equal(1, header.GetProperty("unreadConversationCount").GetInt32());
    }
    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task TypingSkipsQueryWhenClientAlreadyDisconnected(bool update)
    {
        await using var factory = new Factory();
        using var scope = factory.Services.CreateScope();
        var context = new Microsoft.AspNetCore.Http.DefaultHttpContext { RequestAborted = new CancellationToken(true) };
        var controller = new JobTot.Api.Controllers.AccountMessagesController(
            scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>(),
            scope.ServiceProvider.GetRequiredService<IMemoryCache>())
        { ControllerContext = new Microsoft.AspNetCore.Mvc.ControllerContext { HttpContext = context } };
        // No account claim: an aborted request must return before even building the query.
        var result = update
            ? await controller.UpdateTyping(Guid.NewGuid(), new(true), context.RequestAborted)
            : await controller.Typing(Guid.NewGuid(), context.RequestAborted);
        Assert.Equal(499, Assert.IsType<Microsoft.AspNetCore.Mvc.StatusCodeResult>(result).StatusCode);
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task TypingDoesNotSuppressCancellationWhenClientIsConnected(bool update)
    {
        await using var factory = new Factory();
        using var scope = factory.Services.CreateScope();
        var context = new Microsoft.AspNetCore.Http.DefaultHttpContext();
        context.User = new System.Security.Claims.ClaimsPrincipal(new System.Security.Claims.ClaimsIdentity(
            [new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.NameIdentifier, Guid.NewGuid().ToString())], "test"));
        var controller = new JobTot.Api.Controllers.AccountMessagesController(
            scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>(),
            scope.ServiceProvider.GetRequiredService<IMemoryCache>())
        { ControllerContext = new Microsoft.AspNetCore.Mvc.ControllerContext { HttpContext = context } };
        await Assert.ThrowsAnyAsync<OperationCanceledException>(async () =>
        {
            if (update) await controller.UpdateTyping(Guid.NewGuid(), new(true), new CancellationToken(true));
            else await controller.Typing(Guid.NewGuid(), new CancellationToken(true));
        });
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task TypingIsPrivateExpiresAndClearsOnStopAndSend(bool employerSender)
    {
        await using var factory = new Factory();
        using var sender = factory.CreateClient();
        using var peer = factory.CreateClient();
        using var outsider = factory.CreateClient();
        using var guest = factory.CreateClient();
        var senderId = employerSender ? (await RegisterEmployer(factory, sender)).AccountId : await Register(sender, "typing-sender");
        var peerId = await Register(peer, "typing-peer");
        await Register(outsider, "typing-outsider");
        var root = employerSender ? "/api/employer/messages" : "/api/candidate/messages";
        var start = await sender.PostAsJsonAsync(root, new { accountId = peerId });
        var id = (await start.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();
        var mine = $"{root}/{id}/typing";
        var theirs = $"/api/candidate/messages/{id}/typing";
        Assert.Equal(HttpStatusCode.Unauthorized, (await guest.GetAsync(theirs)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await outsider.GetAsync(theirs)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await outsider.PostAsJsonAsync(theirs, new { isTyping = true })).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await sender.PostAsJsonAsync(mine, new { isTyping = true })).StatusCode);
        Assert.True((await peer.GetFromJsonAsync<JsonElement>(theirs)).GetProperty("isTyping").GetBoolean());
        Assert.False((await sender.GetFromJsonAsync<JsonElement>(mine)).GetProperty("isTyping").GetBoolean());
        Assert.Equal(HttpStatusCode.NoContent, (await sender.PostAsJsonAsync(mine, new { isTyping = false })).StatusCode);
        Assert.False((await peer.GetFromJsonAsync<JsonElement>(theirs)).GetProperty("isTyping").GetBoolean());
        await sender.PostAsJsonAsync(mine, new { isTyping = true });
        Assert.Equal(HttpStatusCode.OK, (await sender.PostAsJsonAsync($"{root}/{id}", new { text = "Hello", clientMessageId = Guid.NewGuid() })).StatusCode);
        Assert.False((await peer.GetFromJsonAsync<JsonElement>(theirs)).GetProperty("isTyping").GetBoolean());
        // A stale cached heartbeat must not be shown even before cache eviction runs.
        factory.Services.GetRequiredService<Microsoft.Extensions.Caching.Memory.IMemoryCache>()
            .Set((id, senderId), DateTimeOffset.UtcNow.AddSeconds(-1));
        var expired = await peer.GetFromJsonAsync<JsonElement>(theirs);
        Assert.False(expired.GetProperty("isTyping").GetBoolean());
        Assert.Equal(JsonValueKind.Null, expired.GetProperty("expiresAt").ValueKind);
    }

    [Fact]
    public async Task HeaderQueryCancellationIsHandledBySharedMiddleware()
    {
        await using var factory = new Factory();
        using var scope = factory.Services.CreateScope();
        using var cancellation = new CancellationTokenSource();
        var context = new Microsoft.AspNetCore.Http.DefaultHttpContext { RequestAborted = cancellation.Token };
        context.User = new System.Security.Claims.ClaimsPrincipal(new System.Security.Claims.ClaimsIdentity(
            new[] { new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.NameIdentifier, Guid.NewGuid().ToString()) }, "test"));
        context.Response.Body = new MemoryStream();
        var controller = new JobTot.Api.Controllers.AccountHeaderController(scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>())
        { ControllerContext = new Microsoft.AspNetCore.Mvc.ControllerContext { HttpContext = context } };
        var middleware = new JobTot.Api.RequestCancellationMiddleware(async ctx =>
        {
            cancellation.Cancel();
            await controller.Get(ctx.RequestAborted);
        });
        await middleware.InvokeAsync(context);
        Assert.Equal(499, context.Response.StatusCode);
        Assert.Equal(0, context.Response.Body.Length);
    }

    [Fact]
    public async Task HeaderUsesOwnProfileAndOnlyIncomingPrivateMessages()
    {
        await using var factory = new Factory();
        using var alice = factory.CreateClient();
        using var bob = factory.CreateClient();
        using var guest = factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await guest.GetAsync("/api/candidate/header")).StatusCode);
        var aliceId = await Register(alice, "header-alice");
        await Register(bob, "header-bob");
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var profile = await db.CandidateProfileRecords.SingleAsync(p => p.AccountId == aliceId);
            profile.DetailsJson = JsonSerializer.Serialize(new JobTot.Application.Profiles.CandidateProfileDocument { AvatarUrl = "/uploads/alice.png" });
            await db.SaveChangesAsync();
        }
        var start = await bob.PostAsJsonAsync("/api/candidate/messages", new { accountId = aliceId });
        var id = (await start.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();
        await bob.PostAsJsonAsync($"/api/candidate/messages/{id}", new { text = "Hello", clientMessageId = Guid.NewGuid() });
        var header = await alice.GetFromJsonAsync<JsonElement>("/api/candidate/header");
        Assert.Equal("/uploads/alice.png", header.GetProperty("avatarUrl").GetString());
        var restored = await alice.GetFromJsonAsync<JsonElement>("/api/candidate/auth/me");
        Assert.Equal("/uploads/alice.png", restored.GetProperty("avatarUrl").GetString());
        var login = await alice.PostAsJsonAsync("/api/candidate/auth/login", new { emailOrPhone = "header-alice@chat.example.com", password = "testpassword" });
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);
        var loggedIn = await login.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("/uploads/alice.png", loggedIn.GetProperty("account").GetProperty("avatarUrl").GetString());
        Assert.Equal(id, Assert.Single(header.GetProperty("messages").EnumerateArray()).GetProperty("conversationId").GetGuid());
        var senderHeader = await bob.GetFromJsonAsync<JsonElement>("/api/candidate/header");
        Assert.Empty(senderHeader.GetProperty("messages").EnumerateArray());
        Assert.Empty(senderHeader.GetProperty("notifications").EnumerateArray());
    }

    [Fact]
    public async Task CandidatesAndEmployersChatPrivatelyAndRetryWithoutDuplicates()
    {
        await using var factory=new Factory();
        using var alice=factory.CreateClient();using var bob=factory.CreateClient();using var outsider=factory.CreateClient();using var employer=factory.CreateClient();using var guest=factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized,(await guest.GetAsync("/api/candidate/messages")).StatusCode);
        var aliceId=await Register(alice,"alice");var bobId=await Register(bob,"bob");await Register(outsider,"outsider");
        using var scope=factory.Services.CreateScope();var db=scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var province=new Province {ProvinceName="Test",ProvinceCode="99"};db.Add(province);await db.SaveChangesAsync();
        var response=await employer.PostAsJsonAsync("/api/employer/auth/register",new EmployerRegisterRequest {FullName="HR Test",Email="hr-chat@example.com",WorkPhone="0988123456",CompanyName="Chat Test",TaxCode="0109867899",HeadOfficeProvinceId=province.Id,Password="testpassword",ConfirmPassword="testpassword",AcceptTerms=true,RecruitmentCommitment=true});
        Assert.Equal(HttpStatusCode.Created,response.StatusCode);var session=(await response.Content.ReadFromJsonAsync<EmployerSessionDto>())!;employer.DefaultRequestHeaders.Authorization=new("Bearer",session.AccessToken);
        var start=await alice.PostAsJsonAsync("/api/candidate/messages",new {accountId=bobId});Assert.Equal(HttpStatusCode.OK,start.StatusCode);
        var id=(await start.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();
        var reverse=await bob.PostAsJsonAsync("/api/candidate/messages",new {accountId=aliceId});Assert.Equal(id,(await reverse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid());
        var message=new {text="Hello Bob",clientMessageId=Guid.NewGuid()};
        Assert.Equal(HttpStatusCode.OK,(await alice.PostAsJsonAsync($"/api/candidate/messages/{id}",message)).StatusCode);
        Assert.Equal(HttpStatusCode.OK,(await alice.PostAsJsonAsync($"/api/candidate/messages/{id}",message)).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict,(await alice.PostAsJsonAsync($"/api/candidate/messages/{id}",new {text="Changed",message.clientMessageId})).StatusCode);
        var inbox=await bob.GetFromJsonAsync<JsonElement>($"/api/candidate/messages/{id}");Assert.Equal("Hello Bob",Assert.Single(inbox.GetProperty("items").EnumerateArray()).GetProperty("text").GetString());
        Assert.Equal(HttpStatusCode.NotFound,(await outsider.GetAsync($"/api/candidate/messages/{id}")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound,(await outsider.PostAsJsonAsync($"/api/candidate/messages/{id}",new {text="Intrusion",clientMessageId=Guid.NewGuid()})).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest,(await alice.PostAsJsonAsync("/api/candidate/messages",new {accountId=aliceId})).StatusCode);
        var employerStart=await employer.PostAsJsonAsync("/api/employer/messages",new {accountId=aliceId});Assert.Equal(HttpStatusCode.OK,employerStart.StatusCode);
        var hrId=(await employerStart.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();
        var contactHr = await alice.PostAsJsonAsync("/api/candidate/messages", new { recruiterEmail = " HR-CHAT@example.com " });
        Assert.Equal(HttpStatusCode.OK, contactHr.StatusCode);
        var hrContact = await contactHr.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("HR Test", hrContact.GetProperty("peer").GetProperty("name").GetString());
        Assert.Equal("Employer", hrContact.GetProperty("peer").GetProperty("role").GetString());
        Assert.Equal(hrId, hrContact.GetProperty("id").GetGuid());
        var companyId = await db.RecruiterProfileRecords.Where(p => p.Account.Email == "hr-chat@example.com").Select(p => p.CompanyId).SingleAsync();
        var contactCompany = await alice.PostAsJsonAsync("/api/candidate/messages", new { companyId });
        Assert.Equal(HttpStatusCode.OK, contactCompany.StatusCode);
        Assert.Equal(hrId, (await contactCompany.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid());
        Assert.Equal(HttpStatusCode.NotFound, (await alice.PostAsJsonAsync("/api/candidate/messages", new { recruiterEmail = "missing@example.com" })).StatusCode);
        Assert.Equal(HttpStatusCode.OK,(await employer.PostAsJsonAsync($"/api/employer/messages/{hrId}",new {text="Hello candidate",clientMessageId=Guid.NewGuid()})).StatusCode);
        Assert.Equal(2,(await alice.GetFromJsonAsync<JsonElement>("/api/candidate/messages")).GetArrayLength());
        var people=await alice.GetFromJsonAsync<JsonElement>("/api/candidate/messages/people?q=Chat");Assert.True(people.GetArrayLength()>=2);Assert.All(people.EnumerateArray(),x=>Assert.False(x.TryGetProperty("email",out _)));
        Assert.Equal(2,await db.ChatMessages.CountAsync());
        using var secondEmployer=factory.CreateClient();
        response=await secondEmployer.PostAsJsonAsync("/api/employer/auth/register",new EmployerRegisterRequest {FullName="HR Two",Email="hr-two@example.com",WorkPhone="0988123457",CompanyName="Chat Two",TaxCode="0109867800",HeadOfficeProvinceId=province.Id,Password="testpassword",ConfirmPassword="testpassword",AcceptTerms=true,RecruitmentCommitment=true});
        Assert.Equal(HttpStatusCode.Created,response.StatusCode);
        var secondSession=(await response.Content.ReadFromJsonAsync<EmployerSessionDto>())!;secondEmployer.DefaultRequestHeaders.Authorization=new("Bearer",secondSession.AccessToken);
        var peer=await secondEmployer.GetFromJsonAsync<JsonElement>("/api/employer/auth/me");
        response=await employer.PostAsJsonAsync("/api/employer/messages",new {accountId=peer.GetProperty("id").GetGuid()});
        Assert.Equal(HttpStatusCode.OK,response.StatusCode);
        var employerConversation=(await response.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();
        Assert.Equal(HttpStatusCode.OK,(await employer.PostAsJsonAsync($"/api/employer/messages/{employerConversation}",new {text="Hello HR",clientMessageId=Guid.NewGuid()})).StatusCode);
        var hrInbox=await secondEmployer.GetFromJsonAsync<JsonElement>($"/api/employer/messages/{employerConversation}");
        Assert.Equal("Hello HR",Assert.Single(hrInbox.GetProperty("items").EnumerateArray()).GetProperty("text").GetString());
    }

    [Fact]
    public async Task ChatUsesCandidateAvatarAndCompanyLogoForStartListAndSearchAndReflectsUpdates()
    {
        await using var factory = new Factory();
        using var candidate = factory.CreateClient();
        using var employer = factory.CreateClient();
        var candidateId = await Register(candidate, "avatar-candidate");
        var (employerId, companyId) = await RegisterEmployer(factory, employer);
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var profile = await db.CandidateProfileRecords.SingleAsync(p => p.AccountId == candidateId);
        profile.DetailsJson = "{\"AVATARurl\":\"/uploads/chat-candidate.png\",\"privateNote\":\"private candidate profile\"}";
        var company = await db.Companies.SingleAsync(c => c.Id == companyId);
        var logo = new Media { Url = "/uploads/chat-media-logo.png", Type = "image" };
        company.LogoFile = logo;
        company.LogoFileId = logo.Id;
        company.Culture = JsonSerializer.Serialize(new JobTot.Application.Companies.EmployerCompanyBrand
        {
            LogoUrl = "/uploads/chat-brand-logo.png", Story = "private company profile"
        });
        db.Add(logo);
        await db.SaveChangesAsync();

        var candidateStart = await candidate.PostAsJsonAsync("/api/candidate/messages", new { companyId });
        Assert.Equal(HttpStatusCode.OK, candidateStart.StatusCode);
        var candidateConversation = await candidateStart.Content.ReadFromJsonAsync<JsonElement>();
        var conversationId = candidateConversation.GetProperty("id").GetGuid();
        AssertPublicAvatar(candidateConversation.GetProperty("peer"), employerId, "/uploads/chat-brand-logo.png");

        var employerStart = await employer.PostAsJsonAsync("/api/employer/messages", new { accountId = candidateId });
        Assert.Equal(HttpStatusCode.OK, employerStart.StatusCode);
        var employerConversation = await employerStart.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(conversationId, employerConversation.GetProperty("id").GetGuid());
        AssertPublicAvatar(employerConversation.GetProperty("peer"), candidateId, "/uploads/chat-candidate.png");

        await AssertChatAvatar(candidate, "candidate", employerId, "/uploads/chat-brand-logo.png");
        await AssertChatAvatar(employer, "employer", candidateId, "/uploads/chat-candidate.png");

        // Existing conversations resolve current images; an empty brand logo uses the stored media logo.
        profile.DetailsJson = "{\"avatarUrl\":\"/uploads/chat-candidate-new.png\",\"privateNote\":\"private candidate profile\"}";
        company.Culture = JsonSerializer.Serialize(new JobTot.Application.Companies.EmployerCompanyBrand());
        logo.Url = "/uploads/chat-media-logo-new.png";
        await db.SaveChangesAsync();

        await AssertChatAvatar(candidate, "candidate", employerId, "/uploads/chat-media-logo-new.png");
        await AssertChatAvatar(employer, "employer", candidateId, "/uploads/chat-candidate-new.png");
        var reopenedByEmail = await candidate.PostAsJsonAsync("/api/candidate/messages", new { recruiterEmail = "chat-avatar-hr@example.com" });
        Assert.Equal(HttpStatusCode.OK, reopenedByEmail.StatusCode);
        var reopened = await reopenedByEmail.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(conversationId, reopened.GetProperty("id").GetGuid());
        AssertPublicAvatar(reopened.GetProperty("peer"), employerId, "/uploads/chat-media-logo-new.png");
        var reopenedByEmployer = await employer.PostAsJsonAsync("/api/employer/messages", new { accountId = candidateId });
        Assert.Equal(HttpStatusCode.OK, reopenedByEmployer.StatusCode);
        AssertPublicAvatar((await reopenedByEmployer.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("peer"), candidateId, "/uploads/chat-candidate-new.png");
    }

    [Theory]
    [InlineData(null, false)]
    [InlineData("{}", false)]
    [InlineData("{invalid profile", false)]
    [InlineData("{\"avatarUrl\":42}", false)]
    [InlineData("{\"avatarUrl\":\"\"}", false)]
    [InlineData("{\"avatarUrl\":\"/uploads/inactive-candidate.png\"}", true)]
    public async Task MissingInvalidOrInactiveAvatarsDoNotPreventMessaging(string? detailsJson, bool inactive)
    {
        await using var factory = new Factory();
        using var candidate = factory.CreateClient();
        using var employer = factory.CreateClient();
        var candidateId = await Register(candidate, "avatar-fallback");
        var (employerId, _) = await RegisterEmployer(factory, employer);
        var start = await candidate.PostAsJsonAsync("/api/candidate/messages", new { accountId = employerId });
        Assert.Equal(HttpStatusCode.OK, start.StatusCode);
        var conversation = await start.Content.ReadFromJsonAsync<JsonElement>();
        AssertPublicAvatar(conversation.GetProperty("peer"), employerId, null);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var profile = await db.CandidateProfileRecords.SingleAsync(p => p.AccountId == candidateId);
            profile.DetailsJson = detailsJson;
            if (inactive) profile.Status = JobTot.Domain.Enums.EntityStatus.Inactive;
            await db.SaveChangesAsync();
        }

        var reverse = await employer.PostAsJsonAsync("/api/employer/messages", new { accountId = candidateId });
        Assert.Equal(HttpStatusCode.OK, reverse.StatusCode);
        var reverseConversation = await reverse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(conversation.GetProperty("id").GetGuid(), reverseConversation.GetProperty("id").GetGuid());
        AssertPublicAvatar(reverseConversation.GetProperty("peer"), candidateId, null);
        // Inactive candidate profiles cannot authenticate, but their peer image must still be omitted.
        if (!inactive) await AssertChatAvatar(candidate, "candidate", employerId, null);
        await AssertChatAvatar(employer, "employer", candidateId, null);
    }

    private static async Task AssertChatAvatar(HttpClient client, string role, Guid peerId, string? avatarUrl)
    {
        var conversations = await client.GetFromJsonAsync<JsonElement>($"/api/{role}/messages");
        AssertPublicAvatar(Assert.Single(conversations.EnumerateArray()).GetProperty("peer"), peerId, avatarUrl);
        var people = await client.GetFromJsonAsync<JsonElement>($"/api/{role}/messages/people?q=Chat");
        AssertPublicAvatar(Assert.Single(people.EnumerateArray()), peerId, avatarUrl);
    }

    private static void AssertPublicAvatar(JsonElement person, Guid accountId, string? avatarUrl)
    {
        Assert.Equal(accountId, person.GetProperty("id").GetGuid());
        var actual = person.GetProperty("avatarUrl").GetString();
        if (avatarUrl is null) Assert.True(string.IsNullOrEmpty(actual));
        else Assert.Equal(avatarUrl, actual);
        Assert.Equal(new[] { "avatarUrl", "id", "name", "role" }, person.EnumerateObject().Select(p => p.Name).OrderBy(n => n, StringComparer.Ordinal).ToArray());
    }

    private static async Task<(Guid AccountId, Guid CompanyId)> RegisterEmployer(Factory factory, HttpClient client)
    {
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var province = new Province { ProvinceName = "Chat test", ProvinceCode = "99" };
        db.Add(province);
        await db.SaveChangesAsync();
        var response = await client.PostAsJsonAsync("/api/employer/auth/register", new EmployerRegisterRequest
        {
            FullName = "Chat avatar HR", Email = "chat-avatar-hr@example.com", WorkPhone = "0988123456",
            CompanyName = "Chat avatar company", TaxCode = "0109867899", HeadOfficeProvinceId = province.Id,
            Password = "testpassword", ConfirmPassword = "testpassword", AcceptTerms = true, RecruitmentCommitment = true
        });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var session = (await response.Content.ReadFromJsonAsync<EmployerSessionDto>())!;
        client.DefaultRequestHeaders.Authorization = new("Bearer", session.AccessToken);
        var profile = await db.RecruiterProfileRecords.SingleAsync(p => p.Account.Email == "chat-avatar-hr@example.com");
        return (profile.AccountId, profile.CompanyId);
    }

    private static async Task<Guid> Register(HttpClient client,string name)
    {
        var response=await client.PostAsJsonAsync("/api/candidate/auth/register",new CandidateRegisterRequest {FullName="Chat "+name,EmailOrPhone=name+"@chat.example.com",Password="testpassword",ConfirmPassword="testpassword"});
        Assert.Equal(HttpStatusCode.Created,response.StatusCode);var session=(await response.Content.ReadFromJsonAsync<CandidateSessionDto>())!;client.DefaultRequestHeaders.Authorization=new("Bearer",session.AccessToken);
        var account=await client.GetFromJsonAsync<JsonElement>("/api/candidate/auth/me");return account.GetProperty("id").GetGuid();
    }
    private sealed class Factory:WebApplicationFactory<Program>
    {
        private readonly string name=Guid.NewGuid().ToString();
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Development");builder.ConfigureServices(s=>{
                s.RemoveAll<RecruitmentDbContext>();s.RemoveAll<DbContextOptions<RecruitmentDbContext>>();s.RemoveAll<IDbContextOptionsConfiguration<RecruitmentDbContext>>();
                s.AddDbContext<RecruitmentDbContext>(o=>o.UseInMemoryDatabase(name));
            });
        }
    }
}
