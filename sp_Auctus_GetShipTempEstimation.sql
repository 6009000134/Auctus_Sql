USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_GetShipTempEstimation]    Script Date: 2021/10/29 15:47:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
--需求人：向华静
根据时间抓取已审核的出货单和出货行
Add 2021-10-29
增加 @NotEqualItem条件
*/
ALTER PROC [dbo].[sp_Auctus_GetShipTempEstimation]
(
@Org VARCHAR(200),
@DocType NVARCHAR(1000),
@StartDate DATE,
@EndDate DATE,
@NotEqualItem NVARCHAR(100)
)
AS 
BEGIN 
--DECLARE @StartDate DATE,@EndDate DATE
--DECLARE @Org VARCHAR(200)='1001708020135435;1001708020135665;1001712010015192'
--DECLARE @DocType NVARCHAR(1000),@NotEqualItem NVARCHAR(100)
--SET @StartDate='2018-06-01'
--SET @EndDate=GETDATE()
--SET @DocType='标准销售出货,标准出货(功放产品),寄售销售出货,国内销售出货,海外销售出货,标准出货'
SET @Org=REPLACE(@Org,';',',')

IF ISNULL(@NotEqualItem,'')=''
BEGIN
	SELECT t.DocNo 单号,CONVERT(VARCHAR(100),t.ShipConfirmDate,111) 出货确认日,t.物料编码,t.产品机型,t.币种,t.单价RMB,t.原币价,t.产品类型
	,t.客户,t.客户简称,t.销售员,CONVERT(DECIMAL(18,0),SUM(t.QtyPriceAmount))计价数量,CONVERT(DECIMAL(18,4),SUM(t.QtyPriceAmount)*t.单价RMB)总价RMB
	FROM (
	SELECT a.DocNo,a.ShipConfirmDate,b.ItemInfo_ItemName 产品机型,b.ItemInfo_ItemCode 物料编码
	,n1.Name 币种
	,CASE WHEN a.Org=1001712010015192 THEN CONVERT(DECIMAL(18,10),dbo.fn_CustGetCurrentRate(a.AC,1,b.ShipConfirmDate,2)*b.FinallyPrice) 
	WHEN a.AC=1 THEN CONVERT(DECIMAL(18,10),b.FinallyPrice/(1+b.TaxRate)) 
	ELSE CONVERT(DECIMAL(18,10),a.ACToFCExRate*b.FinallyPrice)
	END 单价RMB
	,CONVERT(DECIMAL(18,10),b.FinallyPrice) 原币价
	,dbo.fun_Auctus_GetProductType(m.DescFlexField_PrivateDescSeg9,GETDATE(),'zh-cn') 产品类型
	,d1.Name 客户,d.ShortName 客户简称,f1.Name 销售员,b.QtyPriceAmount
	--,a.DocNo,a.Status 单据状态,b.DocLineNo,b.status Line_Status
	FROM dbo.SM_Ship a LEFT JOIN dbo.SM_ShipLine b ON a.ID=b.Ship
	LEFT JOIN dbo.SM_ShipDocType c ON a.DocumentType=c.ID LEFT JOIN dbo.SM_ShipDocType_Trl c1 ON c.ID=c1.ID
	LEFT JOIN dbo.CBO_Customer d ON a.OrderBy_Customer=d.ID LEFT JOIN dbo.CBO_Customer_Trl d1 ON d.ID=d1.ID
	LEFT JOIN dbo.SM_SO e ON b.SONo=e.DocNo 
	LEFT JOIN CBO_Operators f ON e.DescFlexField_PubDescSeg6=f.Code LEFT JOIN dbo.CBO_Operators_Trl f1 ON f.ID=f1.ID AND f1.SysMLFlag='zh-cn'
	LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID
	LEFT JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID
	LEFT JOIN dbo.Base_Currency n ON a.AC=n.ID LEFT JOIN dbo.Base_Currency_Trl n1 ON n.ID=n1.ID
	WHERE c1.SysMLFlag='zh-cn' AND d1.SysMLFlag='zh-cn'  AND o1.SysMLFlag='zh-cn' AND n1.SysMLFlag='zh-cn'
	AND c1.name IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@DocType))
	AND a.Org IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Org)) 
	AND a.BusinessDate BETWEEN @StartDate AND @EndDate
	AND a.Status=3 AND b.Status=3
	) t
	GROUP BY t.DocNo,t.ShipConfirmDate,t.物料编码,t.产品机型,t.币种,t.单价RMB,t.原币价,t.产品类型
	,t.客户,t.客户简称,t.销售员
	ORDER BY t.客户,t.物料编码
END
ELSE
BEGIN
	SELECT t.DocNo 单号,CONVERT(VARCHAR(100),t.ShipConfirmDate,111) 出货确认日,t.物料编码,t.产品机型,t.币种,t.单价RMB,t.原币价,t.产品类型
	,t.客户,t.客户简称,t.销售员,CONVERT(DECIMAL(18,0),SUM(t.QtyPriceAmount))计价数量 ,CONVERT(DECIMAL(18,4),SUM(t.QtyPriceAmount)*t.单价RMB)总价RMB
	FROM (
	SELECT a.DocNo,a.ShipConfirmDate,b.ItemInfo_ItemName 产品机型,b.ItemInfo_ItemCode 物料编码
	,n1.Name 币种
	,CASE WHEN a.Org=1001712010015192 THEN CONVERT(DECIMAL(18,10),dbo.fn_CustGetCurrentRate(a.AC,1,b.ShipConfirmDate,2)*b.FinallyPrice) 
	WHEN a.AC=1 THEN CONVERT(DECIMAL(18,10),b.FinallyPrice/(1+b.TaxRate)) 
	ELSE CONVERT(DECIMAL(18,10),a.ACToFCExRate*b.FinallyPrice)
	END 单价RMB
	,CONVERT(DECIMAL(18,10),b.FinallyPrice) 原币价
	,dbo.fun_Auctus_GetProductType(m.DescFlexField_PrivateDescSeg9,GETDATE(),'zh-cn') 产品类型
	,d1.Name 客户,d.ShortName 客户简称,f1.Name 销售员,b.QtyPriceAmount
	--,a.DocNo,a.Status 单据状态,b.DocLineNo,b.status Line_Status
	FROM dbo.SM_Ship a LEFT JOIN dbo.SM_ShipLine b ON a.ID=b.Ship
	LEFT JOIN dbo.SM_ShipDocType c ON a.DocumentType=c.ID LEFT JOIN dbo.SM_ShipDocType_Trl c1 ON c.ID=c1.ID
	LEFT JOIN dbo.CBO_Customer d ON a.OrderBy_Customer=d.ID LEFT JOIN dbo.CBO_Customer_Trl d1 ON d.ID=d1.ID
	LEFT JOIN dbo.SM_SO e ON b.SONo=e.DocNo 
	LEFT JOIN CBO_Operators f ON e.DescFlexField_PubDescSeg6=f.Code LEFT JOIN dbo.CBO_Operators_Trl f1 ON f.ID=f1.ID AND f1.SysMLFlag='zh-cn'
	LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID
	LEFT JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID
	LEFT JOIN dbo.Base_Currency n ON a.AC=n.ID LEFT JOIN dbo.Base_Currency_Trl n1 ON n.ID=n1.ID
	WHERE c1.SysMLFlag='zh-cn' AND d1.SysMLFlag='zh-cn'  AND o1.SysMLFlag='zh-cn' AND n1.SysMLFlag='zh-cn'
	AND c1.name IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@DocType))
	AND a.Org IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Org)) 
	AND a.BusinessDate BETWEEN @StartDate AND @EndDate
	AND a.Status=3 AND b.Status=3
	AND PATINDEX('%'+@NotEqualItem+'%',m.Name)=0
	) t
	GROUP BY t.DocNo,t.ShipConfirmDate,t.物料编码,t.产品机型,t.币种,t.单价RMB,t.原币价,t.产品类型
	,t.客户,t.客户简称,t.销售员
	ORDER BY t.客户,t.物料编码
END 
END
