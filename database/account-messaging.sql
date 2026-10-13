USE [JobTot];
GO
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261006035053_AddAccountMessaging'
)
BEGIN
    CREATE TABLE [ChatConversations] (
        [Id] uniqueidentifier NOT NULL,
        [PairKey] nvarchar(73) NOT NULL,
        [FirstAccountId] uniqueidentifier NOT NULL,
        [SecondAccountId] uniqueidentifier NOT NULL,
        [CreatedAt] datetimeoffset NOT NULL,
        CONSTRAINT [PK_ChatConversations] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_ChatConversations_Account_FirstAccountId] FOREIGN KEY ([FirstAccountId]) REFERENCES [Account] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_ChatConversations_Account_SecondAccountId] FOREIGN KEY ([SecondAccountId]) REFERENCES [Account] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261006035053_AddAccountMessaging'
)
BEGIN
    CREATE TABLE [ChatMessages] (
        [Id] bigint NOT NULL IDENTITY,
        [ConversationId] uniqueidentifier NOT NULL,
        [SenderAccountId] uniqueidentifier NOT NULL,
        [ClientMessageId] uniqueidentifier NOT NULL,
        [Text] nvarchar(4000) NOT NULL,
        [SentAt] datetimeoffset NOT NULL,
        CONSTRAINT [PK_ChatMessages] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_ChatMessages_Account_SenderAccountId] FOREIGN KEY ([SenderAccountId]) REFERENCES [Account] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_ChatMessages_ChatConversations_ConversationId] FOREIGN KEY ([ConversationId]) REFERENCES [ChatConversations] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261006035053_AddAccountMessaging'
)
BEGIN
    CREATE INDEX [IX_ChatConversations_FirstAccountId] ON [ChatConversations] ([FirstAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261006035053_AddAccountMessaging'
)
BEGIN
    CREATE UNIQUE INDEX [IX_ChatConversations_PairKey] ON [ChatConversations] ([PairKey]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261006035053_AddAccountMessaging'
)
BEGIN
    CREATE INDEX [IX_ChatConversations_SecondAccountId] ON [ChatConversations] ([SecondAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261006035053_AddAccountMessaging'
)
BEGIN
    CREATE INDEX [IX_ChatMessages_ConversationId_Id] ON [ChatMessages] ([ConversationId], [Id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261006035053_AddAccountMessaging'
)
BEGIN
    CREATE UNIQUE INDEX [IX_ChatMessages_SenderAccountId_ClientMessageId] ON [ChatMessages] ([SenderAccountId], [ClientMessageId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261006035053_AddAccountMessaging'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261006035053_AddAccountMessaging', N'9.0.9');
END;

COMMIT;
GO

