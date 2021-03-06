USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_GetGrossProfitRateByCode]    Script Date: 2018/8/14 10:14:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--从销售角度和产出角度分别找出 毛利率=毛利/BOM无软件成本
--BOM有效期设置了在2018-06-20之前
--组织是写死了，取采购价时优先取300，没有的再去取200
ALTER  PROC [dbo].[sp_Auctus_GetGrossProfitRateByCode]
(
@Org BIGINT,
@Code VARCHAR(50),
@Displayname VARCHAR(20)--期间
)
AS
BEGIN
--DECLARE @Org BIGINT=1001708020135665
--DECLARE @Code VARCHAR(50)
--DECLARE @DisplayName VARCHAR(50)=''

DECLARE @AccountingPeriod BIGINT--期间
--SET @DisplayName='2017-09'
--根据会计期间获取查询时间区间
DECLARE @FromDate DATETIME,@ToDate DATETIME
IF ISNULL(@DisplayName,'')=''
BEGIN
SET @FromDate='2000-01-01'
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
DECLARE @SOBPeriod BIGINT
SELECT @SOBPeriod=a.ID FROM dbo.Base_SOBAccountingPeriod a LEFT JOIN dbo.Base_SetofBooks b ON a.SetofBooks=b.ID 
LEFT JOIN dbo.Base_AccountingPeriod c ON a.AccountPeriod=c.ID
WHERE b.Org=@Org 
AND c.ID=@AccountingPeriod
if object_id(N'tempdb.dbo.#tempSoCost',N'U') is NULL
BEGIN
CREATE TABLE  #tempSoCost (ShipNo VARCHAR(50),ShipLineNo VARCHAR(50),ItemInfo_ItemID VARCHAR(50),ItemInfo_ItemCode VARCHAR(50),
ItemInfo_ItemName VARCHAR(50), QtyPriceAmount DECIMAL(18,2),OrderPrice DECIMAL(18,4),TotalNetMoney DECIMAL(18,4),
TotalMoneyTC DECIMAL(18,4),TaxRate DECIMAL(18,4),AC INT,DemandCode INT,ShipList VARCHAR(1000),SoList VARCHAR(1000))
END
ELSE
BEGIN
TRUNCATE TABLE #tempSoCost
END

 IF ISNULL(@Code,'')=''
 BEGIN
 ;
 WITH tempSoCost AS
(
	SELECT a.DocNo ShipNo,--出货单号
	b.DocLineNo ShipLineNo,--出货单行
	c.DocNo SoNo,--销售订单号
	b.ItemInfo_ItemID,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,--料品信息
	b.QtyPriceAmount,--计价数量
	b.OrderPrice/(1+b.TaxRate) OrderPrice,--未税单价
	b.TotalNetMoney*a.ACToFCExRate TotalNetMoney,--未税金额
	b.TotalMoneyTC,--税价合计
	b.TaxRate,--税率
	a.AC,
	b.DemandCode--需求分类号
	,a.DocumentType ShipType--出货单据类型
	,c.DocumentType SOType--销售单据类型
	FROM dbo.SM_Ship a LEFT JOIN dbo.SM_ShipLine b ON a.ID=b.Ship LEFT JOIN dbo.SM_SO c ON b.SOKey=c.ID
	LEFT JOIN dbo.SM_ShipDocType d ON a.DocumentType=d.ID LEFT JOIN dbo.SM_ShipDocType_Trl e ON d.ID=e.ID
	WHERE a.ShipConfirmDate BETWEEN @FromDate AND @ToDate AND a.Status=3  AND b.status=3  AND a.Org=@Org
	AND (b.ItemInfo_ItemCode LIKE '1%' OR b.ItemInfo_ItemCode LIKE '2%')
	AND patindex('%样品%',e.Name)=0--排除样品出货单
	--AND b.ItemInfo_ItemCode='101010022'
),
tempSoCostResult AS
(
	SELECT a.ShipNo,--出货单号
	a.ShipLineNo,--出货单行
	a.ItemInfo_ItemID,a.ItemInfo_ItemCode,a.ItemInfo_ItemName,--料品信息
	a.QtyPriceAmount,--计价数量
	a.OrderPrice,--未税单价
	a.TotalNetMoney,--未税金额
	a.TotalMoneyTC,--税价合计
	a.TaxRate,--税率
	a.AC,
	a.DemandCode--需求分类号
	,(SELECT b.ShipNo+'|'+b2.Name+',' 
	FROM tempSoCost b LEFT JOIN dbo.SM_ShipDocType b1 ON b.ShipType=b1.ID LEFT JOIN dbo.SM_ShipDocType_Trl b2 ON b1.ID=b2.ID 
	WHERE b.ItemInfo_ItemCode=a.ItemInfo_ItemCode AND b2.SysMLFlag='zh-CN' FOR XML PATH(''))shipList,
	(SELECT CAST(c.SoNo AS VARCHAR(20))+'|'+c2.Name+',' 
	FROM tempSoCost c LEFT JOIN dbo.SM_SODocType c1 ON c.SOType=c1.ID LEFT JOIN dbo.SM_SODocType_Trl c2 ON c1.ID=c2.ID
	WHERE c.ItemInfo_ItemCode=a.ItemInfo_ItemCode AND c2.SysMLFlag='zh-CN' FOR XML PATH(''))SoList FROM tempSoCost a
)
INSERT INTO #tempSoCost
        SELECT * FROM tempSoCostResult
 END
 ELSE
 BEGIN
 ;
 WITH tempSoCost AS
(
	SELECT a.DocNo ShipNo,--出货单号
	b.DocLineNo ShipLineNo,--出货单行
	c.DocNo SoNo,--销售订单号
	b.ItemInfo_ItemID,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,--料品信息
	b.QtyPriceAmount,--计价数量
	b.OrderPrice/(1+b.TaxRate) OrderPrice,--未税单价
	b.TotalNetMoney*a.ACToFCExRate TotalNetMoney,--未税金额
	b.TotalMoneyTC,--税价合计
	b.TaxRate,--税率
	a.AC,
	b.DemandCode--需求分类号
	,a.DocumentType ShipType--出货单据类型
	,c.DocumentType SOType--销售单据类型
	FROM dbo.SM_Ship a LEFT JOIN dbo.SM_ShipLine b ON a.ID=b.Ship LEFT JOIN dbo.SM_SO c ON b.SOKey=c.ID
	LEFT JOIN dbo.SM_ShipDocType d ON a.DocumentType=d.ID LEFT JOIN dbo.SM_ShipDocType_Trl e ON d.ID=e.ID
	WHERE a.ShipConfirmDate BETWEEN @FromDate AND @ToDate AND a.Status=3  AND b.status=3  AND a.Org=@Org
	AND b.ItemInfo_ItemCode=@Code 
	AND patindex('%样品%',e.Name)=0--排除样品出货单
	--AND b.ItemInfo_ItemCode='101010022'
),
tempSoCostResult AS
(
	SELECT a.ShipNo,--出货单号
	a.ShipLineNo,--出货单行
	a.ItemInfo_ItemID,a.ItemInfo_ItemCode,a.ItemInfo_ItemName,--料品信息
	a.QtyPriceAmount,--计价数量
	a.OrderPrice,--未税单价
	a.TotalNetMoney,--未税金额
	a.TotalMoneyTC,--税价合计
	a.TaxRate,--税率
	a.AC,
	a.DemandCode--需求分类号
	,(SELECT b.ShipNo+'|'+b2.Name+',' 
	FROM tempSoCost b LEFT JOIN dbo.SM_ShipDocType b1 ON b.ShipType=b1.ID LEFT JOIN dbo.SM_ShipDocType_Trl b2 ON b1.ID=b2.ID 
	WHERE b.ItemInfo_ItemCode=a.ItemInfo_ItemCode AND b2.SysMLFlag='zh-CN' FOR XML PATH(''))shipList,
	(SELECT CAST(c.SoNo AS VARCHAR(20))+'|'+c2.Name+',' 
	FROM tempSoCost c LEFT JOIN dbo.SM_SODocType c1 ON c.SOType=c1.ID LEFT JOIN dbo.SM_SODocType_Trl c2 ON c1.ID=c2.ID
	WHERE c.ItemInfo_ItemCode=a.ItemInfo_ItemCode AND c2.SysMLFlag='zh-CN' FOR XML PATH(''))SoList FROM tempSoCost a
)
INSERT INTO #tempSoCost
        SELECT * FROM tempSoCostResult

 END

 --EXEC sp_executesql @Sql,N'@FromDate datetime,@ToDate datetime,@Org Bigint,@Code varchar(50)',@FromDate,@ToDate,@Org,@Code
--标准生产材料费取最新版本
--标准材料物料集合

IF OBJECT_ID(N'tempdb.dbo.#tempItem',N'U') is NULL
BEGIN
CREATE TABLE #tempItem(MasterBom BIGINT,MasterCode varchar(50),ThisUsageQty decimal(18,8),PID BIGINT,MID BIGINT,Code VARCHAR(50),Seq INT,ComponentType INT,SubSeq int)
END
ELSE
BEGIN
TRUNCATE TABLE #tempItem
END
--标准材料结果集
IF OBJECT_ID(N'tempdb.dbo.#tempMaterialResult',N'U') is NULL
BEGIN
CREATE TABLE #tempMaterialResult (MasterBom BIGINT,MasterCode BIGINT,Total DECIMAL(18,8),PPR_Total DECIMAL(18,8),NullList VARCHAR(500))
END
ELSE
BEGIN
TRUNCATE TABLE #tempMaterialResult
END 
INSERT INTO #tempItem SELECT t.id,t.ItemInfo_ItemCode,t1.ThisUsageQty,t1.PID,t1.MID,t1.Code,t1.Sequence,t1.ComponentType,t1.SubSeq FROM (
SELECT a.ItemInfo_ItemCode MasterCode,b.id,a.ItemInfo_ItemCode,
ROW_NUMBER()OVER(PARTITION BY a.ItemInfo_ItemCode ORDER BY b.BOMVersion DESC) rn 
FROM #tempSoCost a LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemInfo_ItemCode=c.Code LEFT JOIN dbo.CBO_BOMMaster b ON c.ID=b.ItemMaster
WHERE b.Org=@Org AND b.BOMType=0 AND b.AlternateType=0 AND b.EffectiveDate<'2018-05-31' ) t LEFT JOIN dbo.Auctus_NewestBom_Test t1 ON t.ID=t1.MasterBom
WHERE t.rn=1 AND  t1.Code NOT LIKE 'S%' AND t1.Code NOT LIKE '401%' AND t1.Code NOT LIKE '403%' AND t1.IsExpand=1 
AND t1.ComponentType=0
--GROUP BY t.id
--SELECT * FROM dbo.CBO_BOMMaster  WHERE ItemMaster=1001708090021645


IF OBJECT_ID(N'tempdb.dbo.#tempMInfo',N'U') is NULL
BEGIN
CREATE TABLE  #tempMInfo (MasterBom BIGINT,MasterCode VARCHAR(50),PID BIGINT,ThisUsageQty DECIMAL(18,8),MID bigint,Code VARCHAR(50),
StandardPrice DECIMAL(18,8),PPR_Price DECIMAL(18,8),Seq INT,ComponentType INT,SubSeq int)
END
ELSE
BEGIN
TRUNCATE TABLE #tempMInfo
END
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
 ) INSERT INTO #tempMInfo SELECT * FROM MInfo
 --找出替代料以及价格
 ;
 WITH ReplaceInfo AS
 (
 SELECT b.MasterBom,b.MasterCode,b.PID,b.ThisUsageQty,b.MID,b.Code,b.Sequence,b.ComponentType,b.SubSeq 
 FROM #tempMInfo a INNER JOIN dbo.Auctus_NewestBom_Test b ON a.MasterBom=b.MasterBom AND a.PID=b.PID AND a.seq=b.Sequence
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
 ReplaceInfo2 AS
 (
 SELECT  a.MasterBom,a.MasterCode,a.PID,a.ThisUsageQty,a.MID,a.Code,ISNULL(b.StandardPrice,ISNULL(c.Price,0))StandardPirce,ISNULL(c.Price,0)PPR_Price
 ,a.Sequence,a.ComponentType,a.SubSeq,
 ROW_NUMBER()OVER(PARTITION BY a.MasterBom,a.PID,a.Sequence ORDER BY a.SubSeq)RN
 FROM ReplaceInfo a LEFT JOIN dbo.Auctus_ItemStandardPrice b ON a.MID=b.ItemId AND b.LogTime=dbo.fun_Auctus_GetInventoryDate(@ToDate)
 LEFT JOIN PPRData2 c ON a.Code=c.ItemInfo_ItemCode
 WHERE b.StandardPrice<>0 AND c.Price<>0--取有价格的替代料
 )
 INSERT INTO #tempMInfo
 SELECT a.MasterBom,a.MasterCode,a.PID,a.ThisUsageQty,a.MID,a.Code,a.StandardPirce,a.PPR_Price,a.Sequence,a.ComponentType,a.SubSeq FROM ReplaceInfo2 a WHERE a.RN=1
 
 ;
 WITH NullItems AS
 (
  SELECT a.* FROM 
 (SELECT * FROM #tempMInfo WHERE StandardPrice=0) a
 LEFT JOIN 
 (SELECT * FROM #tempMInfo WHERE ComponentType=2) b ON a.MasterBom=b.MasterBom AND a.PID=b.PID AND a.Seq=b.Seq
 WHERE ISNULL(b.MasterBom ,0)=0
 ),
 NullPriceCount AS 
 (
 SELECT t.MasterBom,MAX(t.NullList)NullList FROM 
 ( SELECT a.MasterBom,(SELECT b.code+',' FROM NullItems b WHERE b.MasterCode=a.MasterCode AND b.StandardPrice=0 FOR XML PATH(''))NullList 
 FROM NullItems a )t GROUP BY t.MasterBom 
 )
 --SELECT * FROM NullPriceCount 
 INSERT INTO #tempMaterialResult
 SELECT a.*,b.NullList FROM (SELECT a.MasterBom,a.MasterCode,SUM(a.ThisUsageQty*a.StandardPrice)Total,SUM(a.ThisUsageQty*a.PPR_Price)PPR_Total FROM #tempMInfo a
 GROUP BY a.MasterBom,a.MasterCode) a LEFT JOIN NullPriceCount b ON a.MasterBom=b.MasterBom

 --SELECT * FROM #tempItem WHERE MasterCode='202020475'--材料明细
 --SELECT * FROM #tempSoCost WHERE ItemInfo_ItemCode='202020408'--销售单
-- SELECT * FROM dbo.Auctus_NewestBom_Test WHERE MasterBom=1001802280036796
-- SELECT * FROM #tempMaterialResult WHERE MasterCode='202020475'--材料费汇总
/*
 SELECT a.MasterBom,a.MasterCode,a.PID,a.ThisUsageQty,a.MID,a.Code,ISNULL(c.StandardPrice,ISNULL(d.Price,0))StandardPrice
 --,c.StandardPrice StandardPrice2,d.Price--测试价格来源
 FROM #tempItem a LEFT JOIN #tempItem b ON a.MID=b.PID AND a.MasterBom=b.MasterBom
 LEFT JOIN dbo.Auctus_ItemStandardPrice c ON a.MID=c.ItemId AND c.LogTime=''
 LEFT JOIN PPRData d ON a.MID=d.ItemInfo_ItemID
 WHERE b.PID IS NULL
*/
 --TODO:
--标准材料取工单版本
--End TODO



--生产订单集 #MOData
IF OBJECT_ID(N'tempdb.dbo.#MOData',N'U') IS NULL
BEGIN
CREATE TABLE #MOData (MOID BIGINT,DocNo VARCHAR(50),BOMMaster BIGINT,ItemMaster BIGINT,Code VARCHAR(50),BomVersion BIGINT,BomVersionCode VARCHAR(50)
	,DemandCode INT,ActualCompleteDate DATE,RN INT,DocList VARCHAR(5000))
END
ELSE
BEGIN
TRUNCATE TABLE #MOData
END 

	--Insert #MOData	
	;
	WITH MOMO AS
    (
	SELECT * FROM (
	SELECT a.ID MoID,a.docno,b.ID BOMMaster,a.ItemMaster,c.Code,b.BomVersion,b.BOMVersionCode,a.DemandCode,
	dbo.fun_Auctus_GetInventoryDate(a.ActualCompleteDate)ActualCompleteDate,
	ROW_NUMBER()OVER(PARTITION BY a.DocNo,a.ItemMaster ORDER BY b.BOMVersion DESC ) RN
	FROM dbo.MO_MO a LEFT JOIN dbo.CBO_BOMMaster b ON a.ItemMaster=b.ItemMaster LEFT JOIN dbo.CBO_ItemMaster c ON b.ItemMaster=c.ID
	INNER JOIN (SELECT DISTINCT demandcode,ItemInfo_ItemCode FROM #tempsocost) d ON c.Code=d.ItemInfo_ItemCode AND a.DemandCode=d.DemandCode
	--WHERE a.DemandCode IN (SELECT DISTINCT DemandCode FROM #tempSoCost)
	) T
	WHERE T.RN=1 	
	),
	MO AS
    (
	SELECT a.*,(SELECT b.DocNo+',' FROM MOMO b WHERE b.Code=a.Code FOR XML PATH(''))aa  FROM MOMO a
	)
INSERT INTO #MOData
	SELECT * FROM MO ORDER BY MO.DemandCode


----软件结果集  @SoftResult
if object_id(N'tempdb.dbo.#SoftResult',N'U') is NULL
BEGIN
CREATE TABLE  #SoftResult (MOID BIGINT,ActualCompleteDate DATE,MasterBom BIGINT,PID BIGINT,MID BIGINT,ThisUsageQty DECIMAL(18,8))
END
ELSE
BEGIN 
TRUNCATE TABLE #SoftResult
END 
INSERT INTO #SoftResult
	SELECT b.MOID,b.ActualCompleteDate,a.MasterBom,a.PID,a.MID,a.ThisUsageQty
	FROM dbo.Auctus_NewestBom_Test a RIGHT JOIN #MOData b ON a.MasterBom=b.BOMMaster
	WHERE  (PATINDEX('401%',a.Code)>0 OR PATINDEX('403%',a.Code)>0 OR PATINDEX('S%',a.Code)>0 )	AND a.ComponentType=0
	

;
WITH SOResult AS--出货订单结果集
(
SELECT a.ItemInfo_ItemID,a.ItemInfo_ItemCode,--料品信息
SUM(a.TotalNetMoney)TotalSales,--出货总未税金额
SUM(a.QtyPriceAmount) QtyPriceAmount	--出货总数量
,MIN(a.ShipList)ShipList,MIN(a.SoList)SoList
FROM #tempSoCost a
GROUP BY a.ItemInfo_ItemID,a.ItemInfo_ItemCode
),
SoftR AS
(
	SELECT a.* FROM #SoftResult a LEFT JOIN #SoftResult b ON a.MID=b.PID AND a.MOID=b.MOID
	WHERE b.PID IS NULL
),
SoftPrice AS
(
SELECT a.MOID,SUM(a.ThisUsageQty*ISNULL(b.Price,0)) StandardPrice FROM SoftR a LEFT JOIN dbo.Auctus_ItemStandardPrice b ON a.MID=b.ItemId AND a.ActualCompleteDate=b.LogTime
GROUP BY a.MOID
),
RcvDate AS	--完工时间区间
(
	SELECT a.MOID,a.DocNo,ISNULL(MIN(d.FromDate),'9999-12-31') rcvFrom,ISNULL(MAX(d.ToDate),'9999-12-31')  rcvTo
	FROM #MOData a LEFT JOIN dbo.CA_CostQuery b ON a.MOID=b.MO 
	LEFT JOIN dbo.Base_SOBAccountingPeriod c ON b.SOBPeriod=c.ID 
	LEFT JOIN dbo.Base_AccountingPeriod d ON c.AccountPeriod=d.ID
	GROUP BY a.MOID,a.DocNo
),
MOResult AS 
(
SELECT a.MoID,a.BOMMaster,a.ItemMaster,a.BOMVersion,a.BOMVersionCode,e.Code,e.Name,'标准软件费' CostElementType, 
SUM(ISNULL(b.StandardPrice,0)*ISNULL(c.CompleteQty,0)) CurrentCost ,SUM(c.CompleteQty) CompleteQty
,MIN(a.DocList)DocList
FROM #MOData a LEFT JOIN SoftPrice b ON a.MoID=b.MoID
LEFT JOIN dbo.MO_CompleteRpt c ON a.MoID=c.MO LEFT JOIN mo_mo d ON a.MoID=d.ID 
LEFT JOIN dbo.CBO_ItemMaster e ON a.ItemMaster=e.ID LEFT JOIN RcvDate f ON a.MOID=f.MoID
WHERE c.ActualRcvTime BETWEEN f.rcvFrom AND f.rcvTo
GROUP BY a.MoID,a.BOMMaster,a.ItemMaster,a.BOMVersion,a.BOMVersionCode,e.Code,e.Name
),
CostQuery AS--实际成本，通过需求分类号关联订单再关联到生产成本计算表
(
SELECT  a.MoID,a.BOMMaster,a.BOMVersion,a.BOMVersionCode,a.ItemMaster,d.Code,d.Name,--料品信息
--e1.Name CostElement,--成本要素
f1.Name CostElementType,--成要素类型
ISNULL(SUM(ISNULL(c.ReceiptCost_CurrentCost,0)),0)+ISNULL(SUM(ISNULL(c.RealCost_PriorCost,0)),0) CurrentCost
,0 CompleteQty
,MIN(a.DocList)DocList
FROM #MOData a LEFT JOIN dbo.CA_CostQuery c ON a.MoID=c.MO LEFT JOIN dbo.CBO_ItemMaster d ON a.ItemMaster=d.ID
LEFT JOIN dbo.CBO_CostElement e ON c.CostElement=e.ID LEFT JOIN dbo.CBO_CostElement_Trl e1 ON e.ID=e1.ID AND e1.SysMLFlag='zh-CN'
LEFT JOIN dbo.CBO_CostElement f ON e.ParentNode=f.ID LEFT JOIN dbo.CBO_CostElement_Trl f1 ON f.ID=f1.ID AND f1.SysMLFlag='zh-CN'
WHERE c.ReceiptCost_CurrentCost IS NOT NULL 
--AND c.SOBPeriod=@SOBPeriod--将没有实际成本数据的记录剔除
GROUP BY a.MoID,a.BOMMaster,a.BOMVersion,a.BOMVersionCode,a.ItemMaster,d.Code,d.Name,f1.Name
UNION ALL
SELECT b.MoID,b.BOMMaster,b.BOMVersion,b.BOMVersionCode,b.ItemMaster,b.Code
,b.Name,b.CostElementType,ISNULL(b.CurrentCost ,0)CurrentCost
,b.CompleteQty
,b.DocList
FROM MOResult b
),
Result AS
(
SELECT 
a.BOMMaster,a.BomVersion,a.BOMVersionCode,a.ItemMaster,a.Code,a.Name,ISNULL(a.MaterialCost,0)MaterialCost
,ISNULL(b.ManMadeCost,0)ManMadeCost,ISNULL(c.ProductCost,0)ProductCost,ISNULL(d.OutCost,0)OutCost,ISNULL(e.MachineCost,0)MachineCost,ISNULL(f.SoftCost,0) SoftCost
,f.CompleteQty
,a.DocList
FROM (SELECT t.BOMMaster,t.BomVersion,t.BOMVersionCode,t.ItemMaster,t.Code,t.Name,SUM(t.CurrentCost) MaterialCost,MIN(t.DocList)DocList
		FROM CostQuery t WHERE t.CostElementType='直接材料费' GROUP BY t.BOMMaster,t.BomVersion,t.BOMVersionCode,t.ItemMaster,t.Code,t.Name) a
		LEFT JOIN (SELECT CostQuery.BOMMaster,SUM(CurrentCost)ManMadeCost FROM CostQuery WHERE CostElementType='人工费' GROUP BY BOMMaster) b ON a.BOMMaster=b.BOMMaster
		LEFT JOIN (SELECT CostQuery.BOMMaster,SUM(CurrentCost)ProductCost FROM CostQuery WHERE CostElementType='制造费' GROUP BY BOMMaster) c ON a.BOMMaster=c.BOMMaster
		LEFT JOIN (SELECT CostQuery.BOMMaster,SUM(CurrentCost)OutCost FROM CostQuery WHERE CostElementType='外协费' GROUP BY BOMMaster) d ON a.BOMMaster=d.BOMMaster
		LEFT JOIN (SELECT CostQuery.BOMMaster,SUM(CurrentCost)MachineCost FROM CostQuery WHERE CostElementType='机器费' GROUP BY BOMMaster) e ON a.BOMMaster=e.BOMMaster
		LEFT JOIN (SELECT CostQuery.BOMMaster,SUM(CurrentCost)SoftCost,SUM(CompleteQty)CompleteQty FROM CostQuery WHERE CostElementType='标准软件费' GROUP BY BOMMaster) f ON a.BOMMaster=f.BOMMaster
),
Result2 AS 
(
SELECT a.ItemMaster,a.Code,a.Name,SUM(a.MaterialCost+a.OutCost-a.SoftCost) SumMaterCost,SUM(a.ManMadeCost) SumManMadeCost,
SUM(a.ProductCost) SumProductCost,SUM(a.MaterialCost+a.OutCost+a.ManMadeCost+a.ProductCost-a.SoftCost) SumCost
,ISNULL(SUM(ISNULL(a.CompleteQty,0)),0)CompleteQty,SUM(a.SoftCost)SoftCost
,MIN(a.DocList)DocList
FROM Result a
GROUP BY a.ItemMaster,a.Code,a.Name
),
Result3 AS
(
SELECT  a.ItemInfo_ItemID,a.ItemInfo_ItemCode,d.name ItemInfo_ItemName,a.QtyPriceAmount,
dbo.fun_Auctus_GetProductType(d.DescFlexField_PrivateDescSeg9,GETDATE(),'zh-CN')产品类型,
CONVERT(DECIMAL(18,2),a.TotalSales)TotalSales
,b.CompleteQty,CASE b.CompleteQty WHEN 0 THEN NULL ELSE CONVERT(DECIMAL(18,2),b.SoftCost/b.CompleteQty*a.QtyPriceAmount) END 标准软件费
,CONVERT(DECIMAL(18,2),c.Total) 结存标准材料费
,CONVERT(DECIMAL(18,2),c.PPR_Total) 采购标准材料费
,c.NullList
,d.DescFlexField_PrivateDescSeg11 标准工时
, CONVERT(DECIMAL(18,2),d.DescFlexField_PrivateDescSeg11)*40 标准人工制费,
CONVERT(DECIMAL(18,2),(ISNULL(c.Total,0.00)+d.DescFlexField_PrivateDescSeg11*40)*a.QtyPriceAmount) 标准总成本,
CASE a.TotalSales WHEN 0 THEN NULL ELSE (a.TotalSales-(ISNULL(c.Total,0)+d.DescFlexField_PrivateDescSeg11*40)*a.QtyPriceAmount)/a.TotalSales END 标准毛利率,
CASE b.CompleteQty WHEN 0 THEN 0 ELSE CONVERT(DECIMAL(18,2),ISNULL(b.SumMaterCost,0)/b.CompleteQty*a.QtyPriceAmount) END MCost,--材料费
CASE b.CompleteQty WHEN 0 THEN 0 ELSE CONVERT(DECIMAL(18,2),ISNULL(b.SumManMadeCost,0)/b.CompleteQty*a.QtyPriceAmount) END MMCost,--人工费
CASE b.CompleteQty WHEN 0 THEN 0 ELSE CONVERT(DECIMAL(18,2),ISNULL(b.SumProductCost,0)/b.CompleteQty*a.QtyPriceAmount) END MMPCost,--制费
CASE  WHEN b.SumCost=0
THEN NULL ELSE LEFT(ISNULL(b.SumMaterCost,0)/b.SumCost*100,CHARINDEX('.',ISNULL(b.SumMaterCost,0)/b.SumCost*100)+2)+'%'END  MRate,--材料费占比
CASE  WHEN b.SumCost=0
THEN NULL ELSE LEFT(ISNULL(b.SumManMadeCost,0)/b.SumCost*100,CHARINDEX('.',ISNULL(b.SumManMadeCost,0)/b.SumCost*100)+2)+'%' END MMRate,--人工费占比
CASE  WHEN b.SumCost=0
THEN NULL ELSE LEFT(ISNULL(b.SumProductCost,0)/b.SumCost*100,CHARINDEX('.',ISNULL(b.SumProductCost,0)/b.SumCost*100)+2)+'%'END MMPRate,--制费占比
CASE  WHEN a.TotalSales=0 OR b.CompleteQty=0 OR a.QtyPriceAmount=0 
THEN NULL ELSE LEFT((a.TotalSales-ISNULL(b.SumCost,0)/b.CompleteQty*a.QtyPriceAmount)/a.TotalSales*100,CHARINDEX('.',(a.TotalSales-ISNULL(b.SumCost,0)/b.CompleteQty*a.QtyPriceAmount)/a.TotalSales*100)+2)+'%' END ProfitRate--毛利率
,LEFT(a.ShipList,LEN(a.ShipList)-1)ShipList
,LEFT(a.SoList,LEN(a.SoList)-1)SoList
,LEFT(b.DocList,LEN(b.DocList)-1)DocList
,CONVERT(DECIMAL(18,2),a.TotalSales/a.QtyPriceAmount) SalePrice
FROM SOResult  a LEFT JOIN Result2 b ON a.ItemInfo_ItemID =b.ItemMaster
LEFT JOIN #tempMaterialResult c ON a.ItemInfo_ItemCode=c.MasterCode
LEFT JOIN (SELECT id,name,DescFlexField_PrivateDescSeg9,
CASE DescFlexField_PrivateDescSeg11 WHEN '' THEN 0.00 ELSE CONVERT(DECIMAL(18,2),DescFlexField_PrivateDescSeg11) END DescFlexField_PrivateDescSeg11 
FROM CBO_ItemMaster) d ON a.ItemInfo_ItemID=d.ID
)
SELECT * FROM Result3 a
ORDER BY CONVERT(DECIMAL(18,2),SUBSTRING(a.ProfitRate,0,CHARINDEX('%',a.ProfitRate))) DESC 

END 