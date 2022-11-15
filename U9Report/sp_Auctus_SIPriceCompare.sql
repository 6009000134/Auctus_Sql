
/*
�����ˣ���ƽ��
����ʱ�䣺2022-02-28
���󣺻�Դ�ȼ۱������Ƚ�����Ӧ����λ��ǰ�ļ۸��Ƿ����
*/	
ALTER  PROC [dbo].[sp_Auctus_SIPriceCompare]
(
@Org BIGINT,
@ItemID BIGINT,
@Supplier BIGINT
)
AS
BEGIN
	
IF OBJECT_ID(N'tempdb.dbo.#temptable',N'U') is NULL
BEGIN 
	CREATE TABLE #temptable
	(
	[OrgName] [nvarchar] (255) NULL,
	[Code] [nvarchar] (255) NOT NULL,
	[Name] [nvarchar] (255) NOT NULL,
	[SPECS] [nvarchar] (300)  NULL,
	[PurchaseName] [nvarchar] (500) NULL,
	[SupplierName] [nvarchar] (255) NULL,
	[PrivateDescSeg3] [nvarchar] (1000)  NULL,
	[OrderNO] [int] NOT NULL,
	[SupplierQuota] [decimal] (24, 9) NOT NULL,
	[ID] [bigint] NOT NULL,
	[PPRCode] [nvarchar] (50)  NOT NULL,
	[Org] [bigint] NOT NULL,
	[DocLineNo] [int] NOT NULL,
	[NetPrice] [numeric] (38, 6) NULL,
	[Price] [decimal] (38, 7) NULL,
	[IsIncludeTax] [bit] NOT NULL,
	[Active] [bit] NULL,
	[FromDate] [datetime] NOT NULL,
	[ToDate] [datetime] NOT NULL,
	[PurchaseQuotaMode] [int] NULL,
	[RN] [bigint] NULL
	) 
END 
ELSE
BEGIN
	TRUNCATE TABLE #temptable
END

	DECLARE @tb NVARCHAR(MAX)=''
	SET @tb='insert into #TempTable SELECT *  FROM (
	SELECT 
	o.Name OrgName,m.Code,m.Name,m.SPECS,dbo.F_GetEnumName(''UFIDA.U9.CBO.SCM.Item.PurchaseQuotaModeEnum'',p.PurchaseQuotaMode,''zh-cn'')PurchaseName
	,sup1.Name SupplierName,sup.DescFlexField_PrivateDescSeg3 PrivateDescSeg3,c.OrderNO,c.SupplierQuota
	,a.ID,a.Code PPRCode,a.Org,b.DocLineNo
	,CASE WHEN a.IsIncludeTax=1 THEN  b.Price*dbo.fn_GetCurrentRate(a.Currency,1,CONVERT(DATE,GETDATE()),2)/1.13 ELSE  b.Price*dbo.fn_GetCurrentRate(a.Currency,1,CONVERT(DATE,GETDATE()),2) END NetPrice
	,b.Price*dbo.fn_GetCurrentRate(a.Currency,1,CONVERT(DATE,GETDATE()),2)Price
	,a.IsIncludeTax,b.Active,b.FromDate,b.ToDate
	,p.PurchaseQuotaMode
	,ROW_NUMBER() OVER(PARTITION BY m.Code,c.SupplierInfo_Supplier ORDER BY b.FromDate DESC)RN
	FROM dbo.PPR_PurPriceList a INNER JOIN dbo.PPR_PurPriceLine b ON a.ID=b.PurPriceList
	INNER JOIN dbo.CBO_SupplySource c ON a.Supplier=c.SupplierInfo_Supplier AND b.ItemInfo_ItemID=c.ItemInfo_ItemID
	INNER JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID
	INNER JOIN dbo.CBO_PurchaseInfo p ON m.ID=p.ItemMaster
	INNER JOIN dbo.CBO_Supplier_Trl sup1 ON c.SupplierInfo_Supplier=sup1.ID
	INNER JOIN dbo.CBO_Supplier sup ON c.SupplierInfo_Supplier=sup.ID AND sup.DescFlexField_PrivateDescSeg3 NOT IN (''OT01'',''NEI01'')
	INNER JOIN dbo.Base_Organization_Trl o ON m.Org=o.ID AND o.SysMLFlag=''zh-cn''	WHERE  m.ItemFormAttribute=9 AND m.Org=@Org AND  b.Active=1 	AND b.ToDate>GETDATE()	AND c.Effective_IsEffective=1'

	IF ISNULL(@ItemID,0)!=0
	SET @tb=@tb+'  and m.ID in (SELECT strid FROM dbo.fun_Cust_StrToTable2(@ItemID,'','')) '
	IF ISNULL(@Supplier,0)!=0
	SET @tb=@tb+'  and sup.ID in (SELECT strid FROM dbo.fun_Cust_StrToTable2(@Supplier,'','')) '
	SET @tb=@tb+'	
	)t WHERE t.rn=1 '
	EXEC sp_executesql @tb,N'@Org bigint,@ItemID bigint,@Supplier bigint',@Org,@ItemID,@Supplier
	;WITH data1 AS
	(
	SELECT * FROM #TempTable a WHERE PurchaseQuotaMode!=4
	),
	data2 AS
	(
	SELECT *,ROW_NUMBER()OVER(PARTITION BY a.Code ORDER BY a.SupplierQuota) RN2 FROM  #TempTable a WHERE PurchaseQuotaMode=4
	),
	GroupData AS
	(
	SELECT 
	a.Org,a.Code,MIN(a.OrderNO)MinOrderNo,AVG(a.NetPrice)AvgPrice,MAX(a.NetPrice)MaxPrice,MIN(a.NetPrice)MinPrice
	FROM data1 a
	GROUP BY a.Org,a.Code
	),
	GroupData1 AS
	(
	SELECT 
	a.Org,a.Code,MIN(a.RN2)MinOrderNo,AVG(a.NetPrice)AvgPrice,MAX(a.NetPrice)MaxPrice,MIN(a.NetPrice)MinPrice
	FROM data2 a
	GROUP BY a.Org,a.Code
	),Result AS
    (
	SELECT 
	a.OrgName,a.Code,a.Name,a.SPECS,a.PurchaseName,a.SupplierName,a.PrivateDescSeg3,a.OrderNO,a.SupplierQuota,a.PPRCode,a.DocLineNo
	,a.Price,a.NetPrice
	,CASE WHEN a.IsIncludeTax=1 THEN '��' ELSE '��' END IsIncludeTax
	,a.FromDate,a.ToDate,b.AvgPrice,b.MinPrice,b.MaxPrice,b.MinOrderNo
	,CASE WHEN a.NetPrice=b.MinPrice THEN '��' ELSE '��' END IsLowestPrice
	FROM data1 a INNER JOIN GroupData b ON a.Org=b.Org AND a.Code=b.Code 
	AND a.OrderNO=b.MinOrderNo
	UNION ALL 
	SELECT 
	a.OrgName,a.Code,a.Name,a.SPECS,a.PurchaseName,a.SupplierName,a.PrivateDescSeg3,a.OrderNO,a.SupplierQuota,a.PPRCode,a.DocLineNo
	,a.Price,a.NetPrice
	,CASE WHEN a.IsIncludeTax=1 THEN '��' ELSE '��' END IsIncludeTax
	,FORMAT(a.FromDate,'yyyy-MM-dd')FromDate,FORMAT(a.ToDate,'yyyy-MM-dd')ToDate,b.AvgPrice,b.MinPrice,b.MaxPrice,b.MinOrderNo
	,CASE WHEN a.NetPrice=b.MinPrice THEN '��' ELSE '��' END IsLowestPrice
	FROM data2 a INNER JOIN GroupData1 b ON a.Org=b.Org AND a.Code=b.Code 
	AND a.OrderNO=b.MinOrderNo AND a.RN2=1
	)	SELECT * FROM Result a	ORDER BY a.OrgName,a.Code

END 
GO