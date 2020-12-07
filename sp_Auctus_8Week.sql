/*
8周欠交邮件基础上添加单价、金额、开发采购
*/
ALTER  PROC [dbo].[sp_Auctus_8Week]
(
@QueryDate DATE,
@Org BIGINT,
@UserName NVARCHAR(30)
)
as
BEGIN
--DECLARE @Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='300')
DECLARE @Date DATE
DECLARE @Date56 DATE
SET @Date=GETDATE()
SET @Date56=DATEADD(DAY,56,GETDATE())--15天齐套预警
--8周起始日期天汇总列表
DECLARE @SD1 DATE,@ED1 DATE
SET @SD1=DATEADD(DAY,2+(-1)*DATEPART(WEEKDAY,GETDATE()),GETDATE())
SET @ED1=DATEADD(DAY,7,@SD1)
SET @Date56=DATEADD(DAY,56,@SD1)--15天齐套预警
--SET @UserName='陶宗军'

IF OBJECT_ID(N'tempdb.dbo.#tempTable',N'U') IS NULL
CREATE TABLE #tempTable
(
DocNo VARCHAR(50),
DocLineNo VARCHAR(10),
PickLineNo VARCHAR(10),
DocType NVARCHAR(20),
ProductID BIGINT,
ProductCode VARCHAR(50),
ProductName NVARCHAR(255),
ProductSPECS NVARCHAR(300),
ProductQty DECIMAL(18,0),
DemandCode VARCHAR(20),
ItemMaster BIGINT,
Code VARCHAR(30),
Name NVARCHAR(255),
SPEC NVARCHAR(600),
SafetyStockQty DECIMAL(18,0),
IssuedQty DECIMAL(18,0),
STDReqQty DECIMAL(18,0),
ActualReqQty DECIMAL(18,0),
ReqQty DECIMAL(18,0),
ActualReqDate DATE,
RN INT,
DemandCode2 VARCHAR(50),
LackAmount INT,
IsLack NVARCHAR(20),
WhavailiableAmount INT,
PRList VARCHAR(MAX),
PRApprovedQty DECIMAL(18,0),
PRFlag NVARCHAR(10),
POList VARCHAR(MAX),
POReqQtyTu DECIMAL(18,0),
RCVList VARCHAR(MAX),
ArriveQtyTU DECIMAL(18,0),
RcvQtyTU DECIMAL(18,0),
RcvFlag NVARCHAR(10),
ResultFlag NVARCHAR(30),
DescFlexField_PrivateDescSeg19 NVARCHAR(300),--客户产品名称
DescFlexField_PrivateDescSeg20 NVARCHAR(300),--项目编码
DescFlexField_PrivateDescSeg21 NVARCHAR(300),--项目代号
DescFlexField_PrivateDescSeg23 NVARCHAR(300),--执行采购员
MRPCode VARCHAR(50),--MRP分类
MRPCategory NVARCHAR(300),--MRP分类
Buyer NVARCHAR(20),--执行采购分类
MCCode VARCHAR(20),--MC负责人编码
MCName NVARCHAR(20),--MC负责人
FixedLT DECIMAL(18,0),--固定提前期
ProductLine NVARCHAR(255)--产品系列
)
ELSE
TRUNCATE TABLE #tempTable

--INSERT INTO #tempTable EXEC sp_Auctus_AllSetCheckWithDemandCode2 1001708020135665,'','','',@Date56,'1','1','0'

--取每天7点备份的8周齐套数据
INSERT INTO #tempTable 
SELECT
DocNo ,
DocLineNo ,
PickLineNo ,
DocType ,
ProductID ,
ProductCode ,
ProductName ,
ProductSPECS ,
ProductQty ,
DemandCode ,
ItemMaster ,
Code ,
Name ,
SPEC ,
SafetyStockQty ,
IssuedQty ,
STDReqQty ,
ActualReqQty ,
ReqQty ,
ActualReqDate ,
RN ,
DemandCode2 ,
LackAmount ,
IsLack ,
WhavailiableAmount ,
PRList ,
PRApprovedQty ,
PRFlag ,
POList ,
POReqQtyTu ,
RCVList ,
ArriveQtyTU ,
RcvQtyTU ,
RcvFlag ,
ResultFlag ,
DescFlexField_PrivateDescSeg19 ,--客户产品名称
DescFlexField_PrivateDescSeg20 ,--项目编码
DescFlexField_PrivateDescSeg21 ,--项目代号
DescFlexField_PrivateDescSeg23 ,--执行采购员
MRPCode ,--MRP分类
MRPCategory ,--MRP分类
Buyer ,--执行采购分类
MCCode,--MC负责人编码
MCName,--MC负责人
FixedLT ,--固定提前期
ProductLine --产品系列
FROM dbo.Auctus_FullSetCheckResult8 
WHERE CONVERT(DATE,CopyDate)=@QueryDate



--安全库存欠交数量
;
WITH data1 AS
(
SELECT a.Code,MIN(a.SafetyStockQty)SafetyStockQty,MAX(a.RN)RN,MIN(a.WhavailiableAmount)WhavailiableAmount FROM #tempTable a
WHERE a.ActualReqDate<@SD1  AND a.SafetyStockQty>0
GROUP BY a.Code
)
SELECT a.Code
,CASE WHEN a.WhavailiableAmount<0 THEN a.SafetyStockQty
WHEN a.WhavailiableAmount>a.SafetyStockQty THEN 0
ELSE a.SafetyStockQty-a.WhavailiableAmount END SafeQtyLack INTO #tempLackSafe
FROM data1 a


--工单的实际需求时间=实际需求时间-原材料采购后处理期
--委外WPO实际需求时间=实际需求时间-采购组件采购前处理提前期-原材料采购后处理期
UPDATE #tempTable 
SET ActualReqDate=CASE WHEN #tempTable.DocNo LIKE'WPO%' THEN  DATEADD(DAY,(ISNULL(a.PurBackwardProcessLT,0)+ISNULL(b.PurForwardProcessLT,0))*(-1),ActualReqDate)
ELSE DATEADD(DAY,(ISNULL(a.PurBackwardProcessLT,0))*(-1),ActualReqDate) END 
FROM CBO_MrpInfo a,dbo.CBO_MrpInfo b WHERE a.ItemMaster=#tempTable.ItemMaster AND b.ItemMaster=#tempTable.ProductID

--8周汇总列表
;
WITH data1 AS
(
SELECT 
CASE WHEN a.ActualReqDate <@SD1  THEN 'w0'
WHEN a.ActualReqDate>=@SD1 AND a.ActualReqDate<@ED1 THEN 'w1'
WHEN a.ActualReqDate>=DATEADD(DAY,7,@SD1) AND a.ActualReqDate<DATEADD(DAY,7,@ED1) 
THEN 'w2'
WHEN a.ActualReqDate>=DATEADD(DAY,14,@SD1) AND a.ActualReqDate<DATEADD(DAY,14,@ED1) 
THEN 'w3'
WHEN a.ActualReqDate>=DATEADD(DAY,21,@SD1) AND a.ActualReqDate<DATEADD(DAY,21,@ED1) 
THEN 'w4'
WHEN a.ActualReqDate>=DATEADD(DAY,28,@SD1) AND a.ActualReqDate<DATEADD(DAY,28,@ED1) 
THEN 'w5'
WHEN a.ActualReqDate>=DATEADD(DAY,35,@SD1) AND a.ActualReqDate<DATEADD(DAY,35,@ED1) 
THEN 'w6'
WHEN a.ActualReqDate>=DATEADD(DAY,42,@SD1) AND a.ActualReqDate<DATEADD(DAY,42,@ED1) 
THEN 'w7'
WHEN a.ActualReqDate>=DATEADD(DAY,49,@SD1) AND a.ActualReqDate<DATEADD(DAY,49,@ED1) 
THEN 'w8'
ELSE '' END Duration
,a.MRPCategory,a.Buyer,a.MCName,a.Code,a.Name,a.SPEC,a.LackAmount
FROM #tempTable a 
),
data2 AS--行专列 汇总每周的欠料数量
(
SELECT * 
FROM data1 a  
PIVOT(SUM(a.LackAmount) FOR duration IN ([w0],[w1],[w2],[w3],[w4],[w5],[w6],[w7],[w8])) AS t
),
data3 AS
(
SELECT code,MAX(a.WhavailiableAmount+a.ReqQty)WhQty,min(a.WhAvailiableAmount)WhAvailiableAmount--,MIN(a.SafetyStockQty)SafetyStockQty
FROM #tempTable a  
GROUP BY a.Code 
)
SELECT a.*,b.WhQty,b.WhAvailiableAmount--,b.SafetyStockQty 
INTO #tempW8 
FROM data2  a LEFT JOIN data3 b ON a.Code=b.Code

DECLARE @TaxRate DECIMAL(18,2)=1.13--税率
;
WITH PPRData AS
(
 SELECT * FROM (SELECT   a1.ItemInfo_ItemCode,a1.ItemInfo_ItemName,
						CASE WHEN a2.currency=1 AND  a2.IsIncludeTax = 1 						THEN ISNULL(Price, 0)/@TaxRate
						WHEN a2.Currency=1 AND a2.IsIncludeTax=0						THEN ISNULL(Price, 0)
						WHEN a2.Currency!=1 AND a2.IsIncludeTax=1						THEN ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2)/@TaxRate
						ELSE ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2) END Price,
						ROW_NUMBER()OVER(PARTITION BY a1.ItemInfo_ItemCode ORDER BY a2.Org DESC,a1.FromDate DESC) AS rowNum					--倒序排生效日
				FROM    PPR_PurPriceLine a1 RIGHT JOIN (SELECT DISTINCT  code FROM #tempTable) c ON a1.ItemInfo_ItemCode=c.Code
						INNER JOIN PPR_PurPriceList a2 ON a1.PurPriceList = a2.ID AND a2.Status = 2 AND a2.Cancel_Canceled = 0 AND a1.Active = 1
				WHERE   NOT EXISTS ( SELECT 1 FROM CBO_Supplier WHERE DescFlexField_PrivateDescSeg3 = 'OT01' AND a2.Supplier = ID ) AND						
						a2.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
						AND a1.FromDate <= GETDATE())
						t WHERE t.rowNum=1	
)
SELECT ISNULL(a.MRPCategory,'')MRP分类,a.Code 料号,a.Name 品名,a.SPEC 规格
,ISNULL(a.Buyer,'')执行采购,ISNULL(a.MCName,'')MC责任人,ISNULL(op1.Name,'')开发采购
,ISNULL(b.SafeQtyLack,0) 安全库存欠料
,CASE WHEN ISNULL(a.w0,0)>0 THEN 0 ELSE ISNULL(a.w0,0)*(-1) END 逾期欠料
,CASE WHEN ISNULL(a.w1,0)>0 THEN 0 ELSE ISNULL(a.w1,0)*(-1) END 第一周 
,CASE WHEN ISNULL(a.w2,0)>0 THEN 0 ELSE ISNULL(a.w2,0)*(-1) END  第二周
,CASE WHEN ISNULL(a.w3,0)>0 THEN 0 ELSE ISNULL(a.w3,0)*(-1) END 第三周
,CASE WHEN ISNULL(a.w4,0)>0 THEN 0 ELSE ISNULL(a.w4,0)*(-1) END 第四周
,CASE WHEN ISNULL(a.w5,0)>0 THEN 0 ELSE ISNULL(a.w5,0)*(-1) END 第五周
,CASE WHEN ISNULL(a.w6,0)>0 THEN 0 ELSE ISNULL(a.w6,0)*(-1) END 第六周
,CASE WHEN ISNULL(a.w7,0)>0 THEN 0 ELSE ISNULL(a.w7,0)*(-1) END 第七周
,CASE WHEN ISNULL(a.w8,0)>0 THEN 0 ELSE ISNULL(a.w8,0)*(-1) END 第八周
,a.WhAvailiableAmount*(-1) '八周欠料'
,a.WhQty 现有库存
,p.Price 采购价
,CONVERT(DECIMAL(18,2),a.WhAvailiableAmount*(-1)*p.Price) 总金额
FROM #tempW8 a LEFT JOIN #tempLackSafe b ON a.Code=b.Code LEFT JOIN PPRData p ON a.Code=p.ItemInfo_ItemCode
LEFT JOIN dbo.CBO_ItemMaster m ON a.code=m.code AND m.org=@Org 
LEFT JOIN dbo.CBO_Operators op ON m.DescFlexField_PrivateDescSeg6=op.Code LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.ID AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.WhAvailiableAmount<0 AND ISNULL(op1.Name,'')=@UserName
ORDER BY ISNULL(a.w0,0),ISNULL(a.w1,0),ISNULL(a.w2,0),ISNULL(a.w3,0),ISNULL(a.w4,0),ISNULL(a.w5,0),ISNULL(a.w6,0),ISNULL(a.w7,0),ISNULL(a.w8,0),a.code 


	



END 