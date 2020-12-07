CREATE TABLE [dbo].[mxqh_Equipment]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[CreateBy] [nvarchar] (50) COLLATE Chinese_PRC_CI_AS NULL,
[CreateDate] [datetime] NULL CONSTRAINT [DF__mxqh_Equi__Creat__47140943] DEFAULT (getdate()),
[ModifyBy] [nvarchar] (50) COLLATE Chinese_PRC_CI_AS NULL,
[ModifyDate] [datetime] NULL CONSTRAINT [DF__mxqh_Equi__Modif__48082D7C] DEFAULT (getdate()),
[Code] [nvarchar] (300) COLLATE Chinese_PRC_CI_AS NULL,
[Name] [nvarchar] (300) COLLATE Chinese_PRC_CI_AS NULL,
[TypeID] [int] NULL,
[TypeCode] [nvarchar] (300) COLLATE Chinese_PRC_CI_AS NULL,
[TypeName] [nvarchar] (300) COLLATE Chinese_PRC_CI_AS NULL,
[Type] [nvarchar] (300) COLLATE Chinese_PRC_CI_AS NULL,
[CheckUOM] [int] NULL,
[UpperLimit] [decimal] (18, 4) NULL,
[LowerLimit] [decimal] (18, 4) NULL,
[Remark] [nvarchar] (600) COLLATE Chinese_PRC_CI_AS NULL,
IsActive INT--0/1--Õ£”√/∆Ù”√
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mxqh_Equipment] ADD CONSTRAINT [PK__mxqh_Equ__3214EC27CDADDB88] PRIMARY KEY CLUSTERED ([ID]) ON [PRIMARY]
GO


