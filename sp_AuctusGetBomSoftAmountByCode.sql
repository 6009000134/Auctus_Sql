--按料号抓取BOM软件
/*
标题:BOM软件成本报表,按料号查询，不关联工单
需求：财务部
作者:liufei
上线时间:2018-11-22
备注说明：
1、根据输入的时间，查询当前月份的BOM
2、结存价取当月的结存价，采购价取截止@EndDate的最新采购价
//TODO:无法查找200的芯片价格
*/
ALTER PROC [dbo].[sp_AuctusGetBomSoftAmountByCode]
(
 @Org BIGINT,--组织编码
 @Code varchar(50),--料号编码
 @EndDate DATETIME,--截至时间
 @IsXinPian CHAR(2)
)
AS
BEGIN 

--DECLARE @Org BIGINT=1001708020135665
--DECLARE @Code varchar(50)='102020025'
----DECLARE @StartDate DATETIME='2018-01-01'
--DECLARE @EndDate DATE='2018-10-22'
DECLARE @TaxRate DECIMAL(18,2)=1.16--税率
IF ISNULL(@Code,'')=''
SET @Code=''
DECLARE @StandarPriceLogTime VARCHAR(10)
SET @StandarPriceLogTime=CONVERT(CHAR(10),DATEADD(DAY,-DAY(@EndDate)+1,@EndDate),120)



DECLARE @DisplayName VARCHAR(10)--根据月份在Auctus_NewestBOMMonth中选择相应月份的BOM集合
SET @DisplayName=CONVERT(CHAR(7),DATEADD(DAY,-1,@EndDate),120)

--软件明细
IF object_id(N'tempdb.dbo.#tempSoftPriceInfo',N'U') is NULL
BEGIN 
CREATE TABLE  #tempSoftPriceInfo(
MasterBom BIGINT,
MasterCode VARCHAR(50),
Code VARCHAR(50),
SoftPrice DECIMAL(18,8),--软件单价总和,有结存取结存，没结存取最新采购价
SoftPrice2 DECIMAL(18,8)--软件单价总和，取最新采购价
)
END
ELSE
BEGIN 
TRUNCATE TABLE #tempSoftPriceInfo
END 

IF ISNULL(@IsXinpian,'')='1'
BEGIN
IF ISNULL(@Code,'')=''
SET @Code='3'
;
WITH BOM AS--@DisplayName相应月份的BOM集合
(
SELECT a.MasterBom,a.MasterCode,a.PID,a.ParentCode,a.MID,a.Code,a.ComponentType,a.ThisUsageQty,a.Org ,a.Level
FROM dbo.Auctus_NewestBomMonth a WHERE a.LogTime=@DisplayName AND PATINDEX(@Code+'%',a.MasterCode)>0
),
XinPian AS--BOMID为空的工单是芯片工单
(
SELECT DISTINCT b.MasterBom,b.MasterCode,b.MasterCode Code,c.StandardSoftTotal,c.SoftTotal
FROM BOM b LEFT JOIN dbo.Auctus_PriceOf200 c ON b.MasterCode=c.Code AND c.LogTime=dbo.fun_Auctus_GetInventoryDate(@EndDate) AND b.ComponentType=0
WHERE   b.ComponentType=0 AND c.Code IS NOT NULL 
)
INSERT INTO #tempSoftPriceInfo
SELECT *
FROM XinPian a 
END 
ELSE
BEGIN
;
WITH BOM AS--@DisplayName相应月份的BOM集合
(
SELECT a.MasterBom,a.MasterCode,a.PID,a.ParentCode,a.MID,a.Code,a.ComponentType,a.ThisUsageQty,a.Org ,a.Level
FROM dbo.Auctus_NewestBomMonth a WHERE a.LogTime=@DisplayName AND PATINDEX('%'+@Code+'%',a.MasterCode)>0
),
XinPian AS--BOMID为空的工单是芯片工单
(
SELECT b.MasterBom,b.MasterCode,b.Code,ISNULL(b.ThisUsageQty*c.StandardSoftTotal,0) SoftPrice,ISNULL(b.ThisUsageQty*c.SoftTotal,0) SoftPrice2
FROM BOM b LEFT JOIN dbo.Auctus_PriceOf200 c ON b.Code=c.Code AND c.LogTime=dbo.fun_Auctus_GetInventoryDate(@EndDate) AND b.ComponentType=0
WHERE   b.ComponentType=0 AND c.Code IS NOT NULL 
),
SoftData AS
(
SELECT b.MasterCode,b.MasterBom,b.MID,b.Code,b.PID,b.ThisUsageQty FROM  BOM b 
WHERE (PATINDEX('S%',b.Code)>0 ) AND b.ComponentType=0 AND b.Org=1001708020135665
),
SoftResult AS
(
SELECT a.MasterBom,a.MasterCode,a.MID,a.Code,a.ThisUsageQty 
FROM SoftData a LEFT JOIN SoftData b ON a.MID=b.PID AND a.MasterBom=b.MasterBom
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
						AND a1.FromDate < @EndDate)
						t WHERE t.rowNum=1
),
SoftPriceInfo AS
(
SELECT a.MasterBom,a.MasterCode,a.Code,a.ThisUsageQty*ISNULL(b.StandardPrice,ISNULL(t2.Price,0)) SoftPrice
,a.ThisUsageQty*ISNULL(t2.Price,0)SoftPrice2--,ISNULL(COUNT(a.MasterBom),0) SoftCount
FROM SoftResult a LEFT JOIN dbo.Auctus_ItemStandardPrice b ON a.MID=b.ItemId AND b.LogTime=@StandarPriceLogTime
LEFT JOIN PPRData t2 ON a.MID=t2.MID
UNION ALL
SELECT * FROM XinPian
)
INSERT INTO #tempSoftPriceInfo
SELECT *
FROM SoftPriceInfo a 
END 

;
WITH AllSoft AS--@DisplayName相应月份的BOM集合
(
SELECT a.MasterBom,a.MasterCode,a.PID,a.ParentCode,a.MID,a.Code,a.ComponentType,a.ThisUsageQty,a.Org ,a.Level
FROM dbo.Auctus_NewestBomMonth a WHERE a.LogTime=@DisplayName AND PATINDEX('%'+@Code+'%',a.MasterCode)>0 AND PATINDEX('S%',a.Code)>0
),
SoftPriceInfo AS
(
SELECT *,(SELECT CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),b.ThisUsageQty))+'*'+b.Code+'||' FROM AllSoft b WHERE b.MasterBom=a.MasterBom FOR XML PATH(''))SoftList
,(SELECT b.Code+'||' FROM #tempSoftPriceInfo b WHERE b.MasterBom=a.MasterBom AND (ISNULL(b.SoftPrice,0)=0 OR b.SoftPrice<0) FOR XML PATH(''))NullList 
,(SELECT b.Code+'||' FROM #tempSoftPriceInfo b WHERE b.MasterBom=a.MasterBom AND (ISNULL(b.SoftPrice2,0)=0 OR b.SoftPrice2<0) FOR XML PATH(''))NullList2
FROM #tempSoftPriceInfo a
),
SoftResult AS 
(
SELECT a.MasterBom,a.MasterCode,SUM(a.SoftPrice)TotalSoft,SUM(a.softprice2)TotalSoft2,MIN(a.SoftList)SoftList 
,MIN(a.NullList)NullList,MIN(a.NullList2)NullList2
FROM SoftPriceInfo a 
GROUP BY a.MasterBom,a.MasterCode
)
SELECT a.MasterCode,c.Name,a.TotalSoft,a.TotalSoft2,a.SoftList,a.NullList,a.NullList2
FROM SoftResult a LEFT JOIN dbo.CBO_BOMMaster b ON a.MasterBom=b.ID LEFT JOIN dbo.CBO_ItemMaster c ON b.ItemMaster=c.ID
ORDER BY a.MasterCode 

END 