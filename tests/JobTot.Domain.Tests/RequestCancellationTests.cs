using JobTot.Api;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging.Abstractions;

namespace JobTot.Domain.Tests;

public sealed class RequestCancellationTests
{
    [Fact]
    public async Task DisconnectWhileAwaitingReaderCancelsWithoutWritingAnError()
    {
        using var cancellation = new CancellationTokenSource();
        var context = new DefaultHttpContext { RequestAborted = cancellation.Token };
        await using var body = new MemoryStream();
        context.Response.Body = body;
        var readerStarted = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var middleware = new RequestCancellationMiddleware(async ctx =>
        {
            readerStarted.SetResult();
            await Task.Delay(Timeout.Infinite, ctx.RequestAborted);
        });

        var request = middleware.InvokeAsync(context);
        await readerStarted.Task;
        Assert.False(request.IsCompleted);
        cancellation.Cancel();
        await request;

        Assert.Equal(499, context.Response.StatusCode);
        Assert.Equal(0, body.Length);
    }

    [Fact]
    public async Task EfStyleOperationCancellationIsHandledForDisconnectedClient()
    {
        using var cancellation = new CancellationTokenSource();
        var context = new DefaultHttpContext { RequestAborted = cancellation.Token };
        context.Response.Body = new MemoryStream();
        var middleware = new RequestCancellationMiddleware(ctx => {
            cancellation.Cancel();
            ctx.RequestAborted.ThrowIfCancellationRequested();
            return Task.CompletedTask;
        });
        await middleware.InvokeAsync(context);
        Assert.Equal(499, context.Response.StatusCode);
        Assert.Equal(0, context.Response.Body.Length);
    }

    [Fact]
    public async Task ExceptionHandlerDoesNotWriteErrorWhenCancellationRacesWithDisconnect()
    {
        var context = new DefaultHttpContext { RequestAborted = new CancellationToken(true) };
        context.Response.Body = new MemoryStream();
        var handler = new ApiExceptionHandler(NullLogger<ApiExceptionHandler>.Instance);
        Assert.True(await handler.TryHandleAsync(context, new OperationCanceledException(context.RequestAborted), context.RequestAborted));
        Assert.Equal(499, context.Response.StatusCode);
        Assert.Equal(0, context.Response.Body.Length);
    }

    [Fact]
    public async Task DisconnectedClientCancellationCompletesWithoutAnErrorResponse()
    {
        using var cancellation = new CancellationTokenSource();
        var context = new DefaultHttpContext { RequestAborted = cancellation.Token };
        context.Response.Body = new MemoryStream();
        var middleware = new RequestCancellationMiddleware(_ => { cancellation.Cancel(); throw new TaskCanceledException(); });

        await middleware.InvokeAsync(context);

        Assert.Equal(499, context.Response.StatusCode);
        Assert.Equal(0, context.Response.Body.Length);
    }

    [Fact]
    public async Task CancellationWithoutClientDisconnectIsNotSuppressed()
    {
        var middleware = new RequestCancellationMiddleware(_ => throw new TaskCanceledException());
        await Assert.ThrowsAsync<TaskCanceledException>(() => middleware.InvokeAsync(new DefaultHttpContext()));
    }

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public async Task TransportFailureIsSuppressedOnlyWhenClientDisconnected(bool disconnected)
    {
        using var cancellation = new CancellationTokenSource();
        var context = new DefaultHttpContext { RequestAborted = cancellation.Token };
        context.Response.Body = new MemoryStream();
        var failure = new HttpRequestException("Connection aborted", new IOException("Socket aborted"));
        var middleware = new RequestCancellationMiddleware(_ =>
        {
            if (disconnected) cancellation.Cancel();
            throw failure;
        });
        if (disconnected)
        {
            await middleware.InvokeAsync(context);
            Assert.Equal(499, context.Response.StatusCode);
            Assert.Equal(0, context.Response.Body.Length);
        }
        else
            Assert.Same(failure, await Assert.ThrowsAsync<HttpRequestException>(() => middleware.InvokeAsync(context)));
    }

    [Fact]
    public async Task OtherFailuresAreNotSuppressedEvenAfterClientDisconnect()
    {
        using var cancellation = new CancellationTokenSource();
        var context = new DefaultHttpContext { RequestAborted = cancellation.Token };
        var middleware = new RequestCancellationMiddleware(_ => { cancellation.Cancel(); throw new InvalidOperationException("Database failure"); });
        await Assert.ThrowsAsync<InvalidOperationException>(() => middleware.InvokeAsync(context));
    }

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public async Task DisconnectSuppressesSocketIoButPreservesFileIoFailure(bool socketFailure)
    {
        using var cancellation = new CancellationTokenSource();
        var context = new DefaultHttpContext { RequestAborted = cancellation.Token };
        context.Response.Body = new MemoryStream();
        var failure = new IOException("I/O aborted", socketFailure
            ? new System.Net.Sockets.SocketException((int)System.Net.Sockets.SocketError.OperationAborted) : null);
        var middleware = new RequestCancellationMiddleware(_ => { cancellation.Cancel(); throw failure; });
        if (socketFailure)
        {
            await middleware.InvokeAsync(context);
            Assert.Equal(499, context.Response.StatusCode);
            Assert.Equal(0, context.Response.Body.Length);
        }
        else
            Assert.Same(failure, await Assert.ThrowsAsync<IOException>(() => middleware.InvokeAsync(context)));
    }

    [Fact]
    public async Task AlreadyAbortedRequestNeverStartsAuthenticationOrAuthorization()
    {
        var called = false;
        var middleware = new RequestCancellationMiddleware(_ => { called = true; return Task.CompletedTask; });
        var context = new DefaultHttpContext { RequestAborted = new CancellationToken(true) };
        await middleware.InvokeAsync(context);
        Assert.False(called);
        Assert.Equal(499, context.Response.StatusCode);
    }
}
