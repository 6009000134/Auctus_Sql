USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[SP_AuctusGetBomSoftAmount]    Script Date: 2018/8/14 10:15:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER  proc [dbo].[SP_AuctusGetBomSoftAmount]
(
 @Org BIGINT,--组织编码
 @Code varchar(50),--料号编码
 @StartDate datetime,--起始时间
 @EndDate datetime--截至时间
)
as
BEGIN

 --DECLARE @Org BIGINT=1001708020135665
 --DECLARE @Code varchar(50)='101010141'
 --DECLARE @StartDate DATETIME='2018-01-01'
 --DECLARE @EndDate DATETIME='2018-07-31'

IF object_id(N'tempdb.dbo.#MoResult',N'U') is NULL
BEGIN 
CREATE TABLE  #MoResult(DemandCode INT,DocNo VARCHAR(50),ActualCompleteDate DATE,BomID BIGINT,Itemmaster BIGINT,Bomversion VARCHAR(50),BomversionCode VARCHAR(50),
Qty INT,RN INT,ProductCode VARCHAR(50),ProductName VARCHAR(50))
END
ELSE
BEGIN 
TRUNCATE TABLE #MoResult
END 
;
WITH MOData AS--通过时间查找完工数量以及对应的工单
(
SELECT b.DemandCode,b.DocNo,b.BOMMaster,b.BOMVersion,b.ItemMaster,ISNULL(SUM(a.CompleteQty),0) Qty,dbo.fun_Auctus_GetInventoryDate(b.ActualCompleteDate)ActualCompleteDate
FROM dbo.MO_CompleteRpt a LEFT JOIN dbo.MO_MO b ON a.MO=b.ID
WHERE a.ActualRcvTime BETWEEN @StartDate AND @EndDate 
GROUP BY b.DemandCode,b.DocNo,b.BOMMaster,b.BOMVersion,b.ItemMaster,b.ActualCompleteDate
),
MOInfo AS--将工单对应的BOM版本全部展出，工单有BOM版本的取工单BOM版本，没有的取BOM最早版本
(
SELECT a.DemandCode,a.DocNo,a.ActualCompleteDate,b.ID BomID,b.ItemMaster,b.BOMVersion,b.BOMVersionCode,a.QTY,
ROW_NUMBER()OVER(PARTITION BY a.docno,a.ItemMaster ORDER BY b.BOMVersion DESC) RN
FROM MOData a LEFT JOIN dbo.CBO_BOMMaster b ON a.ItemMaster=b.ItemMaster
),
MoResult AS
(
SELECT a.*,b.Code ProductCode,b.Name ProductName 
FROM MOInfo a LEFT JOIN dbo.CBO_ItemMaster b ON a.ItemMaster=b.ID WHERE RN=1
)
INSERT INTO #MoResult SELECT * FROM MoResult

IF ISNULL(@Code,'')<>''
BEGIN
DELETE FROM #MoResult WHERE ISNULL(ProductCode,'')<>@Code
END 

--工单软件明细
IF object_id(N'tempdb.dbo.#tempSoftPriceInfo',N'U') is NULL
BEGIN 
CREATE TABLE  #tempSoftPriceInfo(
DocNo VARCHAR(50),
SoftPrice DECIMAL(18,8),--软件单价总和,有结存取结存，没结存取最新采购价
SoftPrice2 DECIMAL(18,8),--软件单价总和，取最新采购价
Code VARCHAR(50)
)
END
ELSE
BEGIN 
TRUNCATE TABLE #tempSoftPriceInfo
END 
;
WITH SoftData AS
(
SELECT a.DocNo,a.ActualCompleteDate,b.MID,b.Code,b.PID,b.ThisUsageQty FROM #MoResult a LEFT JOIN dbo.Auctus_NewestBom b ON a.BomID=b.MasterBom
WHERE (PATINDEX('401%',b.Code)>0 OR PATINDEX('403%',b.Code)>0 OR PATINDEX('S%',b.Code)>0 ) AND b.ComponentType=0
),
SoftResult AS
(
SELECT a.DocNo,a.MID,a.Code,a.ActualCompleteDate,a.ThisUsageQty FROM SoftData a LEFT JOIN SoftData b ON a.MID=b.PID AND a.DocNo=b.DocNo
WHERE b.PID IS NULL 
),
PPRData AS
(
SELECT * FROM (SELECT  b.MID,
						CASE WHEN a2.currency=1 AND  a2.IsIncludeTax = 1 
						THEN ISNULL(Price, 0)/1.16
						WHEN a2.Currency=1 AND a2.IsIncludeTax=0
						THEN ISNULL(Price, 0)
						WHEN a2.Currency!=1 AND a2.IsIncludeTax=1
						THEN ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2)/1.16
						ELSE
                        ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2) END Price,
						ROW_NUMBER()OVER(PARTITION BY a1.ItemInfo_ItemID ORDER BY a1.FromDate DESC) AS rowNum					--倒序排生效日
				FROM    PPR_PurPriceLine a1 right JOIN SoftResult b ON a1.ItemInfo_ItemCode=b.Code
						INNER JOIN PPR_PurPriceList a2 ON a1.PurPriceList = a2.ID AND a2.Status = 2 AND a2.Cancel_Canceled = 0 AND a1.Active = 1
				WHERE   NOT EXISTS ( SELECT 1 FROM CBO_Supplier WHERE DescFlexField_PrivateDescSeg3 = 'OT01' AND a2.Supplier = ID ) AND 
						a2.Org = @Org
						AND a1.FromDate <= @EndDate)
						t WHERE t.rowNum=1
),
SoftPriceInfo AS
(
SELECT a.DocNo,a.ThisUsageQty*ISNULL(b.StandardPrice,t2.Price) SoftPrice
,a.ThisUsageQty*ISNULL(t2.Price,0)SoftPrice2--,ISNULL(COUNT(a.DocNo),0) SoftCount
,a.Code
FROM SoftResult a LEFT JOIN dbo.Auctus_ItemStandardPrice b ON a.MID=b.ItemId AND a.ActualCompleteDate=b.LogTime
LEFT JOIN PPRData t2 ON a.MID=t2.MID
)
INSERT INTO #tempSoftPriceInfo
SELECT * FROM SoftPriceInfo



;
WITH SoftPriceInfo AS
(
SELECT *,(SELECT b.Code+',' FROM #tempSoftPriceInfo b WHERE b.DocNo=a.docno FOR XML PATH(''))SoftList
,(SELECT b.Code+',' FROM #tempSoftPriceInfo b WHERE b.DocNo=a.docno AND ISNULL(b.SoftPrice,0)=0 FOR XML PATH(''))NullList 
,(SELECT b.Code+',' FROM #tempSoftPriceInfo b WHERE b.DocNo=a.docno AND ISNULL(b.SoftPrice2,0)=0 FOR XML PATH(''))NullList2
FROM #tempSoftPriceInfo a
),
SoftResult AS 
(
SELECT a.DocNo,SUM(a.SoftPrice)TotalSoft,SUM(a.softprice2)TotalSoft2,COUNT(a.DocNo)SoftCount,MIN(a.SoftList)SoftList 
,MIN(a.NullList)NullList,MIN(a.NullList2)NullList2
FROM SoftPriceInfo a 
GROUP BY a.DocNo
)
SELECT a.DocNo,a.ProductCode,a.ProductName,
CONVERT(DECIMAL(18,0),a.Qty) Qty,Convert(DECIMAL(18,2),ISNULL(a.Qty*ISNULL(b.TotalSoft,0),0)) Total,b.TotalSoft,Convert(DECIMAL(18,2),ISNULL(a.Qty*ISNULL(b.TotalSoft2,0),0)) Total2,b.TotalSoft2,ISNULL(b.SoftCount,0)SoftCount,b.SoftList
,b.NullList,b.NullList2
FROM #MoResult a LEFT JOIN SoftResult b ON a.DocNo=b.DocNo
ORDER BY a.ProductCode 

END