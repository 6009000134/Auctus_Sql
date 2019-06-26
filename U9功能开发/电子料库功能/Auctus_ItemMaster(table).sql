/****** Object:  Table [dbo].[Auctus_ItemMaster]    Script Date: 2018/8/24 10:48:32 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Auctus_ItemMaster](
	[ID] [INT] IDENTITY(1,1) NOT NULL,
	[ComponentType] [INT] NULL,
	OrderNo VARCHAR(30),--��ѡ˳��
	[MainItemCategory] [VARCHAR](10) NULL,
	[Code] [VARCHAR](50) NULL,
	[Name] [NVARCHAR](255) NULL,
	[SPEC] [NVARCHAR](300) NULL,
	[Supplier] [NVARCHAR](30) NULL,
	[Supplier_Code] [NVARCHAR](30) NULL,
	[PickOrder] [INT] NULL,
	[Price] [DECIMAL](18, 4) NULL,
	[PLMExportState] [NVARCHAR](4) NULL,
	[IntendState] [NVARCHAR](4) NULL,
	[Purchase] [VARCHAR](20) NULL,
	[PLMExportDate] [DATETIME] NULL,
	[PLMIntroducation] [VARCHAR](50) NULL,
	[Project] [NVARCHAR](50) NULL,
	[DocLineNo] [INT] NULL,
 CONSTRAINT [PK_Auctus_ItemMaster] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'��Ʒ����' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Auctus_ItemMaster', @level2type=N'COLUMN',@level2name=N'ComponentType'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'������' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Auctus_ItemMaster', @level2type=N'COLUMN',@level2name=N'MainItemCategory'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'�Ϻ�' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Auctus_ItemMaster', @level2type=N'COLUMN',@level2name=N'Code'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Ʒ��' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Auctus_ItemMaster', @level2type=N'COLUMN',@level2name=N'Name'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'���' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Auctus_ItemMaster', @level2type=N'COLUMN',@level2name=N'SPEC'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'������' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Auctus_ItemMaster', @level2type=N'COLUMN',@level2name=N'Supplier'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'�����̱���' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Auctus_ItemMaster', @level2type=N'COLUMN',@level2name=N'Supplier_Code'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'��ѡ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Auctus_ItemMaster', @level2type=N'COLUMN',@level2name=N'PickOrder'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'�۸�' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Auctus_ItemMaster', @level2type=N'COLUMN',@level2name=N'Price'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'PLM����״̬' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Auctus_ItemMaster', @level2type=N'COLUMN',@level2name=N'PLMExportState'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'����״̬' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Auctus_ItemMaster', @level2type=N'COLUMN',@level2name=N'IntendState'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'U9�ɹ����' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Auctus_ItemMaster', @level2type=N'COLUMN',@level2name=N'Purchase'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'PLM����ʱ��' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Auctus_ItemMaster', @level2type=N'COLUMN',@level2name=N'PLMExportDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'PLMϵͳ�����' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Auctus_ItemMaster', @level2type=N'COLUMN',@level2name=N'PLMIntroducation'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'��Ŀ����' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Auctus_ItemMaster', @level2type=N'COLUMN',@level2name=N'Project'
GO


