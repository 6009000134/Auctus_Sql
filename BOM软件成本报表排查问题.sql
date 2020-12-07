BEGIN 

DECLARE @Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='200') 
DECLARE @Date DATETIME=GETDATE()--当前时间
DECLARE @LogTime VARCHAR(50)--记录日期
DECLARE @LogTime2 char(7)--记录月份
SET @LogTime=CONVERT(VARCHAR(10),DATEADD(dd,-day(@Date)+1,@Date),120)
SET @LogTime2=CONVERT(CHAR(7),@Date,120)
DECLARE @Org2 BIGINT=1001708020135435
DECLARE @TaxRate DECIMAL(18,2)--税率
SET @TaxRate=1+dbo.fun_Auctus_GetTaxRate(@Date)
--SELECT a.MasterBom,a.MasterCode,a.PID,a.MID,a.Code,a.ComponentType,a.ThisUsageQty,a.Org 
--FROM dbo.Auctus_NewestBomMonth a INNER JOIN dbo.CBO_BOMMaster b ON a.MasterBom=b.ID AND b.Org=@Org2
--WHERE a.Org=@Org2 AND a.LogTime=@LogTime2  AND a.MasterCode='314050152'
;
WITH BOM AS--当前时间力同股份的BOM集合
(
SELECT a.MasterBom,a.MasterCode,a.PID,a.MID,a.Code,a.ComponentType,a.ThisUsageQty,a.Org 
FROM dbo.Auctus_NewestBomMonth a INNER JOIN dbo.CBO_BOMMaster b ON a.MasterBom=b.ID AND b.Org=@Org2
WHERE a.Org=@Org2 AND a.LogTime=@LogTime2  AND a.MasterCode='314050152' AND a.ComponentType=0
),
parent AS
(
SELECT DISTINCT mastercode FROM BOM 
),
child AS
(
SELECT DISTINCT Code FROM BOM WHERE code NOT LIKE 'S%' 
),
alls AS--股份所有非软件料号集合
(
SELECT * FROM parent UNION SELECT * FROM child
),
PPRData AS--股份所有非软件料号最新采购价（优先取力同芯工厂，其次力同股份）
(
 SELECT * FROM (SELECT   a1.ItemInfo_ItemCode,
						CASE WHEN a2.currency=1 AND  a2.IsIncludeTax = 1 						THEN ISNULL(Price, 0)/@TaxRate
						WHEN a2.Currency=1 AND a2.IsIncludeTax=0						THEN ISNULL(Price, 0)
						WHEN a2.Currency!=1 AND a2.IsIncludeTax=1						THEN ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, @Date, 2)/@TaxRate
						ELSE ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, @Date, 2) END Price,
						ROW_NUMBER()OVER(PARTITION BY a1.ItemInfo_ItemCode ORDER BY a2.Org DESC,a1.FromDate DESC,a2.Currency) AS rowNum					--倒序排生效日
						,a1.Price OriPrice,a2.Currency,a2.IsIncludeTax,a2.Org,a2.ModifiedOn
				FROM    PPR_PurPriceLine a1 RIGHT JOIN alls c ON a1.ItemInfo_ItemCode=c.MasterCode
						INNER JOIN PPR_PurPriceList a2 ON a1.PurPriceList = a2.ID AND a2.Status = 2 AND a2.Cancel_Canceled = 0 AND a1.Active = 1
				WHERE   NOT EXISTS ( SELECT 1 FROM CBO_Supplier WHERE DescFlexField_PrivateDescSeg3 = 'OT01' AND a2.Supplier = ID ) AND 
						a2.Org IN( 1001708020135665,1001708020135435)
						--a2.Org=1001708020135665
						AND a1.FromDate <= @Date)
						t WHERE t.rowNum=1
),
result AS
(
SELECT a.MasterCode,a.code,a.ThisUsageQty,ISNULL(b.Price,0)Price,ISNULL(c.Price,0) cPrice,ISNULL(d.StandardPrice,0)StandardPrice
,ISNULL(e.StandardPrice,0) cStandardPrice 
FROM BOM a LEFT JOIN PPRData b ON a.MasterCode=b.ItemInfo_ItemCode LEFT JOIN PPRData c ON a.Code=c.ItemInfo_ItemCode
LEFT JOIN dbo.Auctus_ItemStandardPrice d ON a.MasterCode=d.Code AND d.LogTime=@LogTime 
LEFT JOIN dbo.Auctus_ItemStandardPrice e ON a.Code=e.Code AND e.LogTime=@LogTime
WHERE a.code NOT LIKE 'S%'
)
SELECT a.ItemInfo_ItemCode 料号,a.Price 未税人民币价格,a.OriPrice 价格,CASE WHEN a.Currency=1 THEN '人民币'ELSE '美元'end 币种,a.IsIncludeTax 是否含税
,CASE WHEN a.Org=1001708020135665 THEN '300' ELSE '200' END 组织
,a.ModifiedOn 
FROM PPRData a
--SELECT a.MasterCode,MIN(price)Price,SUM(a.ThisUsageQty*a.cPrice)materialTotal
--,MIN(price)-SUM(a.ThisUsageQty*a.cPrice)-0.1/@TaxRate softTotal
--,MIN(a.StandardPrice),SUM(a.ThisUsageQty*a.cStandardPrice)StandardMaterialTotal,
--MIN(a.StandardPrice)- SUM(a.ThisUsageQty*a.cStandardPrice)-0.1/@TaxRate StandartSoftTotal
--,@LogTime
--FROM result  a
--GROUP BY a.MasterCode

END 
