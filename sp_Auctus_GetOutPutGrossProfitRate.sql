USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_GetOutPutGrossProfitRate]    Script Date: 2018/8/14 10:14:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--从产出角度找出 毛利率=毛利/BOM无软件成本
ALTER  PROC [dbo].[sp_Auctus_GetOutPutGrossProfitRate]
(
@Org VARCHAR(50),
@DisplayName VARCHAR(20)--月份
)
AS
BEGIN

--根据会计期间获取查询时间区间
DECLARE @FromDate DATETIME,@ToDate DATETIME,@AccountingPeriod BIGINT
SELECT @FromDate=c.FromDate,@AccountingPeriod=c.ID FROM dbo.Base_SOBAccountingPeriod a LEFT JOIN dbo.Base_SetofBooks b ON a.SetofBooks=b.ID 
LEFT JOIN dbo.Base_AccountingPeriod c ON a.AccountPeriod=c.ID
WHERE b.Org=@Org 
AND c.DisplayName=@DisplayName
SET @ToDate=DATEADD(MONTH,1,@FromDate)
DECLARE @SOBPeriod BIGINT 
SELECT @SOBPeriod=a.ID FROM dbo.Base_SOBAccountingPeriod a LEFT JOIN dbo.Base_SetofBooks b ON a.SetofBooks=b.ID 
LEFT JOIN dbo.Base_AccountingPeriod c ON a.AccountPeriod=c.ID
WHERE b.Org=@Org AND c.ID=@AccountingPeriod

/*
1、根据时间找出生产订单和料号
2、求出生产成本、销售价表、标准软件费、标准材料费
3、求毛利率
生产订单取BOM当前版本计算材料费
取最新版本计算软件成本
销售价表
*/
--生产订单信息
IF OBJECT_ID(N'tempdb.dbo.#MOData',N'U') is NULL
BEGIN
CREATE table #MOData (MOID BIGINT,DocNo VARCHAR(50),ActualCompleteDate DATE,code VARCHAR(50),name NVARCHAR(255),BOMMaster VARCHAR(50),ItemMaster VARCHAR(50)
,Bomversion VARCHAR(50),BomVersionCode VARCHAR(50),NewestBOMID BIGINT,CompleteQty INT,DemandCode VARCHAR(50),rn INT)
END 
ELSE
BEGIN
TRUNCATE TABLE #MOData
END
--1、根据时间找出生产订单和料号
;
WITH CompleteData AS--根据时间找出完工单，并按生产订单汇总完工数量
(
SELECT b.ID MOID,b.DocNo,b.ItemMaster,b.BOMVersion,dbo.fun_Auctus_GetInventoryDate(b.ActualCompleteDate)ActualCompleteDate,b.BOMMaster
,SUM(a.CompleteQty)CompleteQty,b.DemandCode 
FROM dbo.MO_CompleteRpt a LEFT JOIN dbo.MO_MO b ON a.MO=b.ID
WHERE a.ActualRcvTime BETWEEN @FromDate AND @ToDate AND a.DocState IN (1,3) AND b.DocState IN (1,3) AND b.Org=@Org 
GROUP BY b.DocNo,b.ID,b.ItemMaster,b.BOMVersion,b.BOMMaster,b.ActualCompleteDate,b.DemandCode
),
MOData2 AS
(
SELECT a.MOID,a.DocNo,a.ActualCompleteDate,c.Code,c.Name,ISNULL(a.BOMMaster,b.ID)BOMMaster,a.ItemMaster,a.BOMVersion
,b.BOMVersionCode,b.ID NewestBOMID,a.CompleteQty,a.DemandCode,ROW_NUMBER()OVER(PARTITION BY a.DocNo,a.ItemMaster ORDER BY b.BOMVersion desc)rn
FROM CompleteData a LEFT JOIN dbo.CBO_BOMMaster b ON a.ItemMaster=b.ItemMaster
LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemMaster=c.ID
)
INSERT INTO #MOData
	SELECT  * FROM MOData2 WHERE rn=1
	
		--SELECT * FROM #MOData

		--软件价格集合  #SoftPrice
		IF OBJECT_ID(N'tempdb.dbo.#SoftPrice',N'U') IS NULL
		BEGIN
		CREATE table #SoftPrice(MOID BIGINT,StandardPrice DECIMAL(18,4))
		END 
		ELSE
		BEGIN
		TRUNCATE TABLE #SoftPrice
		END
		;
		WITH Soft1 AS
        (
		SELECT a.MOID,b.Code,b.MID,b.PID,b.ThisUseQty,a.ActualCompleteDate FROM #MOData a LEFT JOIN dbo.Auctus_DailyBomResult b ON a.NewestBOMID=b.MasterBom AND b.MasterDemandCode=-1
		WHERE 	(b.Code LIKE '401%' OR b.Code LIKE '403%' OR b.Code LIKE 'S%')  AND b.ComponentType=0
		),
		Soft2 AS
        (
		SELECT a.* FROM Soft1 a LEFT JOIN Soft1 b ON a.MID=b.PID
		WHERE b.PID IS NULL
		),
		Soft3 AS
        (
		SELECT a.*,b.StandardPrice FROM Soft2 a  LEFT JOIN dbo.Auctus_ItemStandardPrice b ON a.MID=b.ItemId AND b.LogTime=a.ActualCompleteDate
		)
		--SELECT * FROM Soft3 ORDER BY Soft3.MOID
		INSERT INTO #SoftPrice
			SELECT a.MOID,SUM(a.ThisUseQty*a.StandardPrice) FROM Soft3 a GROUP BY a.MOID
			--End 软件价格		

	;	
	WITH SOPrice AS--销售单价
	(
	SELECT t.Code
	,CASE 
	WHEN  t.IsIncludeTax=0 THEN t.Price*dbo.fn_CustGetCurrentRate(t.Currency,1,@ToDate,2)
	WHEN  t.IsIncludeTax=1 THEN t.Price*dbo.fn_CustGetCurrentRate(t.Currency,1,@ToDate,2)/1.17
	END SalePrice
	FROM (SELECT a.Code,a.Currency,a.IsIncludeTax,a.Org,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,b.Price,b.FromDate,b.ToDate 
	,ROW_NUMBER()OVER(PARTITION BY b.ItemInfo_ItemCode ORDER BY b.FromDate desc) rn
	FROM dbo.SPR_SalePriceList a INNER JOIN dbo.SPR_SalePriceLine b ON a.ID=b.SalePriceList
	WHERE b.Active=1 AND a.Status=2 AND b.FromDate<@ToDate AND (b.ItemInfo_ItemCode LIKE '1%' OR b.ItemInfo_ItemCode LIKE '2%')
	AND a.Org=@Org
		 ) t 
	WHERE t.rn=1
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
	SELECT a.MOID,a.DocNo,a.code,a.name,a.ItemMaster,a.ActualCompleteDate
	,a.CompleteQty
	--,b.CompleteQty 
	,SUM(b.CompleteQty)TotalQty 
	FROM #MOData a LEFT JOIN dbo.MO_CompleteRpt b ON a.MOID=b.MO LEFT JOIN RcvDate c ON a.MOID=c.MOID
	WHERE b.ActualRcvTime BETWEEN c.rcvFrom AND c.rcvTo
	GROUP BY a.MOID,a.DocNo,a.code,a.name,a.ItemMaster,a.ActualCompleteDate,a.CompleteQty
	),
	MOFinal AS--查询生产订单产品和软件单价，有销售价取销售价，无销售价取对应的标准价
    (
		SELECT a.*,--a.CompleteQty*ISNULL(b.OrderPriceTC,0) Total,
		a.CompleteQty*ISNULL(b.SalePrice,ISNULL(c.StandardPrice,0)) Total,
		a.CompleteQty*ISNULL(d.StandardPrice,0) TotalSoft
		FROM MOResult a LEFT JOIN SOPrice b ON a.Code=b.Code
		LEFT JOIN dbo.Auctus_ItemStandardPrice c ON a.ItemMaster=c.ItemId AND a.ActualCompleteDate=c.LogTime
		LEFT JOIN #SoftPrice d ON a.MoID=d.MoID
	),
	CostQuery AS--按成本要素类型查询生产订单实际成本
    (
	    --SELECT * FROM #MOData
		SELECT  a.MoID,a.BOMMaster,a.BOMVersion,a.BOMVersionCode,a.ItemMaster,a.Code,a.Name,--料品信息
		f1.Name CostElementType,--成要素类型
		ISNULL(SUM(ISNULL(c.ReceiptCost_CurrentCost,0)),0)+ISNULL(SUM(ISNULL(c.RealCost_PriorCost,0)),0) CurrentCost
		FROM #MOData a LEFT JOIN dbo.CA_CostQuery c ON a.MoID=c.MO 
		LEFT JOIN dbo.CBO_CostElement e ON c.CostElement=e.ID LEFT JOIN dbo.CBO_CostElement_Trl e1 ON e.ID=e1.ID AND e1.SysMLFlag='zh-CN'
		LEFT JOIN dbo.CBO_CostElement f ON e.ParentNode=f.ID LEFT JOIN dbo.CBO_CostElement_Trl f1 ON f.ID=f1.ID AND f1.SysMLFlag='zh-CN'
		WHERE c.ReceiptCost_CurrentCost IS NOT NULL --AND c.SOBPeriod=@SOBPeriod--将没有实际成本数据的记录剔除
		GROUP BY a.MoID,a.BOMMaster,a.BOMVersion,a.BOMVersionCode,a.ItemMaster,a.Code,a.Name,f1.Name
	),
	CostQuery2 AS--将CostQuery数据纵向改成横向
	(
		SELECT 
		a.Code,a.Name,ISNULL(a.MaterialCost,0)MaterialCost
		,ISNULL(b.ManMadeCost,0)ManMadeCost,ISNULL(c.ProductCost,0)ProductCost,ISNULL(d.OutCost,0)OutCost,ISNULL(e.MachineCost,0)MachineCost
		FROM (SELECT t.Code,t.Name,SUM(t.CurrentCost) MaterialCost
		FROM CostQuery t WHERE t.CostElementType='直接材料费' GROUP BY t.Code,t.Name) a
		LEFT JOIN (SELECT CostQuery.code,SUM(CurrentCost)ManMadeCost FROM CostQuery WHERE CostElementType='人工费' GROUP BY code) b ON a.code=b.code
		LEFT JOIN (SELECT CostQuery.code,SUM(CurrentCost)ProductCost FROM CostQuery WHERE CostElementType='制造费' GROUP BY code) c ON a.code=c.code
		LEFT JOIN (SELECT CostQuery.code,SUM(CurrentCost)OutCost FROM CostQuery WHERE CostElementType='外协费' GROUP BY code) d ON a.code=d.code
		LEFT JOIN (SELECT CostQuery.code,SUM(CurrentCost)MachineCost FROM CostQuery WHERE CostElementType='机器费' GROUP BY code) e ON a.code=e.code
	),
	MOFinal2 AS--计算生产订单总成本和软件总成本
    (
		SELECT a.code,a.name,SUM(a.CompleteQty)CompleteQty,SUM(a.Total)total,SUM(a.TotalSoft)TotalSoft,MIN(a.TotalQty)TotalQty
		FROM MOFinal a
		GROUP BY a.code,a.name
	),
	MOFinal3 AS
    (
		SELECT a.code,a.name,a.CompleteQty,a.TotalQty,a.total,a.TotalSoft
		,b.MaterialCost,b.OutCost,b.ManMadeCost,b.ProductCost,(ISNULL(b.MaterialCost,0)+ISNULL(b.OutCost,0))/a.TotalQty*a.CompleteQty-a.TotalSoft MCost,
		(ISNULL(b.MaterialCost,0)+ISNULL(b.OutCost,0)+ISNULL(b.ManMadeCost,0))/a.TotalQty*a.CompleteQty-a.TotalSoft MMCost,
		(ISNULL(b.MaterialCost,0)+ISNULL(b.OutCost,0)+ISNULL(b.ManMadeCost,0)/a.TotalQty*a.CompleteQty+ISNULL(b.ProductCost,0))-a.TotalSoft MMPCost,
		CASE a.total WHEN 0 THEN NULL ELSE (a.total-((ISNULL(b.MaterialCost,0)+ISNULL(b.OutCost,0))/a.TotalQty*a.CompleteQty-a.TotalSoft))/a.total END MRate,
		CASE a.total WHEN 0 THEN NULL ELSE (a.total-((ISNULL(b.MaterialCost,0)+ISNULL(b.OutCost,0)+ISNULL(b.ManMadeCost,0))/a.TotalQty*a.CompleteQty-a.TotalSoft))/a.total END MMRate,
		CASE a.total WHEN 0 THEN NULL ELSE (a.total-((ISNULL(b.MaterialCost,0)+ISNULL(b.OutCost,0)+ISNULL(b.ManMadeCost,0)+ISNULL(b.ProductCost,0))/a.TotalQty*a.CompleteQty-a.TotalSoft))/a.total END MMPRate
		FROM MOFinal2 a LEFT JOIN CostQuery2 b ON a.code=b.code
	),
	MOFinal4 AS--格式化Mofinal3
	(
	SELECT a.code,a.name,a.CompleteQty,a.total,a.TotalSoft
	,a.MaterialCost,a.OutCost,a.ManMadeCost,a.ProductCost
	,a.MCost,a.MMCost,a.MMPCost
	,CASE a.total WHEN 0 THEN NULL ELSE LEFT(a.MRate*100,CHARINDEX('.',a.MRate*100)+2)+'%' END MRate
	,CASE a.total WHEN 0 THEN NULL ELSE LEFT(a.MMRate*100,CHARINDEX('.',a.MMRate*100)+2)+'%' END MMRate
	,CASE a.total WHEN 0 THEN NULL ELSE LEFT(a.MMPRate*100,CHARINDEX('.',a.MMPRate*100)+2)+'%' END MMPRate
	FROM MOFinal3 a
	)
	SELECT * FROM MOFinal4 a
	ORDER BY CONVERT(DECIMAL(18,2),SUBSTRING(a.MMPRate,0,CHARINDEX('%',a.MMPRate))) DESC 
	
END 
