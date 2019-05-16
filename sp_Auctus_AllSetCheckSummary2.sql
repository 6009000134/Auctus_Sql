/*
标题：齐套分析报表2结果汇总表
需求人：蔡总
需求：将齐套分析报表2的结果按料号汇总，统计出3、7、15、30、45、60天需求以及欠料情况
*/
ALTER PROC [dbo].[sp_Auctus_AllSetCheckSummary2]
(
@Org BIGINT,
@DocList VARCHAR(max),
@DemandList VARCHAR(MAX),
@Wh VARCHAR(200),
@EndDate DATETIME,
@IsIncludeWPO VARCHAR(10),--是否包含WPO
@IsIncludeMo VARCHAR(10),--是否包含MO
@IsWMOOnly VARCHAR(10)--MO是否直选WMO
)
AS
BEGIN

DECLARE @Date DATE=GETDATE()
DECLARE @Date3 DATE
DECLARE @Date7 DATE
DECLARE @Date15 DATE
DECLARE @Date30 DATE
DECLARE @Date45 DATE
DECLARE @Date60 DATE
SET @Date3=DATEADD(DAY,3,@Date)--3天齐套预警
SET @Date7=DATEADD(DAY,7,@Date)--7天齐套预警
SET @Date15=DATEADD(DAY,15,@Date)--15天齐套预警
SET @Date30=DATEADD(DAY,30,@Date)--30天齐套预警
SET @Date45=DATEADD(DAY,45,@Date)--45天齐套预警
SET @Date60=DATEADD(DAY,60,@Date)--60天齐套预警
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
FixedLT DECIMAL(18,0)--固定提前期
)
ELSE
BEGIN
TRUNCATE TABLE #tempTable
END 

INSERT INTO #tempTable EXEC sp_Auctus_AllSetCheckWithDemandCode2 @Org,@DocList,@DemandList,@Wh,@Date60,@IsIncludeWPO,@IsIncludeMo,@IsWMOOnly
;
WITH data1 AS--料品信息
(
SELECT a.ItemMaster,a.Code,a.Name,a.SPEC,a.MRPCategory,a.Buyer,a.MCName FROM #tempTable a GROUP BY a.ItemMaster,a.Code,a.Name,a.SPEC,a.MRPCategory,a.Buyer,a.MCName
),
data3 AS--3天齐套结果
(
SELECT a.Code,SUM(a.ReqQty)ReqQty3,SUM(a.LackAmount)LackAmount3,MIN(a.WhavailiableAmount) WhavailiableAmount3
FROM #tempTable a 
WHERE a.ActualReqDate<@Date3
GROUP BY a.Code
),
data7 AS--7天齐套结果
(
SELECT a.Code,SUM(a.ReqQty)ReqQty7,SUM(a.LackAmount)LackAmount7,MIN(a.WhavailiableAmount) WhavailiableAmount7
FROM #tempTable a 
WHERE a.ActualReqDate<@Date7
GROUP BY a.Code
),
 data15 AS--15天齐套结果
(
SELECT a.Code,SUM(a.ReqQty)ReqQty15,SUM(a.LackAmount)LackAmount15,MIN(a.WhavailiableAmount) WhavailiableAmount15
FROM #tempTable a 
WHERE a.ActualReqDate<@Date15
GROUP BY a.Code
),
 data30 AS--30天齐套结果
(
SELECT a.Code,SUM(a.ReqQty)ReqQty30,SUM(a.LackAmount)LackAmount30,MIN(a.WhavailiableAmount) WhavailiableAmount30
FROM #tempTable a 
WHERE a.ActualReqDate<@Date30
GROUP BY a.Code
), data45 AS--45天齐套结果
(
SELECT a.Code,SUM(a.ReqQty)ReqQty45,SUM(a.LackAmount)LackAmount45,MIN(a.WhavailiableAmount) WhavailiableAmount45
FROM #tempTable a 
WHERE a.ActualReqDate<@Date45
GROUP BY a.Code
),
 data60 AS--60天齐套结果
(
SELECT a.Code,SUM(a.ReqQty)ReqQty60,SUM(a.LackAmount)LackAmount60,MIN(a.WhavailiableAmount) WhavailiableAmount60
FROM #tempTable a 
WHERE a.ActualReqDate<@Date60
GROUP BY a.Code
)
SELECT a.*
,ISNULL(a3.ReqQty3,0)三天需求量,ISNULL(a3.WhavailiableAmount3,0)三天库存可用量
,ISNULL(a7.ReqQty7,0)七天需求量,ISNULL(a7.WhavailiableAmount7,0)七天库存可用量
,ISNULL(a15.ReqQty15,0) 十五天需求量,ISNULL(a15.WhavailiableAmount15,0) 十五天库存可用量
,ISNULL(a30.ReqQty30,0)三十天需求量,ISNULL(a30.WhavailiableAmount30,0)三十天库存可用量
,ISNULL(a45.ReqQty45,0)四十五天需求量,ISNULL(a45.WhavailiableAmount45,0)四十五天库存可用量
,ISNULL(a60.ReqQty60,0)六十天需求量,ISNULL(a60.WhavailiableAmount60,0)六十天库存可用量
--,a3.ReqQty3,a3.LackAmount3,a3.WhavailiableAmount3
--,a7.ReqQty7,a7.LackAmount7,a7.WhavailiableAmount7
--,a15.ReqQty15,a15.LackAmount15,a15.WhavailiableAmount15
--,a30.ReqQty30,a30.LackAmount30,a30.WhavailiableAmount30
--,a45.ReqQty45,a45.LackAmount45,a45.WhavailiableAmount45
--,a60.ReqQty60,a60.LackAmount60,a60.WhavailiableAmount60
FROM data1 a LEFT JOIN data3 a3 ON a.Code=a3.Code LEFT JOIN data7 a7 ON a.Code=a7.Code
LEFT JOIN data15 a15 ON a.Code=a15.Code
LEFT JOIN data30 a30 ON a.Code=a30.Code
LEFT JOIN data45 a45 ON a.Code=a45.Code
LEFT JOIN data60 a60 ON a.Code=a60.Code


END 