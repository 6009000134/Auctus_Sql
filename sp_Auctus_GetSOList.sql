USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_GetSOList]    Script Date: 2018/8/14 10:14:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[sp_Auctus_GetSOList]
(
@Org VARCHAR(100),
@DocNo VARCHAR(1000),
@StartDate DATETIME,
@EndDate DATETIME
)
AS
BEGIN
--DECLARE @Org VARCHAR(100)='100'
--DECLARE @DocNo VARCHAR(1000)='11'
--DECLARE @StartDate DATETIME='2018-05-01'
--DECLARE @EndDate DATETIME='2018-06-01'
DECLARE @StartDate2 VARCHAR(20)
DECLARE @EndDate2 VARCHAR(20)
IF ISNULL(@StartDate,'')=''
SET @StartDate='2000-01-01'

IF ISNULL(@EndDate,'')=''
SET @EndDate='9999-01-01'
SET @StartDate2=CHAR(39)+CONVERT(VARCHAR(20),@StartDate,111)+CHAR(39)
SET @EndDate2=CHAR(39)+CONVERT(VARCHAR(20),@EndDate,111)+CHAR(39)
DECLARE @sql NVARCHAR(4000)
SET @sql='SELECT  o1.Name
,a.OrderBy_ShortName
,a.DocNo,b.DocLineNo
,b.ItemInfo_ItemCode,b.ItemInfo_ItemName
,b.OrderByQtyPU
,s1.Name DocType
,p1.Name AC
,a.ACToFCRate
,CASE a.IsPriceIncludeTax
WHEN 0 THEN b.OrderPriceTC
ELSE b.OrderPriceTC/(1+b.TaxRate) END OrderPriceTC
--,b.OrderPriceTC
,b.NetMoneyTC
,b.TotalMoneyTC
,b.NetMoneyTC*a.ACToFCRate 金额本位币--金额本位币
,c.PlanDate
,a.ConfirmTerm
,ar1.Name
,n1.PersonName_DisplayName 销售员
,n.PersonName_DisplayName 业务助理
,dbo.F_GetEnumName(''UFIDA.U9.SM.SO.SODocStatusEnum'',a.Status,''zh-CN'')Status
,dbo.F_GetEnumName(''UFIDA.U9.SM.SO.SODocStatusEnum'',b.Status,''zh-CN'')SOLine_Status
,dbo.F_GetEnumName(''UFIDA.U9.Base.Currency.ExchangeRateTypesEnum'',a.ACToFCRateType,''zh-CN'')ACToFCRateType
,a.IsPriceIncludeTax
,b.TaxRate
--,a.Seller--业务员
--,a.DescFlexField_PubDescSeg6--销售员
--,b.FreeType--免费品类型
,dbo.F_GetEnumName(''UFIDA.U9.CBO.SCM.Enums.FreeTypeEnum'',b.FreeType,''zh-CN'') FreeType
--计划出货日期
FROM dbo.SM_SO a LEFT JOIN dbo.SM_SOLine b ON a.ID=b.SO LEFT JOIN dbo.SM_SOShipline c ON c.SOLine=b.ID
LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID
LEFT JOIN dbo.SM_SODocType S ON a.DocumentType=s.ID LEFT JOIN dbo.SM_SODocType_Trl s1 ON s.ID=s1.ID
LEFT JOIN dbo.CBO_Operators m ON a.Seller=m.ID LEFT JOIN Base_Contact n ON m.Contact=n.ID
LEFT JOIN dbo.CBO_Operators m1 ON a.DescFlexField_PubDescSeg6=m1.Code LEFT JOIN Base_Contact n1 ON m1.Contact=n1.ID
LEFT JOIN dbo.Base_Currency p ON a.AC=p.ID
LEFT JOIN dbo.Base_Currency_Trl p1 ON p.ID=p1.ID
LEFT JOIN dbo.CBO_ARConfirmTerm ar ON a.ConfirmTerm=ar.ID
LEFT JOIN dbo.CBO_ARConfirmTerm_Trl ar1 ON ar.ID=ar1.ID
WHERE o1.SysMLFlag=''zh-CN'' AND s1.SysMLFlag=''zh-CN'' AND P1.SysMLFlag=''zh-CN'' AND ar1.SysMLFlag=''zh-CN'' 
AND a.BusinessDate between '+@StartDate2+' and '+@EndDate2 

IF ISNULL(@org,'')=''
BEGIN
SET @sql=@sql+' and o.Code in (select distinct Code from Base_Organization) '
END 
ELSE
BEGIN
SET @Org=CHAR(39)+REPLACE(@Org,',',char(39)+','+char(39))+CHAR(39)
SET @sql=@sql+' AND o.Code IN ('+@Org+') '
END
IF ISNULL(@DocNo,'')<>''
BEGIN
SET @DocNo=CHAR(39)+REPLACE(@DocNo,',',char(39)+','+char(39))+CHAR(39)
SET @sql=@sql+' AND a.DocNo in ('+@DocNo+')'
END
SET @sql=@sql+' ORDER BY a.DocNo,b.DocLineNo'

--PRINT @sql
EXEC(@sql)

END


