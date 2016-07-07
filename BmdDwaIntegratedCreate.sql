/*
Deployment script for BmdDwaIntegrated
*/

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

SET NUMERIC_ROUNDABORT OFF;


GO
:setvar DatabaseName "BmdDwaIntegrated"
:setvar DefaultFilePrefix "BmdDwaIntegrated"
:setvar DefaultDataPath ""
:setvar DefaultLogPath ""

GO
:on error exit
GO
/*
Detect SQLCMD mode and disable script execution if SQLCMD mode is not supported.
To re-enable the script after enabling SQLCMD mode, execute the following:
SET NOEXEC OFF; 
*/
:setvar __IsSqlCmdEnabled "True"
GO
IF N'$(__IsSqlCmdEnabled)' NOT LIKE N'True'
    BEGIN
        PRINT N'SQLCMD mode must be enabled to successfully execute this script.';
        SET NOEXEC ON;
    END


GO
USE [master];


GO

IF (DB_ID(N'$(DatabaseName)') IS NOT NULL) 
BEGIN
    ALTER DATABASE [$(DatabaseName)]
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$(DatabaseName)];
END

GO
PRINT N'Creating $(DatabaseName)...'
GO
CREATE DATABASE [$(DatabaseName)] COLLATE SQL_Latin1_General_CP1_CI_AS
GO
IF EXISTS (SELECT 1
           FROM   [master].[dbo].[sysdatabases]
           WHERE  [name] = N'$(DatabaseName)')
    BEGIN
        ALTER DATABASE [$(DatabaseName)]
            SET ANSI_NULLS ON,
                ANSI_PADDING ON,
                ANSI_WARNINGS ON,
                ARITHABORT ON,
                CONCAT_NULL_YIELDS_NULL ON,
                NUMERIC_ROUNDABORT OFF,
                QUOTED_IDENTIFIER ON,
                ANSI_NULL_DEFAULT ON,
                CURSOR_DEFAULT LOCAL,
                RECOVERY FULL,
                CURSOR_CLOSE_ON_COMMIT OFF,
                AUTO_CREATE_STATISTICS ON,
                AUTO_SHRINK OFF,
                AUTO_UPDATE_STATISTICS ON,
                RECURSIVE_TRIGGERS OFF 
            WITH ROLLBACK IMMEDIATE;
        ALTER DATABASE [$(DatabaseName)]
            SET AUTO_CLOSE OFF 
            WITH ROLLBACK IMMEDIATE;
    END


GO
IF EXISTS (SELECT 1
           FROM   [master].[dbo].[sysdatabases]
           WHERE  [name] = N'$(DatabaseName)')
    BEGIN
        ALTER DATABASE [$(DatabaseName)]
            SET ALLOW_SNAPSHOT_ISOLATION OFF;
    END


GO
IF EXISTS (SELECT 1
           FROM   [master].[dbo].[sysdatabases]
           WHERE  [name] = N'$(DatabaseName)')
    BEGIN
        ALTER DATABASE [$(DatabaseName)]
            SET READ_COMMITTED_SNAPSHOT OFF 
            WITH ROLLBACK IMMEDIATE;
    END


GO
IF EXISTS (SELECT 1
           FROM   [master].[dbo].[sysdatabases]
           WHERE  [name] = N'$(DatabaseName)')
    BEGIN
        ALTER DATABASE [$(DatabaseName)]
            SET AUTO_UPDATE_STATISTICS_ASYNC OFF,
                PAGE_VERIFY NONE,
                DATE_CORRELATION_OPTIMIZATION OFF,
                DISABLE_BROKER,
                PARAMETERIZATION SIMPLE,
                SUPPLEMENTAL_LOGGING OFF 
            WITH ROLLBACK IMMEDIATE;
    END


GO
IF IS_SRVROLEMEMBER(N'sysadmin') = 1
    BEGIN
        IF EXISTS (SELECT 1
                   FROM   [master].[dbo].[sysdatabases]
                   WHERE  [name] = N'$(DatabaseName)')
            BEGIN
                EXECUTE sp_executesql N'ALTER DATABASE [$(DatabaseName)]
    SET TRUSTWORTHY OFF,
        DB_CHAINING OFF 
    WITH ROLLBACK IMMEDIATE';
            END
    END
ELSE
    BEGIN
        PRINT N'The database settings cannot be modified. You must be a SysAdmin to apply these settings.';
    END


GO
IF IS_SRVROLEMEMBER(N'sysadmin') = 1
    BEGIN
        IF EXISTS (SELECT 1
                   FROM   [master].[dbo].[sysdatabases]
                   WHERE  [name] = N'$(DatabaseName)')
            BEGIN
                EXECUTE sp_executesql N'ALTER DATABASE [$(DatabaseName)]
    SET HONOR_BROKER_PRIORITY OFF 
    WITH ROLLBACK IMMEDIATE';
            END
    END
ELSE
    BEGIN
        PRINT N'The database settings cannot be modified. You must be a SysAdmin to apply these settings.';
    END


GO
ALTER DATABASE [$(DatabaseName)]
    SET TARGET_RECOVERY_TIME = 0 SECONDS 
    WITH ROLLBACK IMMEDIATE;


GO
IF EXISTS (SELECT 1
           FROM   [master].[dbo].[sysdatabases]
           WHERE  [name] = N'$(DatabaseName)')
    BEGIN
        ALTER DATABASE [$(DatabaseName)]
            SET FILESTREAM(NON_TRANSACTED_ACCESS = OFF),
                CONTAINMENT = NONE 
            WITH ROLLBACK IMMEDIATE;
    END


GO
IF EXISTS (SELECT 1
           FROM   [master].[dbo].[sysdatabases]
           WHERE  [name] = N'$(DatabaseName)')
    BEGIN
        ALTER DATABASE [$(DatabaseName)]
            SET AUTO_CREATE_STATISTICS ON(INCREMENTAL = OFF),
                MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = OFF,
                DELAYED_DURABILITY = DISABLED 
            WITH ROLLBACK IMMEDIATE;
    END


GO
USE [$(DatabaseName)];


GO
IF fulltextserviceproperty(N'IsFulltextInstalled') = 1
    EXECUTE sp_fulltext_database 'enable';


GO
PRINT N'Creating [BC\svc-SSIS-proxy-EDW]...';


GO
CREATE USER [BC\svc-SSIS-proxy-EDW] FOR LOGIN [BC\svc-SSIS-proxy-EDW];


GO
REVOKE CONNECT TO [BC\svc-SSIS-proxy-EDW];


GO
PRINT N'Creating <unnamed>...';


GO
EXECUTE sp_addrolemember @rolename = N'db_owner', @membername = N'BC\svc-SSIS-proxy-EDW';


GO
PRINT N'Creating [dbo].[ApplicationEvent]...';


GO
CREATE TABLE [dbo].[ApplicationEvent] (
    [ApplicationEventKeyEDW] BIGINT       NOT NULL,
    [ApplicationKeyEDW]      BIGINT       NOT NULL,
    [FormNumber]             VARCHAR (50) NOT NULL,
    [ApplicationEventSeqNum] INT          NOT NULL,
    [EventTypeCode]          VARCHAR (10) NOT NULL,
    [EventDate]              DATE         NOT NULL,
    [EventTime]              TIME (7)     NULL,
    [StartDateTmeEDW]        DATETIME     NOT NULL,
    [EndDateTmeEDW]          DATETIME     NOT NULL,
    CONSTRAINT [PK_ApplicationEvent] PRIMARY KEY CLUSTERED ([ApplicationEventKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[PersonAliasMatchReference]...';


GO
CREATE TABLE [dbo].[PersonAliasMatchReference] (
    [PersonAliasKeyEDW]   BIGINT       NOT NULL,
    [PartyKeyEDW]         BIGINT       NOT NULL,
    [BmdPartyID]          VARCHAR (50) NULL,
    [PersonAliasSeqNum]   INT          NULL,
    [MatchedFamilyName]   VARCHAR (50) NULL,
    [MatchedGivenNames]   VARCHAR (50) NULL,
    [MatchedGender]       VARCHAR (1)  NULL,
    [MatchedDateOfBirth]  VARCHAR (10) NULL,
    [MatchScore]          FLOAT (53)   NULL,
    [NamePartyRoleSource] VARCHAR (10) NULL,
    [OriginalBmdPartyID]  VARCHAR (50) NULL,
    [StartDateTme]        DATETIME     NULL,
    [EndDateTme]          DATETIME     NULL,
    CONSTRAINT [PK_PersonAliasMatchReference] PRIMARY KEY CLUSTERED ([PersonAliasKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[qa_PersonAliasMatchScores]...';


GO
CREATE TABLE [dbo].[qa_PersonAliasMatchScores] (
    [InputPartyId]      VARCHAR (50) NULL,
    [FamilyName]        VARCHAR (50) NULL,
    [GivenName]         VARCHAR (50) NULL,
    [DOB]               DATE         NULL,
    [Gender]            VARCHAR (1)  NULL,
    [PartyRoleTypeCode] VARCHAR (10) NULL,
    [FormNumber]        VARCHAR (9)  NULL,
    [NameSourceCode]    VARCHAR (10) NULL,
    [newBmdPartyId]     VARCHAR (50) NULL,
    [MatchScore]        REAL         NULL,
    [FamilyNameScore]   REAL         NULL,
    [GivenNameScore]    REAL         NULL
);


GO
PRINT N'Creating [dbo].[PersonAliasSource]...';


GO
CREATE TABLE [dbo].[PersonAliasSource] (
    [PersonAliasSourceKeyEDW] BIGINT       NOT NULL,
    [PersonAliasKeyEDW]       BIGINT       NULL,
    [BmdPartyID]              VARCHAR (50) NULL,
    [PersonAliasSeqNum]       INT          NULL,
    [PersonAliasSourceCode]   VARCHAR (10) NULL,
    [StartDateTmeEDW]         DATETIME     NOT NULL,
    [EndDateTmeEDW]           DATETIME     NOT NULL,
    CONSTRAINT [PK_PersonAliasSource] PRIMARY KEY CLUSTERED ([PersonAliasSourceKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[PersonAlias]...';


GO
CREATE TABLE [dbo].[PersonAlias] (
    [PersonAliasKeyEDW]   BIGINT       NOT NULL,
    [PartyKeyEDW]         BIGINT       NOT NULL,
    [BmdPartyID]          VARCHAR (50) NULL,
    [PersonAliasSeqNum]   INT          NULL,
    [FamilyName]          VARCHAR (50) NULL,
    [GivenNames]          VARCHAR (50) NULL,
    [Gender]              CHAR (1)     NULL,
    [DateOfBirth]         DATE         NULL,
    [BirthNameFlag]       CHAR (1)     NULL,
    [BdmNameFlag]         CHAR (1)     NULL,
    [CitizenshipNameFlag] CHAR (1)     NULL,
    [NameSourceCode]      VARCHAR (10) NULL,
    [StartDateTmeEDW]     DATETIME     NOT NULL,
    [EndDateTmeEDW]       DATETIME     NOT NULL,
    CONSTRAINT [PK_PersonAlias] PRIMARY KEY CLUSTERED ([PersonAliasKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[PartyRoleApplication]...';


GO
CREATE TABLE [dbo].[PartyRoleApplication] (
    [PartyRoleApplicationKeyEDW] BIGINT       NOT NULL,
    [PartyKeyEDW]                BIGINT       NULL,
    [RoleKeyEDW]                 BIGINT       NULL,
    [ApplicationKeyEDW]          BIGINT       NULL,
    [BmdPartyID]                 VARCHAR (50) NULL,
    [PartyRoleTypeCode]          VARCHAR (10) NULL,
    [YearsKnown]                 INT          NULL,
    [MonthsKnown]                INT          NULL,
    [DeclaredRelationship]         VARCHAR (30) NULL,
    [DeclaredOccupation]         VARCHAR (50) NULL,
    [FormNumber]                 VARCHAR (50) NULL,
    [SupportingDocumentKeyEDW]   BIGINT       NULL,
    [SupportingDocumentSeqNum]   INT          NULL,
    [StartDateTmeEDW]            DATETIME     NOT NULL,
    [EndDateTmeEDW]              DATETIME     NOT NULL,
    CONSTRAINT [PK_PartyRoleApplication] PRIMARY KEY CLUSTERED ([PartyRoleApplicationKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[PartyRole]...';


GO
CREATE TABLE [dbo].[PartyRole] (
    [RoleKeyEDW]        BIGINT       NOT NULL,
    [PartyKeyEDW]       BIGINT       NULL,
    [BmdPartyID]        VARCHAR (50) NULL,
    [PartyRoleTypeCode] VARCHAR (10) NULL,
    [StartDateTmeEDW]   DATETIME     NOT NULL,
    [EndDateTmeEDW]     DATETIME     NOT NULL,
    CONSTRAINT [PK_PartyRole] PRIMARY KEY CLUSTERED ([RoleKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[PartyAlertAssociation]...';


GO
CREATE TABLE [dbo].[PartyAlertAssociation] (
    [PartyAlertAssociationKeyEDW] BIGINT       NOT NULL,
    [PartyKeyEDW]                 BIGINT       NULL,
    [BmdPartyID]                  VARCHAR (50) NULL,
    [PartyAlertKeyEDW]            BIGINT       NULL,
    [StartDateTmeEDW]             DATETIME     NOT NULL,
    [EndDateTmeEDW]               DATETIME     NOT NULL,
    CONSTRAINT [PK_PartyAlertAssociation] PRIMARY KEY CLUSTERED ([PartyAlertAssociationKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[PartyAlert]...';


GO
CREATE TABLE [dbo].[PartyAlert] (
    [PartyAlertKeyEDW]    BIGINT       NOT NULL,
    [AlertTypeCode]       VARCHAR (10) NULL,
    [DateRaised]          DATE         NULL,
    [ReviewDate]          DATE         NULL,
    [ExpiryDate]          VARCHAR (10) NULL,
    [DeletedFlag]         CHAR (1)     NULL,
    [UpdatedDate]         DATE         NULL,
    [WotlkFileReferece]    VARCHAR (50) NULL,
    [AgencyFileReference] VARCHAR (50) NULL,
    [StartDateTmeEDW]     DATETIME     NOT NULL,
    [EndDateTmeEDW]       DATETIME     NOT NULL,
    CONSTRAINT [PK_PartyAlert] PRIMARY KEY CLUSTERED ([PartyAlertKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[Party]...';


GO
CREATE TABLE [dbo].[Party] (
    [PartyKeyEDW]         BIGINT       NOT NULL,
    [BmdPartyID]          VARCHAR (50) NOT NULL,
    [PartyTypeCode]       VARCHAR (10) NOT NULL,
    [PreviousPartyKeyEDW] BIGINT       NULL,
    [LacPartyID]         BIGINT       NULL,
    [DocumentOfficeCATA]  VARCHAR (4)  NULL,
    [AgencyName]          VARCHAR (50) NULL,
    [AgencyTypeCode]      INT          NULL,
    [PlaceOfBirth]        VARCHAR (50) NULL,
    [CountryOfBirthCode]  VARCHAR (50) NULL,
    [MothersMaidenName]   VARCHAR (50) NULL,
    [FormalGivenNames]    VARCHAR (50) NULL,
    [FormalFamilyName]    VARCHAR (50) NULL,
    [FormalDOB]           DATE         NULL,
    [FormalGender]        CHAR (1)     NULL,
    [StartDateTmeEDW]     DATETIME     NOT NULL,
    [EndDateTmeEDW]       DATETIME     NOT NULL,
    CONSTRAINT [PK_Party] PRIMARY KEY CLUSTERED ([PartyKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[Narrative]...';


GO
CREATE TABLE [dbo].[Narrative] (
    [NarrativeKeyEDW]             BIGINT        NOT NULL,
    [DocumentKeyEDW]              BIGINT        NULL,
    [DocumentNumber]              VARCHAR (50)  NULL,
    [AssessmentKeyEDW]            BIGINT        NULL,
    [PartyAlertKeyEDW]            BIGINT        NULL,
    [ApplicationKeyEDW]           BIGINT        NULL,
    [NarrativeText]               VARCHAR (MAX) NOT NULL,
    [NarrativeDateTme]            DATETIME      NULL,
    [FormNumber]                  VARCHAR (9)   NULL,
    [ApplicationAssessmentSeqNum] INT           NULL,
    [SupportingDocumentSeqNum]    INT           NULL,
    [StartDateTmeEDW]             DATETIME      NOT NULL,
    [EndDateTmeEDW]               DATETIME      NOT NULL
);


GO
PRINT N'Creating [dbo].[FormalDocument]...';


GO
CREATE TABLE [dbo].[FormalDocument] (
    [DocumentKeyEDW]         BIGINT       NOT NULL,
    [PreviousDocumentKeyEDW] BIGINT       NULL,
    [DocumentNumber]         VARCHAR (50) NOT NULL,
    [DocumentStatusCode]     CHAR (1)     NULL,
    [StatusReason]           VARCHAR (50) NULL,
    [StatusDate]             DATE         NULL,
    [DocumentCategoryCode]   VARCHAR (10) NULL,
    [DocumentType]           VARCHAR (10) NULL,
    [IssueDate]              DATE         NULL,
    [ExpiryDate]             DATE         NULL,
    [ApplicationKeyEDW]      BIGINT       NULL,
    [FormNumber]             VARCHAR (50) NULL,
    [IssuingPartyKeyEDW]     BIGINT       NULL,
    [BmdPartyID]             VARCHAR (50) NULL,
    [StartDateTmeEDW]        DATETIME     NOT NULL,
    [EndDateTmeEDW]          DATETIME     NOT NULL,
    CONSTRAINT [PK_FormalDocument] PRIMARY KEY CLUSTERED ([DocumentKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[Contact]...';


GO
CREATE TABLE [dbo].[Contact] (
    [ContactKeyEDW]         BIGINT       NOT NULL,
    [PartyKeyEDW]           BIGINT       NOT NULL,
    [BmdPartyID]            VARCHAR (50) NOT NULL,
    [RoleApplicationKeyEDW] BIGINT       NOT NULL,
    [MobilePhoneNum]        VARCHAR (20) NULL,
    [DaytimePhoneNum]       VARCHAR (20) NULL,
    [AfterHoursPhoneNum]    VARCHAR (20) NULL,
    [FaxNumber]             VARCHAR (20) NULL,
    [EmailAddress]          VARCHAR (76) NULL,
    [AddressID]             BIGINT       NULL,
    [AddressType]           VARCHAR (10) NULL,
    [StartDateTmeEDW]       DATETIME     NOT NULL,
    [EndDateTmeEDW]         DATETIME     NOT NULL,
    CONSTRAINT [PK_Contact] PRIMARY KEY CLUSTERED ([ContactKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[ApplicationAssessment]...';


GO
CREATE TABLE [dbo].[ApplicationAssessment] (
    [ApplicationAssessmentKeyEDW] BIGINT       NOT NULL,
    [FormNumber]                  VARCHAR (50) NOT NULL,
    [ApplicationAssessmentSeqNum] INT          NOT NULL,
    [AssessmentDate]              DATE         NULL,
    [AssessmentType]              VARCHAR (10) NULL,
    [AssessmentCode]              VARCHAR (10) NULL,
    [AssessmentResult]            VARCHAR (50) NULL,
    [AssessmentDetail]            VARCHAR (76) NULL,
    [ApplicationKeyEDW]           BIGINT       NOT NULL,
    [StartDateTmeEDW]             DATETIME     NOT NULL,
    [EndDateTmeEDW]               DATETIME     NOT NULL,
    CONSTRAINT [PK_ApplicationAssessment] PRIMARY KEY CLUSTERED ([ApplicationAssessmentKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[ApplicationCheck]...';


GO
CREATE TABLE [dbo].[ApplicationCheck] (
    [ApplicationCheckKeyEDW] BIGINT       NOT NULL,
    [FormNumber]             VARCHAR (50) NOT NULL,
    [ApplicationCheckSeqNum] INT          NOT NULL,
    [CheckTypeCode]          VARCHAR (10) NULL,
    [CheckResult]            CHAR (1)     NULL,
    [CheckMode]              VARCHAR (10) NULL,
    [ApplicationKeyEDW]      BIGINT       NOT NULL,
    [StartDateTmeEDW]        DATETIME     NOT NULL,
    [EndDateTmeEDW]          DATETIME     NOT NULL,
    CONSTRAINT [PK_ApplicationCheck] PRIMARY KEY CLUSTERED ([ApplicationCheckKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[Application]...';


GO
CREATE TABLE [dbo].[Application] (
    [ApplicationKeyEDW]           BIGINT       NOT NULL,
    [PrevApplicationKeyEDW]       BIGINT       NULL,
    [FormNumber]                  VARCHAR (9)  NULL,
    [ApplicationTypeCode]         VARCHAR (10) NULL,
    [ApplicationStatusCode]       VARCHAR (10) NULL,
    [ApplicationFamilyName]       VARCHAR (50) NULL,
    [ApplicationGivenNames]       VARCHAR (50) NULL,
    [ApplicationDateOfBirth]      DATE         NULL,
    [ApplicationGender]           CHAR (1)     NULL,
    [ApplicationSignedDate]       DATE         NULL,
    [ApplicationTravel2MonthFlag] CHAR (1)     NULL,
    [ApplicationTravelDate]       DATE         NULL,
    [PaymentMethodCode]           VARCHAR (10) NULL,
    [PaymentDate]                 DATE         NULL,
    [PaymentAmount]               FLOAT (53)   NULL,
    [PriorityFeePaid]             CHAR (1)     NULL,
    [RefundedFlag]                CHAR (1)     NULL,
    [RefundedReasonCode]          VARCHAR (10) NULL,
    [RefundAmount]                FLOAT (53)   NULL,
    [GratisIssueReasonCode]       VARCHAR (10) NULL,
    [FormSource]                  CHAR (1)     NULL,
    [DeclaredDocumentInd]         CHAR (1)     NULL,
    [DeclaredDocumentNumber]      VARCHAR (9)  NULL,
    [WithdrawnReasonCode]         VARCHAR (2)  NULL,
    [PreviousDocStatus]           VARCHAR (1)  NULL,
    [LostDocumentNumber]          VARCHAR (9)  NULL,
    [PoiCombination]              VARCHAR (5)  NULL,
    [StartDateTmeEDW]             DATETIME     NOT NULL,
    [EndDateTmeEDW]               DATETIME     NOT NULL,
    CONSTRAINT [PK_Application] PRIMARY KEY CLUSTERED ([ApplicationKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[AgencyDetail]...';


GO
CREATE TABLE [dbo].[AgencyDetail] (
    [AgencyDetailKeyEDW]          BIGINT       NOT NULL,
    [PartyKeyEDW]                 BIGINT       NULL,
    [BmdPartyID]                  VARCHAR (50) NULL,
    [AgentType]                   VARCHAR (4)  NULL,
    [LacAgencyId]                 INT          NULL,
    [ActiveFlag]                  CHAR (1)     NULL,
    [AverageApplicCategoryCode]   CHAR (1)     NULL,
    [AssociatedBmdOffice]         VARCHAR (4)  NULL,
    [AlternativeBmdOffice]        VARCHAR (4)  NULL,
    [LicencedPostOfficeFlag]      CHAR (1)     NULL,
    [InterviewApprovalStatusCode] CHAR (1)     NULL,
    [DateActive]                  VARCHAR (10) NULL,
    [DateClosed]                  DATE         NULL,
    [RequestDate]                 DATE         NULL,
    [StartDateTmeEDW]             DATETIME     NOT NULL,
    [EndDateTmeEDW]               DATETIME     NOT NULL,
    CONSTRAINT [PK_AgencyDetail] PRIMARY KEY CLUSTERED ([AgencyDetailKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[AddressGNAF]...';


GO
CREATE TABLE [dbo].[AddressGNAF] (
    [GnafAddressDetailPid] VARCHAR (15)    NOT NULL,
    [BuildingName]         VARCHAR (45)    NULL,
    [StreetNumber]         VARCHAR (25)    NULL,
    [StreetName]           VARCHAR (100)   NULL,
    [StreetTypeCode]       VARCHAR (15)    NULL,
    [LocalityName]         VARCHAR (100)   NULL,
    [State]                VARCHAR (3)     NULL,
    [PostCode]             VARCHAR (4)     NULL,
    [Latitude]             NUMERIC (10, 8) NULL,
    [Longitude]            NUMERIC (11, 8) NULL,
    [LegalParcelId]        VARCHAR (20)    NULL,
    [StartDateTme]         DATETIME        NOT NULL,
    [EndDateTme]           DATETIME        NOT NULL,
    CONSTRAINT [PK_AddressGNAF] PRIMARY KEY CLUSTERED ([GnafAddressDetailPid] ASC)
);


GO
PRINT N'Creating [dbo].[Address]...';


GO
CREATE TABLE [dbo].[Address] (
    [AddressKeyEDW]        BIGINT       NOT NULL,
    [PostCode]             VARCHAR (4)  NULL,
    [Surburb]              VARCHAR (50) NULL,
    [CountryCode]          VARCHAR (50) NULL,
    [AddressLine1]         VARCHAR (50) NULL,
    [AddressLine2]         VARCHAR (50) NULL,
    [AddressLine3]         VARCHAR (50) NULL,
    [A_State]              VARCHAR (3)  NULL,
    [A_Zip]                VARCHAR (10) NULL,
    [A_CountryScannedText] VARCHAR (30) NULL,
    [GnafAddressDetailPid] VARCHAR (15) NULL,
    [StartDateTmeEDW]      DATETIME     NOT NULL,
    [EndDateTmeEDW]        DATETIME     NOT NULL,
    CONSTRAINT [PK_Address] PRIMARY KEY CLUSTERED ([AddressKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[SupportingDocument]...';


GO
CREATE TABLE [dbo].[SupportingDocument] (
    [SupportingDocumentKeyEDW]     BIGINT           NOT NULL,
    [FormNumber]                   VARCHAR (50)     NULL,
    [SupportingDocumentSeqNum]     INT              NULL,
    [PrevSupportingDocumentKeyEDW] BIGINT           NULL,
    [SupportingDocumentTypeCode]   VARCHAR (10)     NULL,
    [DocumentSightedFlag]          CHAR (1)         NULL,
    [SupportingDocNumber]          VARCHAR (50)     NULL,
    [IssuingState]                 VARCHAR (50)     NULL,
    [IssueDate]                    DATE             NULL,
    [ExpiryDate]                   DATE             NULL,
    [RegistrationDate]             DATE             NULL,
    [FamilyName]                   VARCHAR (50)     NULL,
    [GivenNames]                   VARCHAR (50)     NULL,
    [CitzOtherNosOnDocument]       VARCHAR (50)     NULL,
    [BirthFatherGivenNames]        VARCHAR (50)     NULL,
    [BirthFatherFamilyName]        VARCHAR (50)     NULL,
    [BirthMotherGivenNames]        VARCHAR (50)     NULL,
    [BirthMotherFamilyName]        VARCHAR (50)     NULL,
    [CourtName]                    VARCHAR (50)     NULL,
    [NameChangeReason]             CHAR (1)         NULL,
    [ErAddressID]                  UNIQUEIDENTIFIER NULL,
    [PartyAlertKeyEDW]             BIGINT           NULL,
    [ApplicationKeyEDW]            BIGINT           NULL,
    [StartDateTmeEDW]              DATETIME         NOT NULL,
    [EndDateTmeEDW]                DATETIME         NOT NULL,
    CONSTRAINT [PK_SupportingDocument] PRIMARY KEY CLUSTERED ([SupportingDocumentKeyEDW] ASC)
);


GO
PRINT N'Creating [dbo].[FK_ApplicationEvent_Application]...';


GO
ALTER TABLE [dbo].[ApplicationEvent]
    ADD CONSTRAINT [FK_ApplicationEvent_Application] FOREIGN KEY ([ApplicationKeyEDW]) REFERENCES [dbo].[Application] ([ApplicationKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_PersonAliasMatchReference_PersonAlias]...';


GO
ALTER TABLE [dbo].[PersonAliasMatchReference]
    ADD CONSTRAINT [FK_PersonAliasMatchReference_PersonAlias] FOREIGN KEY ([PersonAliasKeyEDW]) REFERENCES [dbo].[PersonAlias] ([PersonAliasKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_PersonAliasSource_PersonAlias]...';


GO
ALTER TABLE [dbo].[PersonAliasSource]
    ADD CONSTRAINT [FK_PersonAliasSource_PersonAlias] FOREIGN KEY ([PersonAliasKeyEDW]) REFERENCES [dbo].[PersonAlias] ([PersonAliasKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_PersonAlias_Party]...';


GO
ALTER TABLE [dbo].[PersonAlias]
    ADD CONSTRAINT [FK_PersonAlias_Party] FOREIGN KEY ([PartyKeyEDW]) REFERENCES [dbo].[Party] ([PartyKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_PartyRoleApplication_Party]...';


GO
ALTER TABLE [dbo].[PartyRoleApplication]
    ADD CONSTRAINT [FK_PartyRoleApplication_Party] FOREIGN KEY ([PartyKeyEDW]) REFERENCES [dbo].[Party] ([PartyKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_PartyRoleApplication_Role]...';


GO
ALTER TABLE [dbo].[PartyRoleApplication]
    ADD CONSTRAINT [FK_PartyRoleApplication_Role] FOREIGN KEY ([RoleKeyEDW]) REFERENCES [dbo].[PartyRole] ([RoleKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_PartyRoleApplication_Application]...';


GO
ALTER TABLE [dbo].[PartyRoleApplication]
    ADD CONSTRAINT [FK_PartyRoleApplication_Application] FOREIGN KEY ([ApplicationKeyEDW]) REFERENCES [dbo].[Application] ([ApplicationKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_PartyRole_Party]...';


GO
ALTER TABLE [dbo].[PartyRole]
    ADD CONSTRAINT [FK_PartyRole_Party] FOREIGN KEY ([PartyKeyEDW]) REFERENCES [dbo].[Party] ([PartyKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_PartyAlertAssociation_Party]...';


GO
ALTER TABLE [dbo].[PartyAlertAssociation]
    ADD CONSTRAINT [FK_PartyAlertAssociation_Party] FOREIGN KEY ([PartyKeyEDW]) REFERENCES [dbo].[Party] ([PartyKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_PartyAlertAssociation_PartyAlert]...';


GO
ALTER TABLE [dbo].[PartyAlertAssociation]
    ADD CONSTRAINT [FK_PartyAlertAssociation_PartyAlert] FOREIGN KEY ([PartyAlertKeyEDW]) REFERENCES [dbo].[Party] ([PartyKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_Party_Party]...';


GO
ALTER TABLE [dbo].[Party]
    ADD CONSTRAINT [FK_Party_Party] FOREIGN KEY ([PreviousPartyKeyEDW]) REFERENCES [dbo].[Party] ([PartyKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_FormalDocument_Application]...';


GO
ALTER TABLE [dbo].[FormalDocument]
    ADD CONSTRAINT [FK_FormalDocument_Application] FOREIGN KEY ([ApplicationKeyEDW]) REFERENCES [dbo].[Application] ([ApplicationKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_FormalDocument_Party]...';


GO
ALTER TABLE [dbo].[FormalDocument]
    ADD CONSTRAINT [FK_FormalDocument_Party] FOREIGN KEY ([IssuingPartyKeyEDW]) REFERENCES [dbo].[Party] ([PartyKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_FormalDocument_FormalDocument]...';


GO
ALTER TABLE [dbo].[FormalDocument]
    ADD CONSTRAINT [FK_FormalDocument_FormalDocument] FOREIGN KEY ([PreviousDocumentKeyEDW]) REFERENCES [dbo].[FormalDocument] ([DocumentKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_Contact_Party]...';


GO
ALTER TABLE [dbo].[Contact]
    ADD CONSTRAINT [FK_Contact_Party] FOREIGN KEY ([PartyKeyEDW]) REFERENCES [dbo].[Party] ([PartyKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_Contact_PartyRoleApplication]...';


GO
ALTER TABLE [dbo].[Contact]
    ADD CONSTRAINT [FK_Contact_PartyRoleApplication] FOREIGN KEY ([RoleApplicationKeyEDW]) REFERENCES [dbo].[PartyRoleApplication] ([PartyRoleApplicationKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_Contact_Address]...';


GO
ALTER TABLE [dbo].[Contact]
    ADD CONSTRAINT [FK_Contact_Address] FOREIGN KEY ([AddressID]) REFERENCES [dbo].[Address] ([AddressKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_ApplicationAssessment_Application]...';


GO
ALTER TABLE [dbo].[ApplicationAssessment]
    ADD CONSTRAINT [FK_ApplicationAssessment_Application] FOREIGN KEY ([ApplicationKeyEDW]) REFERENCES [dbo].[Application] ([ApplicationKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_ApplicationCheck_Application]...';


GO
ALTER TABLE [dbo].[ApplicationCheck]
    ADD CONSTRAINT [FK_ApplicationCheck_Application] FOREIGN KEY ([ApplicationKeyEDW]) REFERENCES [dbo].[Application] ([ApplicationKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_Application_ToApplication]...';


GO
ALTER TABLE [dbo].[Application]
    ADD CONSTRAINT [FK_Application_ToApplication] FOREIGN KEY ([PrevApplicationKeyEDW]) REFERENCES [dbo].[Application] ([ApplicationKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_AgencyDetail_Party]...';


GO
ALTER TABLE [dbo].[AgencyDetail]
    ADD CONSTRAINT [FK_AgencyDetail_Party] FOREIGN KEY ([PartyKeyEDW]) REFERENCES [dbo].[Party] ([PartyKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_Address_AddressGNAF]...';


GO
ALTER TABLE [dbo].[Address]
    ADD CONSTRAINT [FK_Address_AddressGNAF] FOREIGN KEY ([GnafAddressDetailPid]) REFERENCES [dbo].[AddressGNAF] ([GnafAddressDetailPid]);


GO
PRINT N'Creating [dbo].[FK_SupportingDocument_SupportingDocument]...';


GO
ALTER TABLE [dbo].[SupportingDocument]
    ADD CONSTRAINT [FK_SupportingDocument_SupportingDocument] FOREIGN KEY ([PrevSupportingDocumentKeyEDW]) REFERENCES [dbo].[SupportingDocument] ([SupportingDocumentKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_SupportingDocument_Application]...';


GO
ALTER TABLE [dbo].[SupportingDocument]
    ADD CONSTRAINT [FK_SupportingDocument_Application] FOREIGN KEY ([ApplicationKeyEDW]) REFERENCES [dbo].[Application] ([ApplicationKeyEDW]);


GO
PRINT N'Creating [dbo].[FK_SupportingDocument_PartyAlert]...';


GO
ALTER TABLE [dbo].[SupportingDocument]
    ADD CONSTRAINT [FK_SupportingDocument_PartyAlert] FOREIGN KEY ([PartyAlertKeyEDW]) REFERENCES [dbo].[PartyAlert] ([PartyAlertKeyEDW]);


GO
PRINT N'Creating [dbo].[vw_AgencyDetail]...';


GO

CREATE VIEW [dbo].[vw_AgencyDetail]
AS
SELECT * 
FROM dbo.AgencyDetail
GO
PRINT N'Creating [dbo].[vw_Address]...';


GO


CREATE VIEW [dbo].[vw_Address]
AS
SELECT * 
FROM dbo.Address
GO
PRINT N'Creating [dbo].[vw_PersonAliasMatchReference]...';


GO

CREATE VIEW [dbo].[vw_PersonAliasMatchReference]
AS
SELECT * 
FROM dbo.PersonAliasMatchReference
GO
PRINT N'Creating [dbo].[vw_AddressGNAF]...';


GO

CREATE VIEW [dbo].[vw_AddressGNAF]
AS
SELECT * 
FROM dbo.AddressGNAF
GO
PRINT N'Creating [dbo].[vw_SupportingDocument]...';


GO

CREATE VIEW [dbo].[vw_SupportingDocument]
AS
SELECT * 
FROM dbo.SupportingDocument
GO
PRINT N'Creating [dbo].[vw_PersonAliasSource]...';


GO

CREATE VIEW [dbo].[vw_PersonAliasSource]
AS
SELECT * 
FROM dbo.PersonAliasSource
GO
PRINT N'Creating [dbo].[vw_PersonAlias]...';


GO

CREATE VIEW [dbo].[vw_PersonAlias]
AS
SELECT * 
FROM dbo.PersonAlias
GO
PRINT N'Creating [dbo].[vw_PartyRoleApplication]...';


GO

CREATE VIEW [dbo].[vw_PartyRoleApplication]
AS
SELECT * 
FROM dbo.PartyRoleApplication
GO
PRINT N'Creating [dbo].[vw_PartyRole]...';


GO

CREATE VIEW [dbo].[vw_PartyRole]
AS
SELECT * 
FROM dbo.PartyRole
GO
PRINT N'Creating [dbo].[vw_PartyAlertAssociation]...';


GO

CREATE VIEW [dbo].[vw_PartyAlertAssociation]
AS
SELECT * 
FROM dbo.PartyAlertAssociation
GO
PRINT N'Creating [dbo].[vw_PartyAlert]...';


GO

CREATE VIEW [dbo].[vw_PartyAlert]
AS
SELECT * 
FROM dbo.PartyAlert
GO
PRINT N'Creating [dbo].[vw_Party]...';


GO

CREATE VIEW [dbo].[vw_Party]
AS
SELECT * 
FROM dbo.Party
GO
PRINT N'Creating [dbo].[vw_Narrative]...';


GO

CREATE VIEW [dbo].[vw_Narrative]
AS
SELECT * 
FROM dbo.Narrative
GO
PRINT N'Creating [dbo].[vw_FormalDocument]...';


GO

CREATE VIEW [dbo].[vw_FormalDocument]
AS
SELECT * 
FROM dbo.FormalDocument
GO
PRINT N'Creating [dbo].[vw_Contact]...';


GO

CREATE VIEW [dbo].[vw_Contact]
AS
SELECT * 
FROM dbo.Contact
GO
PRINT N'Creating [dbo].[vw_ApplicationEvent]...';


GO

CREATE VIEW [dbo].[vw_ApplicationEvent]
AS
SELECT * 
FROM dbo.ApplicationEvent
GO
PRINT N'Creating [dbo].[vw_ApplicationAssessment]...';


GO


CREATE VIEW [dbo].[vw_ApplicationAssessment]
AS
SELECT * 
FROM dbo.ApplicationAssessment
GO
PRINT N'Creating [dbo].[vw_ApplicationCheck]...';


GO

CREATE VIEW [dbo].[vw_ApplicationCheck]
AS
SELECT * 
FROM dbo.ApplicationCheck
GO
PRINT N'Creating [dbo].[vw_Application]...';


GO

CREATE VIEW [dbo].[vw_Application]
AS
SELECT * 
FROM dbo.Application
GO
-- Refactoring step to update target server with deployed transaction logs

IF OBJECT_ID(N'dbo.__RefactorLog') IS NULL
BEGIN
    CREATE TABLE [dbo].[__RefactorLog] (OperationKey UNIQUEIDENTIFIER NOT NULL PRIMARY KEY)
    EXEC sp_addextendedproperty N'microsoft_database_tools_support', N'refactoring log', N'schema', N'dbo', N'table', N'__RefactorLog'
END
GO
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = '04e1fca7-dc99-47cb-b77e-65b93636c077')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('04e1fca7-dc99-47cb-b77e-65b93636c077')
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = '1278b137-47fa-48c8-b604-ff357041023e')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('1278b137-47fa-48c8-b604-ff357041023e')
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = '5204d82e-85c7-443f-8751-f6ad3750efcc')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('5204d82e-85c7-443f-8751-f6ad3750efcc')

GO

GO
DECLARE @VarDecimalSupported AS BIT;

SELECT @VarDecimalSupported = 0;

IF ((ServerProperty(N'EngineEdition') = 3)
    AND (((@@microsoftversion / power(2, 24) = 9)
          AND (@@microsoftversion & 0xffff >= 3024))
         OR ((@@microsoftversion / power(2, 24) = 10)
             AND (@@microsoftversion & 0xffff >= 1600))))
    SELECT @VarDecimalSupported = 1;

IF (@VarDecimalSupported > 0)
    BEGIN
        EXECUTE sp_db_vardecimal_storage_format N'$(DatabaseName)', 'ON';
    END


GO
ALTER DATABASE [$(DatabaseName)]
    SET MULTI_USER 
    WITH ROLLBACK IMMEDIATE;


GO
PRINT N'Update complete.';


GO
