using System.Net;
using JobTot.Api.Controllers;
using Microsoft.AspNetCore.Mvc;

namespace JobTot.Domain.Tests;

public class CompanyMapTests
{
    [Theory]
    [InlineData("https://localhost/maps")]
    [InlineData("https://maps.app.goo.gl.evil.test/place")]
    [InlineData("http://maps.app.goo.gl/place")]
    [InlineData("https://www.google.com:8443/maps")]
    [InlineData("https://user@maps.app.goo.gl/place")]
    public async Task RejectsUntrustedUrlsWithoutNetwork(string url)
    {
        using var handler = new RedirectHandler("https://www.google.com/maps?q=21,105");
        using var factory = new Factory(handler);
        Assert.IsType<BadRequestObjectResult>(await new CompanyMapController(factory).Resolve(url, default));
        Assert.Equal(0, handler.Requests);
    }

    [Fact]
    public async Task ResolvesShortLinkWithoutFetchingTheFullMap()
    {
        using var handler = new RedirectHandler("https://www.google.com/maps/place/Office/data=!3d21.03!4d105.8");
        using var factory = new Factory(handler);
        var result = await new CompanyMapController(factory).Resolve("https://maps.app.goo.gl/demo", default);
        Assert.IsType<OkObjectResult>(result);
        Assert.Equal(1, handler.Requests);
    }

    [Fact]
    public async Task RejectsRedirectToPrivateNetwork()
    {
        using var handler = new RedirectHandler("https://127.0.0.1/private");
        using var factory = new Factory(handler);
        Assert.IsType<UnprocessableEntityObjectResult>(await new CompanyMapController(factory).Resolve("https://maps.app.goo.gl/demo", default));
        Assert.Equal(1, handler.Requests);
    }

    [Fact]
    public async Task PreservesRequestCancellation()
    {
        using var handler = new RedirectHandler("https://www.google.com/maps?q=21,105");
        using var factory = new Factory(handler);
        using var cancellation = new CancellationTokenSource();
        cancellation.Cancel();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => new CompanyMapController(factory).Resolve("https://maps.app.goo.gl/demo", cancellation.Token));
    }

    [Theory]
    [InlineData(false, 502)]
    [InlineData(true, 504)]
    public async Task DistinguishesTransportCancellationFromTimeout(bool timeout, int status)
    {
        using var handler = new CallbackHandler(async ct =>
        {
            if (timeout) await Task.Delay(Timeout.Infinite, ct);
            throw new TaskCanceledException("Transport aborted", new IOException("Connection aborted"));
        });
        using var factory = new Factory(handler);
        var result = Assert.IsType<ObjectResult>(await new CompanyMapController(factory).Resolve("https://maps.app.goo.gl/demo", default));
        Assert.Equal(status, result.StatusCode);
    }

    [Fact]
    public async Task DisconnectDuringHttpRequestPreservesCancellation()
    {
        using var cancellation = new CancellationTokenSource();
        using var handler = new CallbackHandler(ct =>
        {
            cancellation.Cancel();
            throw new HttpRequestException("Transport aborted", new IOException("Connection aborted"));
        });
        using var factory = new Factory(handler);
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => new CompanyMapController(factory).Resolve("https://maps.app.goo.gl/demo", cancellation.Token));
    }

    [Theory]
    [InlineData(429)]
    [InlineData(503)]
    public async Task UpstreamErrorsReturnBadGateway(int status)
    {
        using var handler = new CallbackHandler(_ => Task.FromResult(new HttpResponseMessage((HttpStatusCode)status)));
        using var factory = new Factory(handler);
        var result = Assert.IsType<ObjectResult>(await new CompanyMapController(factory).Resolve("https://maps.app.goo.gl/demo", default));
        Assert.Equal(502, result.StatusCode);
    }

    private sealed class CallbackHandler(Func<CancellationToken, Task<HttpResponseMessage>> send) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct) => send(ct);
    }

    private sealed class RedirectHandler(string location) : HttpMessageHandler
    {
        public int Requests { get; private set; }
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            ct.ThrowIfCancellationRequested();
            Requests++;
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.Redirect) { Headers = { Location = new Uri(location) } });
        }
    }
    private sealed class Factory(HttpMessageHandler handler) : IHttpClientFactory, IDisposable
    {
        private readonly HttpClient client = new(handler, disposeHandler: false);
        public HttpClient CreateClient(string name) => client;
        public void Dispose() => client.Dispose();
    }
}
