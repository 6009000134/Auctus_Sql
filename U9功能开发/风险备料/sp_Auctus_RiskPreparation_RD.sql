----风险备料报表(研发)
--/*
--逻辑：
--1）按条件提取风险备料单物料明细；
--2）根据风险备料明细中的物料匹配最新BOM
--3）按BOM的用量汇总计算物料需求量 
-- 参考公式：
-- 需求数量=进位（数量/母件底数量*用量）  
-- 需求数量=进位（向上取整（数量/母件底数量）*用量） ---BOM中选择了取整
--*/
ALTER PROC [dbo].[sp_Auctus_RiskPreparation_RD]
(
@pageSize int,
@pageIndex int,
@Org VARCHAR(50),
@DocNo VARCHAR(50),--风险备料单号 单号必填
@Code VARCHAR(50),
@SD DATETIME,
@ED DATETIME
)
AS
BEGIN
--DECLARE @pageSize INT =1000
--DECLARE @pageIndex INT =1
--DECLARE @DocNo VARCHAR(50)='FO1910110005'
--DECLARE @Code VARCHAR(50)
--DECLARE @SD DATE,@ED DATE
--DECLARE @Org BIGINT=1001708020135665
--SET @SD='2019-6-1'
--SET @ED='2019-6-30'

DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
DECLARE @endIndex INT=@pageSize*@pageIndex+1
SET @Org=1001708020135665
IF ISNULL(@SD,'')=''
SET @SD='2000-01-01'
IF ISNULL(@ED,'')=''
SET @ED='9999-01-01'
SET @ED=DATEADD(DAY,1,@ED)
SET @Code='%'+ISNULL(@Code,'')+'%'
--SET @DocNo='%'+ISNULL(@DocNo,'')+'%'


--BOM保存集合
IF OBJECT_ID(N'tempdb.dbo.#Auctus_NewestBom',N'U') is NULL
BEGIN
CREATE TABLE #Auctus_NewestBom
(
MasterBom varchar(50),--最顶层成品料号编码
MasterCode VARCHAR(50),
BOMMaster varchar(50),--母项id
PID varchar(50),--母项料号id
ParentCode varchar(50),--子项料号编码
MID varchar(50),--子项料号id
Code varchar(50),--子项料号编码
Name NVARCHAR(255)     ,
Sequence INT,
ComponentType INT,--子项类型 标准/替代 0/2
SubSeq INT,--替代顺序
EffectiveDate datetime,--母项生效时间
DisableDate datetime,--母项失效时间
SubEffectiveDate DATETIME,--子项生效时间
SubDisableDate DATETIME,--子项失效时间
ThisUsageQty DECIMAL(18,8),--用量
Level INT,
DescPrivate1 VARCHAR(4),--权级，即CBO_BOMMaster的DescFlexField_PrivateDescSeg1字段
IsExpand VARCHAR(4)--是否展开，根据BOMMaster权级字段来判断，0/1-不展开/展开
,Org BIGINT
)
END
ELSE
BEGIN
TRUNCATE TABLE #Auctus_NewestBom
END



 IF object_id('tempdb.dbo.#tempDefineValue') is NULL
 CREATE TABLE #tempDefineValue(Code VARCHAR(50),Name NVARCHAR(255),Type VARCHAR(50))
 ELSE
 TRUNCATE TABLE #tempDefineValue
 --MRP分类值集
 INSERT INTO #tempDefineValue
         ( Code, Name, Type )
SELECT T.Code,T.Name,'MRPCategory' FROM ( SELECT  A.[ID] as [ID], A.[Code] as [Code], A1.[Name] as [Name], A.[SysVersion] as [SysVersion], A.[ID] as [MainID], A2.[Code] as SysMlFlag
 , ROW_NUMBER() OVER(ORDER BY A.[Code] asc, (A.[ID] + 17) asc ) AS rownum  FROM  Base_DefineValue as A  left join Base_Language as A2 on (A2.Code = 'zh-CN')
  and (A2.Effective_IsEffective = 1)  left join [Base_DefineValue_Trl] as A1 on (A1.SysMlFlag = 'zh-CN') and (A1.SysMlFlag = A2.Code) and (A.[ID] = A1.[ID])
   WHERE  (((((((A.[ValueSetDef] = (SELECT ID FROM Base_ValueSetDef WHERE code='MRPCategory') ) and (A.[Effective_IsEffective] = 1)) and (A.[Effective_EffectiveDate] <= GETDATE())) 
   AND (A.[Effective_DisableDate] >= GETDATE())) and (1 = 1)) and (1 = 1)) and (1 = 1))) T

IF object_id('tempdb.dbo.#tempForecast') is NULL
BEGIN
	CREATE TABLE #tempForecast
	(
	DocNo VARCHAR(50),
	DocLineNo INT,
	Itemmaster BIGINT,
	Qty INT,
	DeliveryDate DATETIME
	)
END 
ELSE
BEGIN
	TRUNCATE TABLE #tempForecast
END 
--保存预测订单集合
INSERT INTO #tempForecast
	SELECT a.DocNo,b.DocLineNo,b.Itemmaster,b.Qty,b.DeliveryDate FROM dbo.Auctus_Forecast a INNER JOIN dbo.Auctus_ForecastLine b ON a.ID=b.Forecast
	WHERE b.DeliveryDate>=@SD AND b.DeliveryDate<@ED
		AND a.DocNo IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@DocNo))
	AND PATINDEX(@Code,b.Code)>0
	AND a.DocType='研发'
	
IF object_id('tempdb.dbo.#tempResult') is NULL
BEGIN
	CREATE TABLE #tempResult (MID BIGINT,UsageQty DECIMAL(18,4),DeliveryDate DATETIME)
END 
ELSE
BEGIN 
	TRUNCATE TABLE #tempResult
END 
--待展BOM料号
DECLARE @Itemmaster2 VARCHAR(MAX)=(SELECT CONVERT(VARCHAR(50),itemmaster)+',' FROM #tempForecast FOR XML PATH(''))
--展BOM结果
INSERT INTO #Auctus_NewestBom 
EXEC dbo.sp_Auctus_ExpandOneBOM @Itemmaster =@Itemmaster2, -- bigint
    @Org =1001708020135665 -- bigint

;
WITH data1 AS
(
SELECT c.MasterBom,c.MID,c.PID,c.ThisUsageQty
FROM #tempForecast a INNER JOIN dbo.CBO_BOMMaster b ON a.Itemmaster=b.ItemMaster AND b.Org=@Org
INNER JOIN #Auctus_NewestBom c ON b.ID=c.MasterBom AND c.Org=@Org 
WHERE c.ComponentType=0--标准料
),
data2 AS
(
SELECT a.MasterBom,a.MID,a.PID,SUM(a.ThisUsageQty)ThisUsageQty FROM data1 a
GROUP BY a.MasterBom,a.MID,a.PID
),
Items AS
(
SELECT DISTINCT a.* FROM data2 a LEFT JOIN data2 b ON a.MID=b.PID
WHERE ISNULL(b.PID,'')=''
),
ItemResult AS
(
SELECT c.MID,SUM(a.Qty*c.ThisUsageQty) UsageQty,a.DeliveryDate
FROM #tempForecast a INNER JOIN dbo.CBO_BOMMaster b ON a.Itemmaster=b.ItemMaster AND b.Org=@Org
INNER JOIN Items c ON b.ID=c.MasterBom 
GROUP BY c.MID,a.DeliveryDate
)
INSERT INTO #tempResult
SELECT *FROM ItemResult

;
WITH PPRData AS--厂商价表
(SELECT  COUNT(b.MID)IsExistsPrice,b.MID				--倒序排生效日
				FROM    PPR_PurPriceLine a1 INNER JOIN #tempResult b ON a1.ItemInfo_ItemID=b.MID
						INNER JOIN PPR_PurPriceList a2 ON a1.PurPriceList = a2.ID AND a2.Status = 2 AND a2.Cancel_Canceled = 0 AND a1.Active = 1
				WHERE   NOT EXISTS ( SELECT 1 FROM CBO_Supplier WHERE DescFlexField_PrivateDescSeg3 IN ('OT01','NEI01') AND a2.Supplier = ID ) AND 
						a2.Org = @Org
						AND a1.FromDate <= GETDATE()
						GROUP BY b.MID
),
SupplySource AS--货源
(
SELECT DISTINCT a.ItemInfo_ItemID FROM dbo.CBO_SupplySource a INNER JOIN dbo.CBO_Supplier b ON a.SupplierInfo_Supplier=b.ID
INNER JOIN #tempResult c ON a.ItemInfo_ItemID=c.MID
WHERE b.DescFlexField_PrivateDescSeg3 NOT IN ('OT01','NEI01')
AND a.Effective_IsEffective=1
),
ItemSupplier AS--供应商料品交叉
(
SELECT t.ItemInfo_ItemID,t.IsRecognize FROM 
(SELECT a.ItemInfo_ItemID,a.DescFlexField_PrivateDescSeg1 IsRecognize,ROW_NUMBER() OVER(PARTITION BY a.ItemInfo_ItemID ORDER BY a.DescFlexField_PrivateDescSeg1 DESC)RN
FROM dbo.CBO_SupplierItem a INNER JOIN dbo.CBO_Supplier b ON a.SupplierInfo_Supplier=b.ID
INNER JOIN #tempResult c ON a.ItemInfo_ItemID=c.MID
WHERE b.DescFlexField_PrivateDescSeg3 NOT IN ('OT01','NEI01')
AND a.Effective_IsEffective=1
) t WHERE t.rn=1
),
InnerPPRData AS--内部厂商价表
(SELECT  COUNT(b.MID)IsExistsPrice,b.MID				--倒序排生效日
				FROM    PPR_PurPriceLine a1 INNER JOIN #tempResult b ON a1.ItemInfo_ItemID=b.MID
						INNER JOIN PPR_PurPriceList a2 ON a1.PurPriceList = a2.ID AND a2.Status = 2 AND a2.Cancel_Canceled = 0 AND a1.Active = 1
				WHERE   EXISTS ( SELECT 1 FROM CBO_Supplier WHERE DescFlexField_PrivateDescSeg3 ='NEI01' AND a2.Supplier = ID ) AND 
						a2.Org = @Org
						AND a1.FromDate <= GETDATE()
						GROUP BY b.MID
),
InnerSupplySource AS--内部货源
(
SELECT DISTINCT a.ItemInfo_ItemID FROM dbo.CBO_SupplySource a INNER JOIN dbo.CBO_Supplier b ON a.SupplierInfo_Supplier=b.ID
INNER JOIN #tempResult c ON a.ItemInfo_ItemID=c.MID
WHERE b.DescFlexField_PrivateDescSeg3 ='NEI01'
AND a.Effective_IsEffective=1
)
SELECT t.RN*10 RN,t.MRPCategory,t.Code,t.Name,t.SPECS,CEILING(t.UsageQty)UsageQty,t.DeliveryDate,t.SumLT,t.IsRecognize,t.IsItemSupplier
,t.IsSupplySource,t.IsExistsPrice,t.IsInnerSupplySource,t.IsInnerExistsPrice,t.Purchaser
,t.Buyer,t.MCName  FROM (
SELECT 
ROW_NUMBER() OVER(ORDER BY m.Code)RN
,mrp.Name MRPCategory
,m.Code,m.Name,m.SPECS,a.UsageQty,FORMAT(a.DeliveryDate,'yyyy-MM-dd HH:mm:ss')DeliveryDate,d.SumLT
,CASE WHEN ISNULL(o.IsRecognize,'')='True' THEN '是' ELSE '否' END IsRecognize
,CASE WHEN ISNULL(o.IsRecognize,'')='' THEN '否' ELSE '是' END IsItemSupplier
,CASE WHEN ISNULL(p.ItemInfo_ItemID,'')='' THEN '否' ELSE '是' END IsSupplySource
,CASE WHEN ISNULL(q.IsExistsPrice,0)=0 THEN '否' ELSE '是' END IsExistsPrice
,CASE WHEN ISNULL(ip.ItemInfo_ItemID,'')='' THEN '否' ELSE '是' END IsInnerSupplySource
,CASE WHEN ISNULL(iq.IsExistsPrice,0)=0 THEN '否' ELSE '是' END IsInnerExistsPrice
,op1.Name Purchaser,op21.Name Buyer,op31.Name MCName
FROM #tempResult a INNER JOIN dbo.CBO_MrpInfo d ON a.MID=d.ItemMaster
INNER JOIN dbo.CBO_ItemMaster m ON a.MID=m.ID --AND m.ItemFormAttribute=9--采购件
LEFT JOIN ItemSupplier o ON a.MID=o.ItemInfo_ItemID--供应商料品交叉
LEFT JOIN SupplySource p ON a.MID=p.ItemInfo_ItemID--货源表
LEFT JOIN PPRData q ON a.MID=q.MID--厂商价表
LEFT JOIN InnerSupplySource ip ON a.MID=ip.ItemInfo_ItemID--货源表
LEFT JOIN InnerPPRData iq ON a.MID=iq.MID--厂商价表
LEFT JOIN dbo.CBO_Operators op ON m.DescFlexField_PrivateDescSeg6=op.Code LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.id  AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_Operators op2 ON m.DescFlexField_PrivateDescSeg23=op2.Code LEFT JOIN dbo.CBO_Operators_Trl op21 ON op2.ID=op21.id  AND ISNULL(op21.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_Operators op3 ON m.DescFlexField_PrivateDescSeg24=op3.Code LEFT JOIN dbo.CBO_Operators_Trl op31 ON op3.ID=op31.id  AND ISNULL(op31.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN #tempDefineValue mrp ON m.DescFlexField_PrivateDescSeg22=mrp.Code
)t WHERE t.RN>@beginIndex AND t.RN<@endIndex

SELECT COUNT(*)Count FROM #tempResult

END 

