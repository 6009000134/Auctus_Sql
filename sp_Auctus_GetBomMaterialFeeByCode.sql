USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_GetBomMaterialFeeByCode]    Script Date: 2018/8/14 10:13:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--从销售角度和产出角度分别找出 毛利率=毛利/BOM无软件成本
--BOM有效期设置了在2018-06-20之前
--组织是写死了，取采购价时优先取300，没有的再去取200
ALTER  PROC [dbo].[sp_Auctus_GetBomMaterialFeeByCode]
(
@Org BIGINT,
@Code VARCHAR(50),
@DisplayName VARCHAR(20),--期间
@IsStandard VARCHAR(20)
)
AS
BEGIN
--DECLARE @Org BIGINT=1001708020135665
--DECLARE @Code VARCHAR(50)=''
--DECLARE @DisplayName VARCHAR(20)=''
--DECLARE @IsStandard VARCHAR(20)='2'


DECLARE @AccountingPeriod BIGINT
--DECLARE @DisplayName VARCHAR(50)='2018-06'
--SET @DisplayName='2017-09'
--根据会计期间获取查询时间区间
DECLARE @FromDate DATETIME,@ToDate DATETIME
IF ISNULL(@DisplayName,'')='' AND ISNULL(@Code,'')=''
BEGIN
SET @FromDate='2018-07-01'
SET @ToDate=GETDATE()
END
ELSE IF ISNULL(@DisplayName,'')=''
BEGIN
SET @FromDate='2000-07-01'
SET @ToDate=GETDATE()
END
ELSE 
BEGIN
SELECT @FromDate=c.FromDate,@AccountingPeriod=c.ID FROM dbo.Base_SOBAccountingPeriod a LEFT JOIN dbo.Base_SetofBooks b ON a.SetofBooks=b.ID 
LEFT JOIN dbo.Base_AccountingPeriod c ON a.AccountPeriod=c.ID
WHERE b.Org=@Org 
AND c.DisplayName=@DisplayName 
--AND c.ID=@AccountingPeriod
SET @ToDate=DATEADD(MONTH,1,@FromDate)
END

IF OBJECT_ID(N'tempdb.dbo.#tempSoCost',N'U') IS NULL
BEGIN
CREATE TABLE  #tempSoCost (ShipNo VARCHAR(50),ShipLineNo VARCHAR(50),ItemInfo_ItemID VARCHAR(50),ItemInfo_ItemCode VARCHAR(50),
ItemInfo_ItemName VARCHAR(50), QtyPriceAmount DECIMAL(18,2),OrderPrice DECIMAL(18,4),TotalNetMoney DECIMAL(18,4),
TotalMoneyTC DECIMAL(18,4),TaxRate DECIMAL(18,4),AC INT,DemandCode INT)
END
ELSE
BEGIN
TRUNCATE TABLE #tempSoCost
END

DECLARE @Sql NVARCHAR(4000)
SET @Sql=' Insert Into #tempSoCost
SELECT a.DocNo ShipNo,--出货单号
b.DocLineNo ShipLineNo,--出货单行
b.ItemInfo_ItemID,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,--料品信息
b.QtyPriceAmount,--计价数量
b.OrderPrice/(1+b.TaxRate) OrderPrice,--未税单价
b.TotalNetMoney*a.ACToFCExRate TotalNetMoney,--未税金额
b.TotalMoneyTC,--税价合计
b.TaxRate,--税率
a.AC,
b.DemandCode--需求分类号
FROM dbo.SM_Ship a LEFT JOIN dbo.SM_ShipLine b ON a.ID=b.Ship
WHERE a.ShipConfirmDate BETWEEN @FromDate AND @ToDate AND a.Status=3  AND b.status=3 and a.Org=@Org and b.Org=@Org '
 IF ISNULL(@Code,'')=''
 BEGIN
 SET @Sql=@Sql+ ' and (b.ItemInfo_ItemCode LIKE ''1%'' OR b.ItemInfo_ItemCode LIKE ''2%'') '
 END
 ELSE
 BEGIN
 SET @Sql=@Sql+ ' and b.ItemInfo_ItemCode=@Code '
 END

 EXEC sp_executesql @Sql,N'@FromDate datetime,@ToDate datetime,@Org Bigint,@Code varchar(50)',@FromDate,@ToDate,@Org,@Code
--标准生产材料费取最新版本
--标准材料物料集合
IF object_id(N'tempdb.dbo.#tempItem',N'U') is NULL
begin
CREATE TABLE #tempItem(MasterBom BIGINT,MasterCode varchar(50),ThisUsageQty decimal(18,8),PID BIGINT,MID BIGINT,Code VARCHAR(50),Seq INT,ComponentType INT,SubSeq int)
END
ELSE
BEGIN
TRUNCATE TABLE #tempItem
END

 --最终结果集
IF object_id(N'tempdb.dbo.#tempResult',N'U') is NULL
BEGIN
CREATE TABLE #tempResult (MasterBom BIGINT,MasterCode BIGINT,PID BIGINT,ThisUsageQty DECIMAL(18,8),MID BIGINT,Code VARCHAR(20),
StandardPrice DECIMAL(18,8),PPR_Price DECIMAL(18,8),Seq INT,ComponentType VARCHAR(4),SubSeq INT,Total DECIMAL(18,8),PPR_Total DECIMAL(18,8))

END
ELSE
BEGIN
TRUNCATE TABLE #tempResult
END 

IF ISNULL(@IsStandard,'')<>'2'
BEGIN


----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
INSERT INTO #tempItem SELECT t.id,t.ItemInfo_ItemCode,t1.ThisUsageQty,t1.PID,t1.MID,t1.Code,t1.Sequence,t1.ComponentType,t1.SubSeq FROM (
SELECT a.ItemInfo_ItemCode MasterCode,b.id,a.ItemInfo_ItemCode 
,ROW_NUMBER()OVER(PARTITION BY a.ItemInfo_ItemCode ORDER BY b.BOMVersion DESC) rn 
FROM #tempSoCost a LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemInfo_ItemCode=c.Code LEFT JOIN dbo.CBO_BOMMaster b ON c.ID=b.ItemMaster
WHERE b.Org=@Org AND b.BOMType=0 AND b.AlternateType=0 
AND b.EffectiveDate<'2018-05-31'
 ) t LEFT JOIN dbo.Auctus_NewestBom_Test t1 ON t.ID=t1.MasterBom
 WHERE t.rn=1 AND  t1.Code NOT LIKE 'S%' AND t1.Code NOT LIKE '401%' AND t1.Code NOT LIKE '403%' AND t1.IsExpand=1
 AND t1.ComponentType=0
 --GROUP BY t.id
 --SELECT * FROM dbo.CBO_BOMMaster  WHERE ItemMaster=1001708090021645
 
 ;
 WITH PPRData AS 
 (
 SELECT * FROM (SELECT   a1.ItemInfo_ItemCode,
						CASE WHEN a2.currency=1 AND  a2.IsIncludeTax = 1 						THEN ISNULL(Price, 0)/1.16
						WHEN a2.Currency=1 AND a2.IsIncludeTax=0						THEN ISNULL(Price, 0)
						WHEN a2.Currency!=1 AND a2.IsIncludeTax=1						THEN ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2)/1.16
						ELSE ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2) END Price,
						ROW_NUMBER()OVER(PARTITION BY a1.ItemInfo_ItemCode ORDER BY a2.Org DESC,a1.FromDate DESC) AS rowNum					--倒序排生效日
				FROM    PPR_PurPriceLine a1 RIGHT JOIN #tempItem c ON a1.ItemInfo_ItemCode=c.Code
						INNER JOIN PPR_PurPriceList a2 ON a1.PurPriceList = a2.ID AND a2.Status = 2 AND a2.Cancel_Canceled = 0 AND a1.Active = 1
				WHERE   NOT EXISTS ( SELECT 1 FROM CBO_Supplier WHERE DescFlexField_PrivateDescSeg3 = 'OT01' AND a2.Supplier = ID ) AND 
						a2.Org IN( @Org,1001708020135435)
						--a2.Org=1001708020135665
						AND a1.FromDate <= GETDATE())
						t WHERE t.rowNum=1
 ),
 MInfo AS
 (
 SELECT a.MasterBom,a.MasterCode,a.PID,a.ThisUsageQty,a.MID,a.Code,ISNULL(c.StandardPrice,ISNULL(d.Price,0))StandardPrice,ISNULL(d.Price,0)PPR_Price
 ,a.Seq,a.ComponentType,a.SubSeq
 --,c.StandardPrice StandardPrice2,d.Price--测试价格来源
 FROM #tempItem a LEFT JOIN #tempItem b ON a.MID=b.PID AND a.MasterBom=b.MasterBom
 LEFT JOIN dbo.Auctus_ItemStandardPrice c ON a.MID=c.ItemId 
 AND c.LogTime=dbo.fun_Auctus_GetInventoryDate(@ToDate)
 --AND c.LogTime='2018-05-01'
 LEFT JOIN PPRData d ON a.Code=d.ItemInfo_ItemCode
 WHERE b.PID IS NULL 
 )
 INSERT INTO #tempResult
 SELECT *,MInfo.StandardPrice*MInfo.ThisUsageQty total,MInfo.PPR_Price*MInfo.ThisUsageQty ppr_total
  FROM MInfo ORDER BY MInfo.MasterBom,MInfo.Code
 ;
 WITH 
 ReplaceInfo AS--价格为0的标准料
 (
 SELECT b.MasterBom,b.MasterCode,b.PID,b.ThisUsageQty,b.MID,b.Code,b.Sequence,b.ComponentType,b.SubSeq 
 FROM #tempResult a INNER JOIN dbo.Auctus_NewestBom_Test b ON a.MasterBom=b.MasterBom AND a.PID=b.PID AND a.seq=b.Sequence
 WHERE a.StandardPrice=0 AND b.ComponentType=2 --AND a.Code<>b.Code 
 ),
 PPRData2 AS 
 (
 SELECT * FROM (SELECT   a1.ItemInfo_ItemCode,
						CASE WHEN a2.currency=1 AND  a2.IsIncludeTax = 1 						THEN ISNULL(Price, 0)/1.16
						WHEN a2.Currency=1 AND a2.IsIncludeTax=0						THEN ISNULL(Price, 0)
						WHEN a2.Currency!=1 AND a2.IsIncludeTax=1						THEN ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2)/1.16
						ELSE ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2) END Price,
						ROW_NUMBER()OVER(PARTITION BY a1.ItemInfo_ItemCode ORDER BY a2.Org DESC,a1.FromDate DESC) AS rowNum					--倒序排生效日
				FROM    PPR_PurPriceLine a1 RIGHT JOIN ReplaceInfo c ON a1.ItemInfo_ItemCode=c.Code
						INNER JOIN PPR_PurPriceList a2 ON a1.PurPriceList = a2.ID AND a2.Status = 2 AND a2.Cancel_Canceled = 0 AND a1.Active = 1
				WHERE   NOT EXISTS ( SELECT 1 FROM CBO_Supplier WHERE DescFlexField_PrivateDescSeg3 = 'OT01' AND a2.Supplier = ID ) AND 
						a2.Org IN( @Org,1001708020135435)
						--a2.Org=1001708020135665
						AND a1.FromDate <= GETDATE())
						t WHERE t.rowNum=1
 ),
 ReplaceInfo2 AS--
 (
 SELECT  a.MasterBom,a.MasterCode,a.PID,a.ThisUsageQty,a.MID,a.Code,ISNULL(b.StandardPrice,ISNULL(c.Price,0))StandardPrice,ISNULL(c.Price,0)PPR_Price
 ,a.Sequence,a.ComponentType,a.SubSeq,
 ROW_NUMBER()OVER(PARTITION BY a.MasterBom,a.PID,a.Sequence ORDER BY a.SubSeq)RN
 FROM ReplaceInfo a LEFT JOIN dbo.Auctus_ItemStandardPrice b ON a.MID=b.ItemId AND b.LogTime=dbo.fun_Auctus_GetInventoryDate(@ToDate)
 LEFT JOIN PPRData2 c ON a.Code=c.ItemInfo_ItemCode
 WHERE b.StandardPrice<>0 AND c.Price<>0--取有价格的替代料
 )
 INSERT INTO #tempResult
 SELECT a.MasterBom,a.MasterCode,a.PID,a.ThisUsageQty,a.MID,a.Code,a.StandardPrice,a.ppr_Price,a.Sequence,dbo.F_GetEnumName('UFIDA.U9.CBO.MFG.Enums.ComponentTypeEnum',a.ComponentType,'zh-cn')ComponentType,a.SubSeq,a.StandardPrice*a.ThisUsageQty,a.PPR_Price*a.ThisUsageQty FROM ReplaceInfo2 a WHERE a.rn=1
 
   SELECT a.MasterBom,a.MasterCode,a.PID,a.ThisUsageQty,a.MID,a.StandardPrice,a.PPR_Price,a.Code,b.Name,a.Seq,dbo.F_GetEnumName('UFIDA.U9.CBO.MFG.Enums.ComponentTypeEnum',a.ComponentType,'zh-cn')ComponentType,a.SubSeq,a.Total,a.PPR_Total,b.SPECS
   FROM #tempResult a LEFT JOIN dbo.CBO_ItemMaster b ON a.MID=b.ID
 ORDER BY a.MasterCode,a.MasterBom,a.PID,a.Seq,a.ComponentType,a.SubSeq


 END --End IF
 ---------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
ELSE 
BEGIN
TRUNCATE TABLE #tempSoCost
IF ISNULL(@Code,'')=''
BEGIN
INSERT #tempSoCost   (ItemInfo_ItemCode) SELECT DISTINCT b.Code ItemInfo_ItemCode FROM dbo.MO_CompleteRpt a LEFT JOIN dbo.CBO_ItemMaster b ON a.Item=b.ID
WHERE a.CompleteDate BETWEEN @FromDate AND @ToDate
END
ELSE
BEGIN
INSERT #tempSoCost   (ItemInfo_ItemCode) SELECT DISTINCT b.Code ItemInfo_ItemCode FROM dbo.MO_CompleteRpt a LEFT JOIN dbo.CBO_ItemMaster b ON a.Item=b.ID
WHERE a.CompleteDate BETWEEN @FromDate AND @ToDate AND b.Code=@Code
END

INSERT INTO #tempItem SELECT t.id,t.ItemInfo_ItemCode,t1.ThisUsageQty,t1.PID,t1.MID,t1.Code,t1.Sequence,t1.ComponentType,t1.SubSeq FROM (
SELECT a.ItemInfo_ItemCode MasterCode,b.id,a.ItemInfo_ItemCode 
,ROW_NUMBER()OVER(PARTITION BY a.ItemInfo_ItemCode ORDER BY b.BOMVersion DESC) rn 
FROM #tempSoCost a LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemInfo_ItemCode=c.Code LEFT JOIN dbo.CBO_BOMMaster b ON c.ID=b.ItemMaster
WHERE b.Org=@Org AND b.BOMType=0 AND b.AlternateType=0 
 ) t LEFT JOIN dbo.Auctus_NewestBom t1 ON t.ID=t1.MasterBom
 WHERE t.rn=1 AND  t1.Code NOT LIKE 'S%' AND t1.Code NOT LIKE '401%' AND t1.Code NOT LIKE '403%' AND t1.IsExpand=1
 AND t1.ComponentType=0
 --GROUP BY t.id
 --SELECT * FROM dbo.CBO_BOMMaster  WHERE ItemMaster=1001708090021645

 ;
 WITH PPRData AS 
 (
 SELECT * FROM (SELECT   a1.ItemInfo_ItemCode,
						CASE WHEN a2.currency=1 AND  a2.IsIncludeTax = 1 						THEN ISNULL(Price, 0)/1.16
						WHEN a2.Currency=1 AND a2.IsIncludeTax=0						THEN ISNULL(Price, 0)
						WHEN a2.Currency!=1 AND a2.IsIncludeTax=1						THEN ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2)/1.16
						ELSE ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2) END Price,
							ROW_NUMBER()OVER(PARTITION BY a1.ItemInfo_ItemCode ORDER BY a2.Org DESC,a1.FromDate DESC) AS rowNum						--倒序排生效日
				FROM    PPR_PurPriceLine a1 RIGHT JOIN #tempItem c ON a1.ItemInfo_ItemCode=c.Code
						INNER JOIN PPR_PurPriceList a2 ON a1.PurPriceList = a2.ID AND a2.Status = 2 AND a2.Cancel_Canceled = 0 AND a1.Active = 1
				WHERE   NOT EXISTS ( SELECT 1 FROM CBO_Supplier WHERE DescFlexField_PrivateDescSeg3 = 'OT01' AND a2.Supplier = ID ) AND 
							a2.Org IN( @Org,1001708020135435)
						--a2.Org=1001708020135665
						AND a1.FromDate <= GETDATE())
						t WHERE t.rowNum=1
 ),
 MInfo AS
 (
 SELECT a.MasterBom,a.MasterCode,a.PID,a.ThisUsageQty,a.MID,a.Code,ISNULL(c.StandardPrice,ISNULL(d.Price,0))StandardPrice,ISNULL(d.Price,0)PPR_Price
 ,a.Seq,a.ComponentType,a.SubSeq
 --,c.StandardPrice StandardPrice2,d.Price--测试价格来源
 FROM #tempItem a LEFT JOIN #tempItem b ON a.MID=b.PID AND a.MasterBom=b.MasterBom
 LEFT JOIN dbo.Auctus_ItemStandardPrice c ON a.MID=c.ItemId 
 AND c.LogTime=dbo.fun_Auctus_GetInventoryDate(@ToDate)
 --AND c.LogTime='2018-05-01'
 LEFT JOIN PPRData d ON a.Code=d.ItemInfo_ItemCode
 WHERE b.PID IS NULL 
 )
 INSERT INTO #tempResult
 SELECT *,MInfo.StandardPrice*MInfo.ThisUsageQty total,MInfo.PPR_Price*MInfo.ThisUsageQty PPR_Total
  FROM MInfo ORDER BY MInfo.MasterBom,MInfo.Code
 ;
 WITH 
 ReplaceInfo AS--价格为0的标准料
 (
 SELECT b.MasterBom,b.MasterCode,b.PID,b.ThisUsageQty,b.MID,b.Code,b.Sequence,b.ComponentType,b.SubSeq 
 FROM #tempResult a INNER JOIN dbo.Auctus_NewestBom b ON a.MasterBom=b.MasterBom AND a.PID=b.PID AND a.seq=b.Sequence
 WHERE a.StandardPrice=0 AND b.ComponentType=2 --AND a.Code<>b.Code 
 ),
 PPRData2 AS 
 (
 SELECT * FROM (SELECT   a1.ItemInfo_ItemCode,
						CASE WHEN a2.currency=1 AND  a2.IsIncludeTax = 1 						THEN ISNULL(Price, 0)/1.16
						WHEN a2.Currency=1 AND a2.IsIncludeTax=0						THEN ISNULL(Price, 0)
						WHEN a2.Currency!=1 AND a2.IsIncludeTax=1						THEN ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2)/1.16
						ELSE ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2) END Price,
							ROW_NUMBER()OVER(PARTITION BY a1.ItemInfo_ItemCode ORDER BY a2.Org DESC,a1.FromDate DESC) AS rowNum						--倒序排生效日
				FROM    PPR_PurPriceLine a1 RIGHT JOIN ReplaceInfo c ON a1.ItemInfo_ItemCode=c.Code
						INNER JOIN PPR_PurPriceList a2 ON a1.PurPriceList = a2.ID AND a2.Status = 2 AND a2.Cancel_Canceled = 0 AND a1.Active = 1
				WHERE   NOT EXISTS ( SELECT 1 FROM CBO_Supplier WHERE DescFlexField_PrivateDescSeg3 = 'OT01' AND a2.Supplier = ID ) AND 
							a2.Org IN( @Org,1001708020135435)
						--a2.Org=1001708020135665
						AND a1.FromDate <= GETDATE())
						t WHERE t.rowNum=1
 ),
 ReplaceInfo2 AS--
 (
SELECT  a.MasterBom,a.MasterCode,a.PID,a.ThisUsageQty,a.MID,a.Code,ISNULL(b.StandardPrice,ISNULL(c.Price,0))StandardPrice,ISNULL(c.Price,0)PPR_Price
 ,a.Sequence,a.ComponentType,a.SubSeq,
 ROW_NUMBER()OVER(PARTITION BY a.MasterBom,a.PID,a.Sequence ORDER BY a.SubSeq)RN
 FROM ReplaceInfo a LEFT JOIN dbo.Auctus_ItemStandardPrice b ON a.MID=b.ItemId AND b.LogTime=dbo.fun_Auctus_GetInventoryDate(@ToDate)
 LEFT JOIN PPRData2 c ON a.Code=c.ItemInfo_ItemCode
 WHERE b.StandardPrice<>0 AND c.Price<>0--取有价格的替代料
 )
 INSERT INTO #tempResult
 SELECT a.MasterBom,a.MasterCode,a.PID,a.ThisUsageQty,a.MID,a.Code,a.StandardPrice,a.PPR_Price,a.Sequence,dbo.F_GetEnumName('UFIDA.U9.CBO.MFG.Enums.ComponentTypeEnum',a.ComponentType,'zh-cn')ComponentType,a.SubSeq,a.StandardPrice*a.ThisUsageQty,a.PPR_Price*a.ThisUsageQty FROM ReplaceInfo2 a WHERE a.rn=1

   SELECT a.MasterBom,a.MasterCode,a.PID,a.ThisUsageQty,a.MID,a.StandardPrice,a.PPR_Price,a.Code,b.Name,a.Seq,dbo.F_GetEnumName('UFIDA.U9.CBO.MFG.Enums.ComponentTypeEnum',a.ComponentType,'zh-cn')ComponentType,a.SubSeq,a.Total,a.PPR_Total ,b.SPECS
   FROM #tempResult a LEFT JOIN dbo.CBO_ItemMaster b ON a.MID=b.ID
 ORDER BY a.MasterCode,a.MasterBom,a.PID,a.Seq,a.ComponentType,a.SubSeq


END

 

 --WHERE total=0
 --ORDER BY MasterCode,MasterBom,PID,Code,Seq,ComponentType,SubSeq
 --SELECT * FROM #tempResult


 END
 


