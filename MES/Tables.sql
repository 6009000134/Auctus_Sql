DECLARE @Delete VARCHAR(2)='0'
/*
工单主计划表
一条线(AssemblyLineID)、一个计划日期（AssemblyDate）只有一条记录，记录不可删除或修改
即组装线1在2019-6-27会有一条数据
即组装线2在2019-6-27也会有一条数据

*/
IF @Delete='1'
BEGIN
DROP TABLE [mxqh_plAssemblyPlan]
END 
CREATE TABLE [dbo].[mxqh_plAssemblyPlan](
	[ID] [INT] NOT NULL IDENTITY(1,1),
	CreateBy VARCHAR(30),
	CreateDate DATETIME,
	ModifyBy VARCHAR(30),
	ModifyDate DATETIME,
	[AssemblyDate] DATE NOT NULL,--计划日期
	[AssemblyLineID] [INT] NOT NULL,--线别档案
	[AssemblyLineCode] [NVARCHAR](10) NULL,
	[AssemblyLineName] [NVARCHAR](50) NULL,
	[VesionNo] [NVARCHAR](20) NULL,
 CONSTRAINT [PK_mxqh_plAssemblyPlan] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

--ALTER TABLE [dbo].[plAssemblyPlan] ADD  CONSTRAINT [DF_plAssemblyPlan_TS]  DEFAULT (GETDATE()) FOR [TS]
--GO

--ALTER TABLE [dbo].[plAssemblyPlan]  WITH CHECK ADD  CONSTRAINT [FK_plAssemblyPlan_baAssemblyLine] FOREIGN KEY([AssemblyLineID])
--REFERENCES [dbo].[baAssemblyLine] ([ID])
--GO

--ALTER TABLE [dbo].[plAssemblyPlan] CHECK CONSTRAINT [FK_plAssemblyPlan_baAssemblyLine]
--GO



/*
工单主计划详情表
*/
IF @Delete='1'
BEGIN
DROP TABLE [mxqh_plAssemblyPlanDetail]
END 
CREATE TABLE [dbo].[mxqh_plAssemblyPlanDetail](
	[ID] [INT] NOT NULL IDENTITY(1,1),
	CreateBy VARCHAR(30),
	CreateDate DATETIME,
	ModifyBy VARCHAR(30),
	ModifyDate DATETIME,
	[AssemblyPlanID] [INT] NOT NULL,
	[ListNo] VARCHAR(30) NOT NULL,--序号，默认设置成yyyyMMddxxx格式
	[WorkOrder] [NVARCHAR](20) NOT NULL,
	[MaterialID] [INT] NOT NULL,--料品档案 
	[MaterialCode] [NVARCHAR](30) NULL,
	[MaterialName] [NVARCHAR](50) NULL,
	[Quantity] [INT] NOT NULL,--数量
	[OnlineTime] [NVARCHAR](20) NOT NULL,--开始时间
	[OfflineTime] [NVARCHAR](20) NOT NULL,--结束时间
	[CustomerOrder] [NVARCHAR](20) NULL,
	[DeliveryDate] [NVARCHAR](20) NULL,--计划交期
	[CustomerID] [INT] NULL,--客户档案
	[CustomerCode] [NVARCHAR](20) NULL,
	[CustomerName] [NVARCHAR](30) NULL,
	[SendPlaceID] [INT] NOT NULL,--出货地档案
	[SendPlaceCode] [NVARCHAR](20) NULL,
	[SendPlaceName] [NVARCHAR](50) NULL,
	[IsPublish] [BIT] NOT NULL,
	[IsLock] [BIT] NOT NULL,
	[Status] INT,--单据状态 0\1\2\3\4\5  开立\审核中\已审核\完工关闭\作废
	--[ExtendOne] [NVARCHAR](50) NULL,
	--[ExtendTwo] [NVARCHAR](50) NULL,
	--[ExtendThree] [NVARCHAR](50) NULL,
	[CompleteDate] DATETIME,
	[ERPSO] [NVARCHAR](100) NULL,
	[ERPMO] [NVARCHAR](100) NULL,
	[ERPQuantity] [INT] NOT NULL,
	[ERPOrderNo] [NVARCHAR](50) NULL,
	[ERPOrderQty] [INT] NULL,
	[IsUpload] [BIT] NOT NULL DEFAULT (0),
	[boRoutingID] INT,--工艺ID
	[TbName] VARCHAR(30),--SN编码规则 前缀
	[ClName] VARCHAR(30),--SN编码规则 后缀
	[Remark] NVARCHAR(4000),
	MinWeight DECIMAL(18,4) DEFAULT(100),
	MaxWeight DECIMAL(18,4) DEFAULT(200),
 CONSTRAINT [PK_mxqh_plAssemblyPlanDetail] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


--ALTER TABLE [dbo].[plAssemblyPlanDetail] ADD  CONSTRAINT [DF_plAssemblyPlanDetail_TS]  DEFAULT (GETDATE()) FOR [TS]
--GO

--ALTER TABLE [dbo].[plAssemblyPlanDetail] ADD  CONSTRAINT [DF_plAssemblyPlanDetail_ERPQuantity]  DEFAULT ((0)) FOR [ERPQuantity]
--GO

--ALTER TABLE [dbo].[plAssemblyPlanDetail]  WITH CHECK ADD  CONSTRAINT [FK_plAssemblyPlanDetail_baCustom] FOREIGN KEY([CustomerID])
--REFERENCES [dbo].[baCustom] ([ID])
--GO

--ALTER TABLE [dbo].[plAssemblyPlanDetail] CHECK CONSTRAINT [FK_plAssemblyPlanDetail_baCustom]
--GO

--ALTER TABLE [dbo].[plAssemblyPlanDetail]  WITH CHECK ADD  CONSTRAINT [FK_plAssemblyPlanDetail_baMaterial] FOREIGN KEY([MaterialID])
--REFERENCES [dbo].[baMaterial] ([ID])
--GO

--ALTER TABLE [dbo].[plAssemblyPlanDetail] CHECK CONSTRAINT [FK_plAssemblyPlanDetail_baMaterial]
--GO

--ALTER TABLE [dbo].[plAssemblyPlanDetail]  WITH CHECK ADD  CONSTRAINT [FK_plAssemblyPlanDetail_baSendPlace] FOREIGN KEY([SendPlaceID])
--REFERENCES [dbo].[baSendPlace] ([ID])
--GO

--ALTER TABLE [dbo].[plAssemblyPlanDetail] CHECK CONSTRAINT [FK_plAssemblyPlanDetail_baSendPlace]
--GO

--ALTER TABLE [dbo].[plAssemblyPlanDetail]  WITH CHECK ADD  CONSTRAINT [FK_plAssemblyPlanDetail_plAssemblyPlan] FOREIGN KEY([AssemblyPlanID])
--REFERENCES [dbo].[plAssemblyPlan] ([ID])
--GO

--ALTER TABLE [dbo].[plAssemblyPlanDetail] CHECK CONSTRAINT [FK_plAssemblyPlanDetail_plAssemblyPlan]
--GO
