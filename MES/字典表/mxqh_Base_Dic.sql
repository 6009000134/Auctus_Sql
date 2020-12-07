CREATE TABLE [dbo].[mxqh_Base_Dic]
(
[ID] [INT] PRIMARY KEY IDENTITY(1, 1),
[CreateBy] [nvarchar] (40) COLLATE Chinese_PRC_CI_AS NULL,
[CreateDate] [datetime] NULL CONSTRAINT [DF__mxqh_Base__Creat__1764F621] DEFAULT (getdate()),
[ModifyBy] [nvarchar] (40) COLLATE Chinese_PRC_CI_AS NULL,
[ModifyDate] [datetime] NULL CONSTRAINT [DF__mxqh_Base__Modif__18591A5A] DEFAULT (getdate()),
[Code] [nvarchar] (300) COLLATE Chinese_PRC_CI_AS NULL,--×Öµä±àÂë
[Name] [nvarchar] (300) COLLATE Chinese_PRC_CI_AS NULL,--×ÖµäÃû³Æ
[TypeCode] [nvarchar] (300) COLLATE Chinese_PRC_CI_AS NULL,--×Öµä·ÖÀà±àÂë
[TypeName] [nvarchar] (300) COLLATE Chinese_PRC_CI_AS NULL,--×Öµä·ÖÀàÃû³Æ
IsActive INT DEFAULT(1),
[OrderNo] [int] NULL CONSTRAINT [DF__mxqh_Base__Order__194D3E93] DEFAULT ((0))
)
