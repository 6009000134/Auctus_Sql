USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_CostAnalysis]    Script Date: 2018/8/14 10:12:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
此版本将按料号汇总销售金额和生产成本,且只查找300组织
改为
按销售订单展示，不再进行汇总，允许查找多组织
*/
--从销售角度和产出角度分别找出 毛利率=毛利/BOM无软件成本
ALTER  PROC [dbo].[sp_Auctus_CostAnalysis]
(
@Org bigint,
@DisplayName VARCHAR(20)--期间
)
AS
BEGIN
IF ISNULL(@Org,0)=0
BEGIN
SELECT @Org=ID FROM dbo.Base_Organization WHERE code='300'
END

DECLARE @AccountingPeriod BIGINT
--根据会计期间获取查询时间区间
DECLARE @FromDate DATETIME,@ToDate DATETIME
SELECT @FromDate=c.FromDate,@AccountingPeriod=c.ID FROM dbo.Base_SOBAccountingPeriod a LEFT JOIN dbo.Base_SetofBooks b ON a.SetofBooks=b.ID 
LEFT JOIN dbo.Base_AccountingPeriod c ON a.AccountPeriod=c.ID
WHERE b.Org=@Org 
--AND c.ID=@AccountingPeriod
AND c.DisplayName=@DisplayName
DECLARE @SOBPeriod BIGINT
SELECT @SOBPeriod=a.ID FROM dbo.Base_SOBAccountingPeriod a LEFT JOIN dbo.Base_SetofBooks b ON a.SetofBooks=b.ID 
LEFT JOIN dbo.Base_AccountingPeriod c ON a.AccountPeriod=c.ID
WHERE b.Org=@Org 
AND c.ID=@AccountingPeriod
SET @ToDate=DATEADD(MONTH,1,@FromDate)
--出货集 #tempSoCost
IF OBJECT_ID(N'tempdb.dbo.#tempSoCost',N'U') IS NULL
BEGIN
	CREATE TABLE #tempSoCost (DocNo VARCHAR(50),DocLineNo VARCHAR(50),SO_DocType VARCHAR(50),ItemInfo_ItemID BIGINT,ItemInfo_ItemCode VARCHAR(50),ItemInfo_ItemName VARCHAR(50)
,TaxRate DECIMAL(18,8),ACToFCRate DECIMAL(18,8),OrderPriceTC DECIMAL(18,4),OrderByQtyTU DECIMAL(18,4),NetMoneyTC DECIMAL(18,4),Status VARCHAR(50),SoLineStatus VARCHAR(50),DemandType VARCHAR(50),FreeType VARCHAR(50)
,Ship_DocNo VARCHAR(50),Ship_DocLineNo VARCHAR(50),Ship_DocType VARCHAR(50),Ship_TaxRate DECIMAL(18,8),Ship_ACToFCExRate DECIMAL(18,8)
,Ship_OrderPrice DECIMAL(18,4),QtyPriceAmount DECIMAL(18,4),TotalNetMoney DECIMAL(18,4),AC VARCHAR(50),DemandCode VARCHAR(50),Ship_Status VARCHAR(50),Ship_LineStatus VARCHAR(50)
,ShipList VARCHAR(500))
END 
ELSE
BEGIN
TRUNCATE TABLE #tempSoCost
END


--Insert Into  #tempSoCost
; 
WITH tempSM AS--出货单
(
SELECT a.DocNo,--出货单号
	b.DocLineNo,--出货单行
	d1.Name Ship_DocType,--单据类型
	b.SONo ,--销售订单号
	b.ItemInfo_ItemID,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,--料品信息
	b.TaxRate,--税率
	a.ACToFCExRate,--汇率
	b.OrderPrice,--单价（含税）
	b.QtyPriceAmount,--计价数量
	b.TotalNetMoney,--未税金额
	a.AC,--币种
	b.DemandCode--需求分类号
	,a.Status
	,b.Status Ship_LineStatus
	FROM dbo.SM_Ship a LEFT JOIN dbo.SM_ShipLine b ON a.ID=b.Ship
	LEFT JOIN dbo.SM_ShipDocType d ON a.DocumentType=d.ID LEFT JOIN dbo.SM_ShipDocType_Trl d1 ON d.ID=d1.ID
	WHERE a.ShipConfirmDate BETWEEN @FromDate AND @ToDate AND a.Status=3  AND b.status=3  AND a.Org=@Org
	AND (b.ItemInfo_ItemCode LIKE '1%' OR b.ItemInfo_ItemCode LIKE '2%')
	AND d1.SysMLFlag='zh-CN'
	AND patindex('%样品%',d1.Name)=0--排除样品出货单
),
tempSO AS--销售单
(
SELECT a.DocNo,b.DocLineNo,d1.Name SO_DocType,b.ItemInfo_ItemID,b.ItemInfo_ItemCode,b.ItemInfo_ItemName
,b.TaxRate,a.ACToFCRate,b.OrderPriceTC,b.OrderByQtyTU,b.NetMoneyTC,a.Status,b.Status SoLineStatus,c.DemandType,CASE b.FreeType WHEN 0 THEN '赠品' WHEN 1 THEN '备损品' ELSE '' END FreeType
FROM SM_SO a LEFT JOIN dbo.SM_SOLine b ON a.ID=b.SO LEFT JOIN dbo.SM_SOShipline c ON b.ID=c.SOLine 
LEFT JOIN dbo.SM_SODocType d ON a.DocumentType=d.ID LEFT JOIN dbo.SM_SODocType_Trl d1 ON d.ID=d1.ID
WHERE a.Status NOT IN (0,1,2) AND b.status NOT IN (0,1,2) AND PATINDEX('%样品%',d1.Name)=0 AND d1.SysMLFlag='zh-CN'
),
SOResult AS
(
SELECT a.DocNo,a.DocLineNo,a.SO_DocType,a.ItemInfo_ItemID,a.ItemInfo_ItemCode,a.ItemInfo_ItemName
,a.TaxRate,a.ACToFCRate,a.OrderPriceTC,a.OrderByQtyTU,a.NetMoneyTC,a.Status,a.SoLineStatus,a.DemandType,a.FreeType
,b.DocNo Ship_DocNo,b.DocLineNo Ship_DocLineNo,b.Ship_DocType,b.TaxRate Ship_TaxRate,b.ACToFCExRate Ship_ACToFCExRate
,b.OrderPrice Ship_OrderPrice,b.QtyPriceAmount,b.TotalNetMoney,b.AC,b.DemandCode,b.Status Ship_Status,b.Ship_LineStatus
FROM tempSO a RIGHT JOIN tempSM b ON a.DocNo=b.SONo AND a.ItemInfo_ItemCode=b.ItemInfo_ItemCode AND a.DemandType=b.DemandCode
WHERE a.DocNo IS NOT NULL
)
INSERT INTO #tempSoCost
        SELECT a.*,(SELECT b.Ship_DocNo+',' FROM SOResult b WHERE b.DocNo=a.DocNo AND b.DocLineNo=a.DocLineNo FOR XML PATH(''))ShipList FROM SOResult a 


--标准生产材料费取最新版本
--标准材料物料集合
IF OBJECT_ID(N'tempdb.dbo.#tempItem',N'U') IS NULL
BEGIN
CREATE TABLE #tempItem(MasterBom BIGINT,MasterCode varchar(50),ThisUsageQty decimal(18,8),PID BIGINT,MID BIGINT,Code VARCHAR(50))
END
ELSE
BEGIN
TRUNCATE TABLE #tempItem
END
--标准材料结果集
IF OBJECT_ID(N'tempdb.dbo.#tempMaterialResult',N'U') IS NULL
BEGIN
CREATE TABLE #tempMaterialResult (MasterBom BIGINT,MasterCode BIGINT,Price DECIMAL(18,8))
END
ELSE
BEGIN
TRUNCATE TABLE #tempMaterialResult
END 
INSERT INTO #tempItem SELECT t.ID,t.ItemInfo_ItemCode,t1.ThisUsageQty,t1.PID,t1.MID,t1.Code FROM (
SELECT a.ItemInfo_ItemCode MasterCode,b.id,a.ItemInfo_ItemCode ,
ROW_NUMBER()OVER(PARTITION BY a.ItemInfo_ItemCode ORDER BY b.BOMVersion DESC) rn 
FROM #tempSoCost a LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemInfo_ItemCode=c.Code LEFT JOIN dbo.CBO_BOMMaster b ON c.ID=b.ItemMaster
WHERE b.Org=@Org AND b.BOMType=0 AND b.AlternateType=0 ) t LEFT JOIN dbo.Auctus_NewestBom t1 ON t.ID=t1.MasterBom
 WHERE t.rn=1 AND  t1.Code NOT LIKE 'S%' AND t1.Code NOT LIKE '401%' AND t1.Code NOT LIKE '403%' AND t1.IsExpand=1 AND t1.ComponentType=0

 ;
 WITH PPRData AS 
 (
 SELECT * FROM (SELECT   a1.ItemInfo_ItemID,
						CASE WHEN a2.currency=1 AND  a2.IsIncludeTax = 1 						THEN ISNULL(Price, 0)/1.16
						WHEN a2.Currency=1 AND a2.IsIncludeTax=0						THEN ISNULL(Price, 0)
						WHEN a2.Currency!=1 AND a2.IsIncludeTax=1						THEN ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2)/1.16
						ELSE ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2) END Price,
						ROW_NUMBER()OVER(PARTITION BY a1.ItemInfo_ItemID ORDER BY a1.FromDate DESC) AS rowNum					--倒序排生效日
				FROM    PPR_PurPriceLine a1 RIGHT JOIN #tempItem c ON a1.ItemInfo_ItemID=c.MID
						INNER JOIN PPR_PurPriceList a2 ON a1.PurPriceList = a2.ID AND a2.Status = 2 AND a2.Cancel_Canceled = 0 AND a1.Active = 1
				WHERE   NOT EXISTS ( SELECT 1 FROM CBO_Supplier WHERE DescFlexField_PrivateDescSeg3 = 'OT01' AND a2.Supplier = ID ) AND 
						a2.Org = @Org
						--a2.Org=1001708020135665
						AND a1.FromDate <= GETDATE())
						t WHERE t.rowNum=1
 ),
 MInfo AS
 (
 SELECT a.MasterBom,a.MasterCode,a.PID,a.ThisUsageQty,a.MID,a.Code,ISNULL(c.StandardPrice,ISNULL(d.Price,0))StandardPrice
 --,c.StandardPrice StandardPrice2,d.Price--测试价格来源
 FROM #tempItem a LEFT JOIN #tempItem b ON a.MID=b.PID AND a.MasterBom=b.MasterBom
 LEFT JOIN dbo.Auctus_ItemStandardPrice c ON a.MID=c.ItemId 
 AND c.LogTime=dbo.fun_Auctus_GetInventoryDate(@ToDate)
 --AND c.LogTime='2018-05-01'
 LEFT JOIN PPRData d ON a.MID=d.ItemInfo_ItemID
 WHERE b.PID IS NULL 
 )
 --SELECT * FROM MInfo
 INSERT INTO #tempMaterialResult
 SELECT a.MasterBom,a.MasterCode,SUM(a.ThisUsageQty*a.StandardPrice)Price FROM MInfo a
 GROUP BY a.MasterBom,a.MasterCode

 --TODO:
--标准材料取工单版本
--End TODO

--生产订单集 #MOData
IF OBJECT_ID(N'tempdb.dbo.#MOData',N'U') IS NULL
BEGIN
CREATE TABLE #MOData (SoNo VARCHAR(50),SOLine VARCHAR(50),MOID BIGINT,DocNo VARCHAR(50),BOMMaster BIGINT,ItemMaster BIGINT,Code VARCHAR(50),BomVersion BIGINT,BomVersionCode VARCHAR(50)
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
	SELECT a.DocNo SoNo,a.DocLineNo SOLine,b.* FROM (SELECT DISTINCT DocNo,DocLineNo,demandcode,ItemInfo_ItemCode FROM #tempSoCost) a INNER JOIN 
	(SELECT a.ID MoID,a.docno,b.ID BOMMaster,a.ItemMaster,c.Code,b.BomVersion,b.BOMVersionCode,a.DemandCode,
	dbo.fun_Auctus_GetInventoryDate(a.ActualCompleteDate)ActualCompleteDate,
	ROW_NUMBER()OVER(PARTITION BY a.DocNo,a.ItemMaster ORDER BY b.BOMVersion DESC ) RN
	FROM dbo.MO_MO a LEFT JOIN dbo.CBO_BOMMaster b ON a.ItemMaster=b.ItemMaster LEFT JOIN dbo.CBO_ItemMaster c ON b.ItemMaster=c.ID) b
	ON a.ItemInfo_ItemCode=b.Code AND a.DemandCode=b.DemandCode
	) T
	WHERE T.RN=1 	
	),
	MO AS--TODO：DOCList列可以移除
    (
	SELECT a.*,(SELECT b.DocNo+',' FROM MOMO b WHERE b.Code=a.Code AND b.SoNo=a.SoNo FOR XML PATH(''))aa  FROM MOMO a
	)
INSERT INTO #MOData
	SELECT * FROM MO ORDER BY MO.DemandCode
----软件结果集  @SoftResult
IF object_id(N'tempdb.dbo.#SoftResult',N'U') is NULL
BEGIN
CREATE TABLE  #SoftResult (MOID BIGINT,ActualCompleteDate DATE,MasterBom BIGINT,PID BIGINT,MID BIGINT,ThisUsageQty DECIMAL(18,8))
END
ELSE
BEGIN 
TRUNCATE TABLE #SoftResult
END 
INSERT INTO #SoftResult
	SELECT b.MOID,b.ActualCompleteDate,a.MasterBom,a.PID,a.MID,a.ThisUsageQty
	FROM dbo.Auctus_NewestBom a RIGHT JOIN #MOData b ON a.MasterBom=b.BOMMaster
	WHERE  (PATINDEX('401%',a.Code)>0 OR PATINDEX('403%',a.Code)>0 OR PATINDEX('S%',a.Code)>0 )	AND a.ComponentType=0
	
	--SELECT * FROM #tempSoCost
;
WITH SOResult AS--出货订单结果集
(
SELECT a.DocNo,a.DocLineNo,a.SO_DocType,a.ItemInfo_ItemCode,a.ItemInfo_ItemID,a.ItemInfo_ItemName,a.TaxRate,a.ACToFCRate,a.OrderPriceTC,a.OrderByQtyTU
,ISNULL(a.NetMoneyTC,0)*ISNULL(a.ACToFCRate,0)NetMoneyTC,a.Status,a.SoLineStatus
,SUM(ISNULL(a.QtyPriceAmount,0))QtyPriceAmount,SUM(ISNULL(a.TotalNetMoney,0)*ISNULL(a.Ship_ACToFCExRate,0))Ship_NetMoneyTC ,MIN(a.ShipList)ShipList
FROM #tempSoCost a
GROUP BY a.DocNo,a.DocLineNo,a.SO_DocType,a.ItemInfo_ItemCode,a.ItemInfo_ItemID,a.ItemInfo_ItemName,a.TaxRate,a.ACToFCRate,a.OrderPriceTC,a.OrderByQtyTU
,a.NetMoneyTC,a.Status,a.SoLineStatus
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
SELECT a.MoID,a.DemandCode,a.BOMMaster,a.ItemMaster,a.BOMVersion,a.BOMVersionCode,e.Code,e.Name,'标准软件费' CostElementType, 
SUM(ISNULL(b.StandardPrice,0)*ISNULL(c.CompleteQty,0)) CurrentCost ,SUM(c.CompleteQty) CompleteQty
,MIN(a.DocList)DocList
FROM #MOData a LEFT JOIN SoftPrice b ON a.MoID=b.MoID
LEFT JOIN dbo.MO_CompleteRpt c ON a.MoID=c.MO LEFT JOIN mo_mo d ON a.MoID=d.ID 
LEFT JOIN dbo.CBO_ItemMaster e ON a.ItemMaster=e.ID LEFT JOIN RcvDate f ON a.MOID=f.MoID
WHERE c.ActualRcvTime BETWEEN f.rcvFrom AND f.rcvTo
GROUP BY a.MoID,a.DemandCode,a.BOMMaster,a.ItemMaster,a.BOMVersion,a.BOMVersionCode,e.Code,e.Name
),
CostQuery AS--实际成本，通过需求分类号关联订单再关联到生产成本计算表
(
SELECT  a.MoID,a.DemandCode,a.BOMMaster,a.BOMVersion,a.BOMVersionCode,a.ItemMaster,d.Code,d.Name--料品信息
--e1.Name CostElement,--成本要素
,f1.Name CostElementType--成要素类型
,ISNULL(SUM(ISNULL(c.ReceiptCost_CurrentCost,0)),0)+ISNULL(SUM(ISNULL(c.RealCost_PriorCost,0)),0) CurrentCost
,0 CompleteQty
,MIN(a.DocList)DocList
FROM #MOData a LEFT JOIN dbo.CA_CostQuery c ON a.MoID=c.MO LEFT JOIN dbo.CBO_ItemMaster d ON a.ItemMaster=d.ID
LEFT JOIN dbo.CBO_CostElement e ON c.CostElement=e.ID LEFT JOIN dbo.CBO_CostElement_Trl e1 ON e.ID=e1.ID AND e1.SysMLFlag='zh-CN'
LEFT JOIN dbo.CBO_CostElement f ON e.ParentNode=f.ID LEFT JOIN dbo.CBO_CostElement_Trl f1 ON f.ID=f1.ID AND f1.SysMLFlag='zh-CN'
WHERE c.ReceiptCost_CurrentCost IS NOT NULL 
--AND c.SOBPeriod=@SOBPeriod--将没有实际成本数据的记录剔除
GROUP BY a.MoID,a.DemandCode,a.BOMMaster,a.BOMVersion,a.BOMVersionCode,a.ItemMaster,d.Code,d.Name,f1.Name
UNION ALL
SELECT b.MoID,b.DemandCode,b.BOMMaster,b.BOMVersion,b.BOMVersionCode,b.ItemMaster,b.Code
,b.Name,b.CostElementType,ISNULL(b.CurrentCost ,0)CurrentCost
,b.CompleteQty
,b.DocList
FROM MOResult b
),
Result AS
(
SELECT a.MOID,a.DemandCode,g.docno,ISNULL(a.MaterialCost,0)MaterialCost
,ISNULL(b.ManMadeCost,0)ManMadeCost,ISNULL(c.ProductCost,0)ProductCost,ISNULL(d.OutCost,0)OutCost,ISNULL(e.MachineCost,0)MachineCost,ISNULL(f.SoftCost,0) SoftCost
,f.CompleteQty
,a.DocList
FROM (SELECT t.MOID,t.DemandCode,SUM(t.CurrentCost) MaterialCost,MIN(t.DocList)DocList
		FROM CostQuery t WHERE t.CostElementType='直接材料费' GROUP BY t.MOID,t.DemandCode) a
		LEFT JOIN (SELECT CostQuery.MOID,SUM(CurrentCost)ManMadeCost FROM CostQuery WHERE CostElementType='人工费' GROUP BY CostQuery.MOID) b ON a.MOID=b.MOID
		LEFT JOIN (SELECT CostQuery.MOID,SUM(CurrentCost)ProductCost FROM CostQuery WHERE CostElementType='制造费' GROUP BY MOID) c ON a.MOID=c.MOID
		LEFT JOIN (SELECT CostQuery.MOID,SUM(CurrentCost)OutCost FROM CostQuery WHERE CostElementType='外协费' GROUP BY MOID) d ON a.MOID=d.MOID
		LEFT JOIN (SELECT CostQuery.MOID,SUM(CurrentCost)MachineCost FROM CostQuery WHERE CostElementType='机器费' GROUP BY MOID) e ON a.MOID=e.MOID
		LEFT JOIN (SELECT CostQuery.MOID,SUM(CurrentCost)SoftCost,SUM(CompleteQty)CompleteQty FROM CostQuery WHERE CostElementType='标准软件费' GROUP BY MOID) f ON a.MOID=f.MOID
		LEFT JOIN dbo.MO_MO g ON a.MOID=g.ID
),
SO_MO AS--按销售单行汇总生产成本后求出单个生产成本   --材料费=直接材料费+外协费-标准软件费
(
SELECT a.docno SONo2,a.DocLineNo DocLineNo2
,sum(b.MaterialCost+b.OutCost-b.SoftCost)/SUM(b.CompleteQty)MCost--材料费/1个
,sum(b.ManMadeCost)/SUM(b.CompleteQty)ManMadeCost--人工费/1个
,sum(b.ProductCost)/SUM(b.CompleteQty)ProductCost--制费/1个
,sum(b.SoftCost)/SUM(b.CompleteQty)SoftCost--软件费/1个
,SUM(b.CompleteQty)CompleteQty
,MIN(b.DocList)DocList
FROM (SELECT DISTINCT docno,docLineno,demandcode,OrderByQtyTU FROM #tempSoCost) a RIGHT JOIN Result b ON a.DemandCode=b.DemandCode
GROUP BY a.DocNo,a.DocLineNo
),
Final AS
(
SELECT a.DocNo,a.DocLineNo,a.SO_DocType,a.ItemInfo_ItemCode,a.ItemInfo_ItemName,a.TaxRate,a.ACToFCRate
,CONVERT(DECIMAL(18,2),a.OrderPriceTC/(1+a.TaxRate)*a.ACToFCRate)OrderPriceTC--售价（未税人民币）
,CONVERT(INT,a.OrderByQtyTU)SO_Qty
,CONVERT(DECIMAL(18,2),a.NetMoneyTC)SO_NetMoneyTC--销售金额（未税）
,a.Status,a.SoLineStatus
,CONVERT(INT,a.QtyPriceAmount)QtyPriceAmount
,LEFT(b.DocList,LEN(b.DocList)-1)DocList
,LEFT(a.ShipList,LEN(a.ShipList)-1)ShipList
,CONVERT(DECIMAL(18,2),a.Ship_NetMoneyTC)Ship_NetMoneyTC--出货金额（未税）
,CONVERT(DECIMAL(18,2),c.Price)Price--标准材料费
,CONVERT(DECIMAL(18,2),b.SoftCost)SoftCost--标准软件费
,CONVERT(DECIMAL(18,2),b.MCost*a.QtyPriceAmount) MCost--材料费
,LEFT(b.MCost*a.QtyPriceAmount/a.Ship_NetMoneyTC*100,CHARINDEX('.',b.MCost*a.QtyPriceAmount/a.Ship_NetMoneyTC*100)+2)+'%' MRate--材料费占比
,CONVERT(DECIMAL(18,2),b.ManMadeCost*a.QtyPriceAmount) ManMadeCost--人工费
,LEFT(b.ManMadeCost*a.QtyPriceAmount/a.Ship_NetMoneyTC*100,CHARINDEX('.',b.ManMadeCost*a.QtyPriceAmount/a.Ship_NetMoneyTC*100)+2)+'%' ManMadeRate--人工费占比
,CONVERT(DECIMAL(18,2),b.ProductCost*a.QtyPriceAmount) ProductCost--制费
,LEFT(b.ProductCost*a.QtyPriceAmount/a.Ship_NetMoneyTC*100,CHARINDEX('.',b.ProductCost*a.QtyPriceAmount/a.Ship_NetMoneyTC*100)+2)+'%' ProductRate--制费占比
,(b.MCost+b.ManMadeCost+b.ProductCost)*a.QtyPriceAmount TotalCost--总成本
,LEFT((a.Ship_NetMoneyTC-(b.MCost+b.ManMadeCost+b.ProductCost)*a.QtyPriceAmount)/a.Ship_NetMoneyTC*100,CHARINDEX('.',(a.Ship_NetMoneyTC-(b.MCost+b.ManMadeCost+b.ProductCost)*a.QtyPriceAmount)/a.Ship_NetMoneyTC*100)+2)+'%' ProfitRate--毛利率
FROM SOResult a LEFT JOIN SO_MO b ON a.DocNo=b.SONo2 AND a.DocLineNo=b.DocLineNo2
LEFT JOIN #tempMaterialResult c ON a.ItemInfo_ItemCode=c.MasterCode
)
SELECT * FROM Final a
ORDER BY CONVERT(DECIMAL(18,2),SUBSTRING(a.ProfitRate,0,CHARINDEX('%',a.ProfitRate))) DESC 
END


