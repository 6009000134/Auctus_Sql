/*
标题:BOM软件成本报表
需求：财务部
作者:liufei
上线时间:2018-05
备注说明：
1、根据输入的时间查询时间范围内的工单
2、结存价取工单完工月份的结存价，采购价取截止@EndDate的最新采购价

ADD（2018-8-13）：
2018-8-13修改报表逻辑，由于带软件的芯片全部改到力同股份购买，带“软件”字样的芯片在力同芯工厂只是底层材料，如果要找芯片BOM需要去力同股份查找
直接配的软件从价表直接取，芯片的软件价格=芯片价格（优先取300，后取200厂商价表）-芯片下阶材料费-0.1元烧录费
*/
ALTER  proc [dbo].[SP_AuctusGetBomSoftAmount]
(
 @Org BIGINT,--组织编码
 @Code varchar(50),--料号编码
 @StartDate datetime,--起始时间
 @EndDate datetime--截至时间
)
as
BEGIN
DECLARE @DisplayName VARCHAR(10)--根据月份在Auctus_NewestBOMMonth中选择相应月份的BOM集合
SET @DisplayName=CONVERT(CHAR(7),DATEADD(DAY,-1,@EndDate),120)
DECLARE @TaxRate DECIMAL(18,2)=1.16--税率
--SELECT @DisplayName
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
WHERE a.ActualRcvTime >= @StartDate AND a.ActualRcvTime<@EndDate 
GROUP BY b.DemandCode,b.DocNo,b.BOMMaster,b.BOMVersion,b.ItemMaster,b.ActualCompleteDate
),
MOInfo AS--将工单对应的BOM版本全部展出，工单有BOM版本的取工单BOM版本，没有的取BOM最早版本
(
SELECT a.DemandCode,a.DocNo,a.ActualCompleteDate,b.ID BomID,a.ItemMaster,b.BOMVersion,b.BOMVersionCode,a.QTY,
ROW_NUMBER()OVER(PARTITION BY a.docno,a.ItemMaster ORDER BY b.BOMVersion DESC) RN
FROM MOData a LEFT JOIN dbo.CBO_BOMMaster b ON a.ItemMaster=b.ItemMaster AND b.EffectiveDate<@EndDate
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
WITH BOM AS--@DisplayName相应月份的BOM集合
(
SELECT a.MasterBom,a.MasterCode,a.PID,a.MID,a.Code,a.ComponentType,a.ThisUsageQty,a.Org FROM dbo.Auctus_NewestBomMonth a WHERE a.LogTime=@DisplayName
),
XinPian AS--BOMID为空的工单是芯片工单
(
SELECT a.DocNo,ISNULL(b.ThisUsageQty*c.StandardSoftTotal,0) SoftPrice,ISNULL(b.ThisUsageQty*c.SoftTotal,0) SoftPrice2
,c.Code
FROM #MoResult a LEFT JOIN BOM b ON a.BomID=b.MasterBom
LEFT JOIN dbo.Auctus_PriceOf200 c ON b.Code=c.Code
WHERE c.Code IS NOT NULL AND c.LogTime=dbo.fun_Auctus_GetInventoryDate(@EndDate) AND b.ComponentType=0
AND a.BomID IS NOT null
),
XinPian2 AS--芯片工单直接与芯片价格表连接获取软件价格
(
SELECT a.DocNo,b.StandardSoftTotal,b.SoftTotal,b.Code FROM #MoResult a LEFT JOIN dbo.Auctus_PriceOf200 b ON a.ProductCode=b.Code
WHERE a.BomID IS NULL AND b.LogTime=dbo.fun_Auctus_GetInventoryDate(@EndDate) 
),
SoftData AS--只取300组织的软件，200的软件在芯片下面计算了所以不取
(
SELECT a.DocNo,a.ActualCompleteDate,b.MID,b.Code,b.PID,b.ThisUsageQty FROM #MoResult a LEFT JOIN BOM b ON a.BomID=b.MasterBom
WHERE (PATINDEX('S%',b.Code)>0 ) AND b.ComponentType=0 AND b.Org=1001708020135665
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
						THEN ISNULL(Price, 0)/@TaxRate
						WHEN a2.Currency=1 AND a2.IsIncludeTax=0
						THEN ISNULL(Price, 0)
						WHEN a2.Currency!=1 AND a2.IsIncludeTax=1
						THEN ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2)/@TaxRate
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
SELECT a.DocNo,a.ThisUsageQty*ISNULL(b.StandardPrice,ISNULL(t2.Price,0)) SoftPrice
,a.ThisUsageQty*ISNULL(t2.Price,0)SoftPrice2--,ISNULL(COUNT(a.DocNo),0) SoftCount
,a.Code
FROM SoftResult a LEFT JOIN dbo.Auctus_ItemStandardPrice b ON a.MID=b.ItemId AND a.ActualCompleteDate=b.LogTime
LEFT JOIN PPRData t2 ON a.MID=t2.MID
UNION ALL
SELECT * FROM XinPian
UNION ALL
SELECT * FROM XinPian2
)
INSERT INTO #tempSoftPriceInfo
SELECT * FROM SoftPriceInfo



;
WITH SoftPriceInfo AS
(
SELECT *,(SELECT b.Code+',' FROM #tempSoftPriceInfo b WHERE b.DocNo=a.docno FOR XML PATH(''))SoftList
,(SELECT b.Code+',' FROM #tempSoftPriceInfo b WHERE b.DocNo=a.docno AND (ISNULL(b.SoftPrice,0)=0 OR b.SoftPrice<0) FOR XML PATH(''))NullList 
,(SELECT b.Code+',' FROM #tempSoftPriceInfo b WHERE b.DocNo=a.docno AND (ISNULL(b.SoftPrice2,0)=0 OR b.SoftPrice2<0) FOR XML PATH(''))NullList2
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