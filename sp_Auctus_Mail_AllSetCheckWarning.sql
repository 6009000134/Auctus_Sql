--七天齐套预警
/*
ADD(2019-3-4)
在7天未齐套单据列表后面增加一个7-15天未齐套单据列表
ADD(2019-3-6)
添加7天马来物料欠料数据
ADD(2019-3-9)
增加15天齐套率表格
ADD(2019-3-11)
马来修改成15天齐套并添加一个汇总表格
ADD(2019-6-3)
增加安全库存列
8周欠料汇总=所有欠料+安全库存
ADD(2019-6-18)
将内部生产的齐套表格数据剔除
Update(2019-12-9）--邹经理
将15天齐套改成14天
Update(2020-4-7)
MRP分类修改：
1、内部生产拆分为：包装、组装、后焊、功放、前加工
2、SMT委外拆分为：对讲机SMT委外、功放SMT委外
*/
ALTER PROC [dbo].[sp_Auctus_Mail_AllSetCheckWarning]
AS
BEGIN
DECLARE @html NVARCHAR(MAX)=''
DECLARE @Date DATE
DECLARE @Date2 DATE
DECLARE @Date3 DATE
DECLARE @Date7 DATE
DECLARE @Date15 DATE
DECLARE @Date21 DATE
DECLARE @Date56 DATE
--SET @Date=GETDATE()
SET @Date=GETDATE()
SET @Date2=DATEADD(DAY,2,@Date) --3天齐套预警
SET @Date3=DATEADD(DAY,3,@Date) --3天齐套预警
SET @Date7=DATEADD(DAY,7,@Date) --7天齐套预警
SET @Date15=DATEADD(DAY,14,@Date)--14天齐套预警
--SET @Date15=DATEADD(DAY,15,@Date)--15天齐套预警
SET @Date21=DATEADD(DAY,21,@Date)--21天齐套预警
SET @Date56=DATEADD(DAY,56,@Date)--15天齐套预警
--8周起始日期天汇总列表
DECLARE @SD1 DATE,@ED1 DATE
SET @SD1=DATEADD(DAY,2+(-1)*DATEPART(WEEKDAY,@Date),@Date)
SET @ED1=DATEADD(DAY,7,@SD1)
SET @Date56=DATEADD(DAY,56,@SD1)--15天齐套预警

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
WHERE CONVERT(DATE,CopyDate)=CONVERT(DATE,@Date)
AND PATINDEX('SO%',DocNo)=0
AND PATINDEX('FO%',DocNo)=0

--马来15天未齐套
IF object_id('tempdb.dbo.#tempMalai',N'U') is NULL
BEGIN
CREATE TABLE #tempMalai
(	 
DocNo VARCHAR(50),--委外单
DocLineNo VARCHAR(50),	
SOList VARCHAR(MAX), 
DocType NVARCHAR(20),
Itemmaster BIGINT,
Code VARCHAR(50),--备料
Name NVARCHAR(300),
SPEC NVARCHAR(600),     
ActualReqDate DATETIME,--实际需求日
Qty DECIMAL(18,0),--数量
DeliveredQty DECIMAL(18,0),--已出货数量
ReqQty DECIMAL(18,0),--实际需求数量-已发数量
LackAmount DECIMAL(18,0),--缺料数量
IsLack nvarchar(10),--齐套标识
WhAvailiableAmount DECIMAL(18,0),--库存可用量
MRPCategory NVARCHAR(15),
MRPCode VARCHAR(50),
Operators NVARCHAR(10),--执行采购
RN INT	 ,
ProductLine NVARCHAR(255)--产品系列
)
END
ELSE 
BEGIN
TRUNCATE TABLE #tempMalai
END
 INSERT INTO #tempMalai
 EXEC sp_Auctus_MalaiSetCheck 1001708020135665,'125','2000-01-01',@Date56
 
 INSERT INTO Auctus_Malai SELECT *,@Date FROM #tempMalai 
 

IF OBJECT_ID(N'tempdb.dbo.#tempResult',N'U') IS NULL
CREATE TABLE #tempResult
(
Operator NVARCHAR(20),
MRPCategory VARCHAR(50),
MRPCode VARCHAR(50),
totalCount INT,
totalPurchaseCount INT,
totalMakeCount INT,
LackCount INT,
LackPurchaseCount INT,
LackMakeCount INT,
UnLackCount INT,
UnLackPurchaseCount INT,
UnLackMakeCount INT,
Rate VARCHAR(20),
Type int
)
ELSE
TRUNCATE TABLE #tempResult




--3天齐套料品数据
;WITH data1 AS
(
SELECT DISTINCT a.Code,a.MRPCategory,a.MRPCode
,CASE WHEN a.MRPCategory='电子' OR a.MRPCategory='结构' OR a.MRPCategory='包材' OR a.MRPCategory='配件' THEN ISNULL(a.Buyer,'')
ELSE ISNULL(a.MCName,'')END   Operator --负责人：有采购取采购 ，无采购取PMC
,CASE WHEN  a.IsLack='缺料'THEN 1
ELSE 0 END ResultFlag--缺料标识
,CASE WHEN a.ActualReqDate<@Date2 THEN 1 ELSE 0 END IS2
,CASE WHEN a.ActualReqDate<@Date3 THEN 1 ELSE 0 END IS3
,CASE WHEN a.ActualReqDate<@Date7 THEN 1 ELSE 0 END IS7
,CASE WHEN a.ActualReqDate<@Date15 THEN 1 ELSE 0 END IS15
,CASE WHEN a.ActualReqDate<@Date21 THEN 1 ELSE 0 END IS21
,CASE WHEN m.ItemFormAttribute=9 THEN 1 ELSE 0 END PurchasePart
,CASE WHEN m.ItemFormAttribute=10 THEN 1 ELSE 0 END  MakePart
FROM #tempTable a --LEFT JOIN dbo.CBO_Operators b ON a.DescFlexField_PrivateDescSeg23=b.Code LEFT JOIN dbo.CBO_Operators_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_ItemMaster m ON a.ItemMaster=m.ID
WHERE (ISNULL(a.MRPCategory,'')<>'' or ISNULL(a.Buyer,'')<>'') --AND a.ActualReqDate<@Date3
AND a.DocNo<>'安全库存'
),
Result2 AS
(
SELECT a.Code,a.MRPCategory,a.MRPCode,ISNULL(a.Operator,'')Operator,SUM(a.ResultFlag)Result--Result=1，说明有缺料的数据，Result=0说明只有齐套数据 
,max(a.PurchasePart)PurchaseCount,max(a.MakePart)MakeCount
FROM data1 a 
WHERE a.IS2=1
GROUP BY a.Code,a.MRPCategory,a.MRPCode,a.Operator
),
LackResult2 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)LackCount,SUM(a.PurchaseCount)LackPurchaseCount,SUM(a.MakeCount)LackMakeCount
FROM Result2  a WHERE a.Result>0 GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
TotalResult2 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)totalCount ,SUM(a.PurchaseCount)totalPurchaseCount,SUM(a.MakeCount)totalMakeCount
FROM Result2  a GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
Result3 AS
(
SELECT a.Code,a.MRPCategory,a.MRPCode,ISNULL(a.Operator,'')Operator,SUM(a.ResultFlag)Result--Result=1，说明有缺料的数据，Result=0说明只有齐套数据 
,max(a.PurchasePart)PurchaseCount,max(a.MakePart)MakeCount
FROM data1 a 
WHERE a.IS3=1
GROUP BY a.Code,a.MRPCategory,a.MRPCode,a.Operator
),
LackResult3 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)LackCount ,SUM(a.PurchaseCount)LackPurchaseCount,SUM(a.MakeCount)LackMakeCount
FROM Result3  a WHERE a.Result>0 GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
TotalResult3 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)totalCount 
,SUM(a.PurchaseCount)totalPurchaseCount,SUM(a.MakeCount)totalMakeCount
FROM Result3  a GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
Result7 AS
(
SELECT a.Code,a.MRPCategory,a.MRPCode,ISNULL(a.Operator,'')Operator,SUM(a.ResultFlag)Result--Result=1，说明有缺料的数据，Result=0说明只有齐套数据 
,max(a.PurchasePart)PurchaseCount,max(a.MakePart)MakeCount
FROM data1 a 
WHERE a.IS7=1
GROUP BY a.Code,a.MRPCategory,a.MRPCode,a.Operator
),
LackResult7 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)LackCount  ,SUM(a.PurchaseCount)LackPurchaseCount,SUM(a.MakeCount)LackMakeCount
FROM Result7  a WHERE a.Result>0 GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
TotalResult7 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)totalCount,SUM(a.PurchaseCount)totalPurchaseCount,SUM(a.MakeCount)totalMakeCount
FROM Result7  a GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
Result15 AS
(
SELECT a.Code,a.MRPCategory,a.MRPCode,ISNULL(a.Operator,'')Operator,SUM(a.ResultFlag)Result--Result=1，说明有缺料的数据，Result=0说明只有齐套数据 
,max(a.PurchasePart)PurchaseCount,max(a.MakePart)MakeCount
FROM data1 a 
WHERE a.IS15=1
GROUP BY a.Code,a.MRPCategory,a.MRPCode,a.Operator
),
LackResult15 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)LackCount  ,SUM(a.PurchaseCount)LackPurchaseCount,SUM(a.MakeCount)LackMakeCount
FROM Result15  a WHERE a.Result>0 GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
TotalResult15 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)totalCount,SUM(a.PurchaseCount)totalPurchaseCount,SUM(a.MakeCount)totalMakeCount FROM Result15  a GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
Result21 AS
(
SELECT a.Code,a.MRPCategory,a.MRPCode,ISNULL(a.Operator,'')Operator,SUM(a.ResultFlag)Result--Result=1，说明有缺料的数据，Result=0说明只有齐套数据 
,max(a.PurchasePart)PurchaseCount,max(a.MakePart)MakeCount
FROM data1 a 
WHERE a.IS21=1
GROUP BY a.Code,a.MRPCategory,a.MRPCode,a.Operator
),
LackResult21 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)LackCount  ,SUM(a.PurchaseCount)LackPurchaseCount,SUM(a.MakeCount)LackMakeCount
FROM Result21  a WHERE a.Result>0 GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
TotalResult21 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)totalCount,SUM(a.PurchaseCount)totalPurchaseCount,SUM(a.MakeCount)totalMakeCount FROM Result21  a GROUP BY a.Operator,a.MRPCategory,a.MRPCode
)
INSERT INTO #tempResult
SELECT a.*,ISNULL(b.LackCount,0)LackCount,ISNULL(b.LackPurchaseCount,0),ISNULL(b.LackMakeCount,0),a.totalCount-ISNULL(b.LackCount,0) UnLackCount
,a.totalPurchaseCount-ISNULL(b.LackPurchaseCount,0),a.totalMakeCount-ISNULL(b.LackMakeCount,0)
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.totalCount-ISNULL(b.LackCount,0))/CONVERT(DECIMAL(18,4),a.totalCount)*100))+'%' Rate
,2
FROM  TotalResult2 a LEFT JOIN LackResult2 b ON a.Operator=b.Operator AND a.MRPCategory=b.MRPCategory
UNION ALL
SELECT a.*,ISNULL(b.LackCount,0)LackCount,ISNULL(b.LackPurchaseCount,0),ISNULL(b.LackMakeCount,0),a.totalCount-ISNULL(b.LackCount,0) UnLackCount
,a.totalPurchaseCount-ISNULL(b.LackPurchaseCount,0),a.totalMakeCount-ISNULL(b.LackMakeCount,0)
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.totalCount-ISNULL(b.LackCount,0))/CONVERT(DECIMAL(18,4),a.totalCount)*100))+'%' Rate
,3
FROM  TotalResult3 a LEFT JOIN LackResult3 b ON a.Operator=b.Operator AND a.MRPCategory=b.MRPCategory
UNION ALL
SELECT a.*,ISNULL(b.LackCount,0)LackCount,ISNULL(b.LackPurchaseCount,0),ISNULL(b.LackMakeCount,0),a.totalCount-ISNULL(b.LackCount,0) UnLackCount
,a.totalPurchaseCount-ISNULL(b.LackPurchaseCount,0),a.totalMakeCount-ISNULL(b.LackMakeCount,0)
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.totalCount-ISNULL(b.LackCount,0))/CONVERT(DECIMAL(18,4),a.totalCount)*100))+'%' Rate,7
FROM TotalResult7  a LEFT JOIN LackResult7 b ON a.Operator=b.Operator AND a.MRPCategory=b.MRPCategory
UNION ALL
SELECT a.*,ISNULL(b.LackCount,0)LackCount,ISNULL(b.LackPurchaseCount,0),ISNULL(b.LackMakeCount,0),a.totalCount-ISNULL(b.LackCount,0) UnLackCount
,a.totalPurchaseCount-ISNULL(b.LackPurchaseCount,0),a.totalMakeCount-ISNULL(b.LackMakeCount,0)
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.totalCount-ISNULL(b.LackCount,0))/CONVERT(DECIMAL(18,4),a.totalCount)*100))+'%' Rate,15
FROM TotalResult15  a LEFT JOIN LackResult15 b ON a.Operator=b.Operator AND a.MRPCategory=b.MRPCategory
UNION ALL
SELECT a.*,ISNULL(b.LackCount,0)LackCount,ISNULL(b.LackPurchaseCount,0),ISNULL(b.LackMakeCount,0),a.totalCount-ISNULL(b.LackCount,0) UnLackCount
,a.totalPurchaseCount-ISNULL(b.LackPurchaseCount,0),a.totalMakeCount-ISNULL(b.LackMakeCount,0)
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.totalCount-ISNULL(b.LackCount,0))/CONVERT(DECIMAL(18,4),a.totalCount)*100))+'%' Rate,21
FROM TotalResult21  a LEFT JOIN LackResult21 b ON a.Operator=b.Operator AND a.MRPCategory=b.MRPCategory



--15天马来天齐套料品数据
;
WITH data1 AS
(
SELECT DISTINCT a.Code,a.MRPCategory,a.MRPCode
,a.Operators Operator --负责人：有采购取采购 ，无采购取PMC
,CASE WHEN a.IsLack='缺料'THEN 1
ELSE 0 END ResultFlag--缺料标识
FROM #tempMalai a --LEFT JOIN dbo.CBO_Operators b ON a.DescFlexField_PrivateDescSeg23=b.Code LEFT JOIN dbo.CBO_Operators_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
WHERE (ISNULL(a.MRPCategory,'')<>'' or ISNULL(a.Operators,'')<>'') AND a.ActualReqDate<@Date15
AND a.DocNo<>'安全库存'
),
Result AS
(
SELECT a.Code,a.MRPCategory,a.MRPCode,a.Operator,SUM(a.ResultFlag)Result--Result=1，说明有缺料的数据，Result=0说明只有齐套数据 
FROM data1 a GROUP BY a.Code,a.MRPCategory,a.MRPCode,a.Operator
),
Result2 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)LackCount FROM Result  a WHERE a.Result>0 GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
Result3 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)totalCount FROM Result  a GROUP BY a.Operator,a.MRPCategory,a.MRPCode
)
INSERT INTO #tempResult
SELECT a.Operator,a.MRPCategory,a.MRPCode,a.totalCount,0,0,ISNULL(b.LackCount,0)LackCount,0,0,a.totalCount-ISNULL(b.LackCount,0) UnLackCount,0,0
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.totalCount-ISNULL(b.LackCount,0))/CONVERT(DECIMAL(18,4),a.totalCount)*100))+'%' Rate
,152
FROM Result3 a LEFT JOIN Result2 b ON a.Operator=b.Operator AND a.MRPCategory=b.MRPCategory


--按人员统计工单齐套率



;
WITH data1 AS
(
SELECT c1.Name Op,b.DescFlexField_PrivateDescSeg22 ProMRP,mrp.Name ProMRPCategory,a.*
,CASE WHEN a.ActualReqDate<@Date2 THEN 1 ELSE 0 END IS2
,CASE WHEN a.ActualReqDate<@Date3 THEN 1 ELSE 0 END IS3
,CASE WHEN a.ActualReqDate<@Date7 THEN 1 ELSE 0 END IS7
,CASE WHEN a.ActualReqDate<@Date15 THEN 1 ELSE 0 END IS15
,CASE WHEN a.ActualReqDate<@Date21 THEN 1 ELSE 0 END IS21
FROM #tempTable a LEFT JOIN dbo.CBO_ItemMaster b ON a.ProductID=b.ID
LEFT JOIN dbo.CBO_Operators c ON b.DescFlexField_PrivateDescSeg24=c.Code LEFT JOIN dbo.CBO_Operators_Trl c1 ON c.ID=c1.ID
LEFT JOIN dbo.vw_MRPCategory mrp ON b.DescFlexField_PrivateDescSeg22=mrp.Code
WHERE a.ActualReqDate<@Date21 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND b.DescFlexField_PrivateDescSeg22 NOT IN ('MRP104','MRP105','MRP106','MRP113')
AND a.DocNo<>'安全库存'
),
TotalCount2 AS
(
SELECT a.Op,a.ProMRP,a.ProMRPCategory,COUNT(a.DocNo)total,22 T FROM 
(SELECT DISTINCT a.ProMRP,ProMRPCategory,a.Op,a.DocNo FROM data1 a WHERE a.IS2=1) a GROUP BY a.Op,a.ProMRP,a.ProMRPCategory
),
UnTotalCount2 AS
(
SELECT a.Op,a.ProMRP,a.ProMRPCategory,COUNT(a.DocNo)untotal,22 T FROM 
(SELECT DISTINCT a.ProMRP,a.ProMRPCategory,a.Op,a.DocNo,a.IsLack FROM data1 a WHERE a.IS2=1 AND a.IsLack='缺料')a GROUP BY a.Op,a.ProMRP,a.ProMRPCategory
),
TotalCount3 AS
(
SELECT a.Op,a.ProMRP,a.ProMRPCategory,COUNT(a.DocNo)total,33 T FROM 
(SELECT DISTINCT a.ProMRP,ProMRPCategory,a.Op,a.DocNo FROM data1 a WHERE a.IS3=1) a GROUP BY a.Op,a.ProMRP,a.ProMRPCategory
),
UnTotalCount3 AS
(
SELECT a.Op,a.ProMRP,a.ProMRPCategory,COUNT(a.DocNo)untotal,33 T FROM 
(SELECT DISTINCT a.ProMRP,a.ProMRPCategory,a.Op,a.DocNo,a.IsLack FROM data1 a WHERE a.IS3=1 AND a.IsLack='缺料')a GROUP BY a.Op,a.ProMRP,a.ProMRPCategory
),
TotalCount7 AS
(
SELECT a.Op,a.ProMRP,a.ProMRPCategory,COUNT(a.DocNo)total,77 T FROM 
(SELECT DISTINCT a.ProMRP,a.ProMRPCategory,a.Op,a.DocNo FROM data1 a WHERE a.IS7=1) a GROUP BY a.Op,a.ProMRP,a.ProMRPCategory
),
UnTotalCount7 AS
(
SELECT a.Op,a.ProMRP,a.ProMRPCategory,COUNT(a.DocNo)untotal,77 T FROM 
(SELECT DISTINCT a.ProMRP,a.ProMRPCategory,a.Op,a.DocNo,a.IsLack FROM data1 a WHERE a.IS7=1 AND a.IsLack='缺料')a GROUP BY a.Op,a.ProMRP,a.ProMRPCategory
),
TotalCount15 AS
(
SELECT a.Op,a.ProMRP,a.ProMRPCategory,COUNT(a.DocNo)total,1515 T FROM 
(SELECT DISTINCT a.ProMRP,a.ProMRPCategory,a.Op,a.DocNo FROM data1 a WHERE a.IS15=1) a GROUP BY a.Op,a.ProMRP,a.ProMRPCategory
),
UnTotalCount15 AS
(
SELECT a.Op,a.ProMRP,a.ProMRPCategory,COUNT(a.DocNo)untotal,1515 T FROM 
(SELECT DISTINCT a.ProMRP,a.ProMRPCategory,a.Op,a.DocNo,a.IsLack FROM data1 a WHERE a.IS15=1 AND a.IsLack='缺料')a GROUP BY a.Op,a.ProMRP,a.ProMRPCategory
),
TotalCount21 AS
(
SELECT a.Op,a.ProMRP,a.ProMRPCategory,COUNT(a.DocNo)total,2121 T FROM 
(SELECT DISTINCT a.ProMRP,a.ProMRPCategory,a.Op,a.DocNo FROM data1 a WHERE a.IS21=1) a GROUP BY a.Op,a.ProMRP,a.ProMRPCategory
),
UnTotalCount21 AS
(
SELECT a.Op,a.ProMRP,a.ProMRPCategory,COUNT(a.DocNo)untotal,2121 T FROM 
(SELECT DISTINCT a.ProMRP,a.ProMRPCategory,a.Op,a.DocNo,a.IsLack FROM data1 a WHERE a.IS21=1 AND a.IsLack='缺料')a GROUP BY a.Op,a.ProMRP,a.ProMRPCategory
)
INSERT INTO #TempResult
SELECT a.Op,a.ProMRPCategory,a.ProMRP,a.total,0,0,ISNULL(b.untotal,0)untotal,0,0,a.total-ISNULL(b.untotal,0),0,0,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.total-ISNULL(b.untotal,0))/CONVERT(DECIMAL(18,4),a.total)*100))+'%' Rate,a.T FROM TotalCount2 a LEFT JOIN UnTotalCount2 b ON a.Op=b.Op AND b.ProMRP = a.ProMRP
UNION
SELECT a.Op,a.ProMRPCategory,a.ProMRP,a.total,0,0,ISNULL(b.untotal,0)untotal,0,0,a.total-ISNULL(b.untotal,0),0,0,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.total-ISNULL(b.untotal,0))/CONVERT(DECIMAL(18,4),a.total)*100))+'%' Rate,a.T FROM TotalCount3 a LEFT JOIN UnTotalCount3 b ON a.Op=b.Op AND b.ProMRP = a.ProMRP
UNION
SELECT a.Op,a.ProMRPCategory,a.ProMRP,a.total,0,0,ISNULL(b.untotal,0)untotal,0,0,a.total-ISNULL(b.untotal,0),0,0,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.total-ISNULL(b.untotal,0))/CONVERT(DECIMAL(18,4),a.total)*100))+'%' Rate,a.T FROM TotalCount7 a LEFT JOIN UnTotalCount7 b ON a.Op=b.Op AND b.ProMRP = a.ProMRP
UNION
SELECT a.Op,a.ProMRPCategory,a.ProMRP,a.total,0,0,ISNULL(b.untotal,0)untotal,0,0,a.total-ISNULL(b.untotal,0),0,0,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.total-ISNULL(b.untotal,0))/CONVERT(DECIMAL(18,4),a.total)*100))+'%' Rate,a.T FROM TotalCount15 a LEFT JOIN UnTotalCount15 b ON a.Op=b.Op AND b.ProMRP = a.ProMRP
UNION
SELECT a.Op,a.ProMRPCategory,a.ProMRP,a.total,0,0,ISNULL(b.untotal,0)untotal,0,0,a.total-ISNULL(b.untotal,0),0,0,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.total-ISNULL(b.untotal,0))/CONVERT(DECIMAL(18,4),a.total)*100))+'%' Rate,a.T FROM TotalCount21 a LEFT JOIN UnTotalCount21 b ON a.Op=b.Op AND b.ProMRP = a.ProMRP




;
WITH data1 AS
(
SELECT a.DocNo,a.Code,a.IsLack,a.Buyer,a.MRPCode,a.MRPCategory
,CASE WHEN a.ActualReqDate<@Date2 THEN 1 ELSE '' END IS2
,CASE WHEN a.ActualReqDate<@Date3 THEN 1 ELSE '' END IS3
,CASE WHEN a.ActualReqDate<@Date7 THEN 1 ELSE '' END IS7
,CASE WHEN a.ActualReqDate<@Date15 THEN 1 ELSE '' END IS15
,CASE WHEN a.ActualReqDate<@Date21 THEN 1 ELSE '' END IS21
FROM #tempTable a WHERE a.MRPCategory IN ('电子','结构','包材','配件')
AND a.ActualReqDate<@Date21
AND a.DocNo<>'安全库存'
),
Total AS
(
SELECT a.Buyer,a.MRPCode,a.MRPCategory,COUNT(a.DocNo)Total,22 T FROM (SELECT DISTINCT a.DocNo,a.Buyer,a.MRPCode,a.MRPCategory,a.IS2,a.IS3,a.IS7,a.IS15 FROM data1 a) a WHERE a.IS2=1
GROUP BY a.Buyer,a.MRPCode,a.MRPCategory
UNION 
SELECT a.Buyer,a.MRPCode,a.MRPCategory,COUNT(a.DocNo)Total,33 T FROM (SELECT DISTINCT a.DocNo,a.Buyer,a.MRPCode,a.MRPCategory,a.IS3,a.IS7,a.IS15 FROM data1 a) a WHERE a.IS3=1
GROUP BY a.Buyer,a.MRPCode,a.MRPCategory
UNION 
SELECT a.Buyer,a.MRPCode,a.MRPCategory,COUNT(a.DocNo)Total,77 T FROM (SELECT DISTINCT a.DocNo,a.Buyer,a.MRPCode,a.MRPCategory,a.IS3,a.IS7,a.IS15 FROM data1 a) a WHERE a.IS7=1
GROUP BY a.Buyer,a.MRPCode,a.MRPCategory
UNION 
SELECT a.Buyer,a.MRPCode,a.MRPCategory,COUNT(a.DocNo)Total,1515 T FROM (SELECT DISTINCT a.DocNo,a.Buyer,a.MRPCode,a.MRPCategory,a.IS3,a.IS7,a.IS15 FROM data1 a) a WHERE a.IS15=1
GROUP BY a.Buyer,a.MRPCode,a.MRPCategory
UNION 
SELECT a.Buyer,a.MRPCode,a.MRPCategory,COUNT(a.DocNo)Total,2121 T FROM (SELECT DISTINCT a.DocNo,a.Buyer,a.MRPCode,a.MRPCategory,a.IS3,a.IS7,a.IS15,a.IS21 FROM data1 a) a WHERE a.IS21=1
GROUP BY a.Buyer,a.MRPCode,a.MRPCategory
),
UnTotal AS
(
SELECT a.Buyer,a.MRPCode,a.MRPCategory,COUNT(a.DocNo)Total,22 T FROM (SELECT DISTINCT a.DocNo,a.Buyer,a.MRPCode,a.MRPCategory,a.IS2,a.IS3,a.IS7,a.IS15 FROM data1 a WHERE a.IsLack='缺料') a WHERE a.IS2=1
GROUP BY a.Buyer,a.MRPCode,a.MRPCategory
UNION 
SELECT a.Buyer,a.MRPCode,a.MRPCategory,COUNT(a.DocNo)Total,33 T FROM (SELECT DISTINCT a.DocNo,a.Buyer,a.MRPCode,a.MRPCategory,a.IS3,a.IS7,a.IS15 FROM data1 a WHERE a.IsLack='缺料') a WHERE a.IS3=1
GROUP BY a.Buyer,a.MRPCode,a.MRPCategory
UNION 
SELECT a.Buyer,a.MRPCode,a.MRPCategory,COUNT(a.DocNo)Total,77 T FROM (SELECT DISTINCT a.DocNo,a.Buyer,a.MRPCode,a.MRPCategory,a.IS3,a.IS7,a.IS15 FROM data1 a WHERE a.IsLack='缺料') a WHERE a.IS7=1
GROUP BY a.Buyer,a.MRPCode,a.MRPCategory
UNION 
SELECT a.Buyer,a.MRPCode,a.MRPCategory,COUNT(a.DocNo)Total,1515 T FROM (SELECT DISTINCT a.DocNo,a.Buyer,a.MRPCode,a.MRPCategory,a.IS3,a.IS7,a.IS15 FROM data1 a WHERE a.IsLack='缺料') a WHERE a.IS15=1
GROUP BY a.Buyer,a.MRPCode,a.MRPCategory
UNION 
SELECT a.Buyer,a.MRPCode,a.MRPCategory,COUNT(a.DocNo)Total,2121 T FROM (SELECT DISTINCT a.DocNo,a.Buyer,a.MRPCode,a.MRPCategory,a.IS3,a.IS7,a.IS15,a.IS21 FROM data1 a WHERE a.IsLack='缺料') a WHERE a.IS21=1
GROUP BY a.Buyer,a.MRPCode,a.MRPCategory
)
INSERT INTO #tempResult
SELECT a.Buyer,a.MRPCategory,a.MRPCode,a.Total,0,0,ISNULL(b.Total,0) UnTotal,0,0,a.Total-ISNULL(b.Total,0),0,0,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.Total-ISNULL(b.Total,0))/CONVERT(DECIMAL(18,4),a.Total)*100))+'%',a.T 
FROM Total a LEFT JOIN UnTotal b ON a.Buyer=b.Buyer AND a.T=b.T AND a.MRPCode=b.MRPCode


--统计工单备料单制造件和采购件的齐套、不齐套数量
IF OBJECT_ID(N'tempdb.dbo.#tempKit',N'U') IS NULL
	CREATE TABLE #tempKit
	(
	MRPCode VARCHAR(50),
	MPRName VARCHAR(50),
	PurKit INT,
	PurKitNot INT,
	MakeKit INT,
	MakeKitNot INT,
	Type INT
	)
ELSE
	TRUNCATE TABLE #tempKit

;
WITH data1 AS
(
SELECT c1.Name Op,b.DescFlexField_PrivateDescSeg22 ProMRP,mrp.Name ProMRPCategory,a.*
,CASE WHEN a.ActualReqDate<@Date2 THEN 1 ELSE 0 END IS2
,CASE WHEN a.ActualReqDate<@Date3 THEN 1 ELSE 0 END IS3
,CASE WHEN a.ActualReqDate<@Date7 THEN 1 ELSE 0 END IS7
,CASE WHEN a.ActualReqDate<@Date15 THEN 1 ELSE 0 END IS15
,CASE WHEN a.ActualReqDate<@Date21 THEN 1 ELSE 0 END IS21
,CASE WHEN a.islack='齐套' AND m.ItemFormAttribute=9 THEN 1 ELSE 0 END PurKit
,CASE WHEN a.islack!='齐套' AND m.ItemFormAttribute=9 THEN -1 ELSE 0 END PurKitNot
,CASE WHEN a.islack='齐套' AND m.ItemFormAttribute=10 THEN 1 ELSE 0 END MakeKit
,CASE WHEN a.islack!='齐套' AND m.ItemFormAttribute=10 THEN -1 ELSE 0 END MakeKitNot
FROM #tempTable a LEFT JOIN dbo.CBO_ItemMaster b ON a.ProductID=b.ID
LEFT JOIN dbo.CBO_Operators c ON b.DescFlexField_PrivateDescSeg24=c.Code LEFT JOIN dbo.CBO_Operators_Trl c1 ON c.ID=c1.ID
LEFT JOIN dbo.vw_MRPCategory mrp ON b.DescFlexField_PrivateDescSeg22=mrp.Code
LEFT JOIN dbo.CBO_ItemMaster m ON a.itemmaster=m.ID
WHERE a.ActualReqDate<@Date21 AND b.DescFlexField_PrivateDescSeg22 NOT IN ('MRP104','MRP105','MRP106','MRP113')
AND a.DocNo<>'安全库存'
)
INSERT INTO #tempKit
        ( MRPCode ,
          MPRName ,
          PurKit ,
          PurKitNot ,
          MakeKit ,
          MakeKitNot ,
          Type
        )
SELECT a.ProMRP,a.ProMRPCategory
,SUM(a.PurKit)PurKit,SUM(a.PurKitNot)PurKitNot 
,SUM(a.MakeKit)MakeKit,SUM(a.MakeKitNot)MakeKitNot ,333
FROM data1 a 
WHERE a.is3=1
GROUP BY a.ProMRP,a.ProMRPCategory
UNION ALL
SELECT a.ProMRP,a.ProMRPCategory
,SUM(a.PurKit)PurKit,SUM(a.PurKitNot)PurKitNot 
,SUM(a.MakeKit)MakeKit,SUM(a.MakeKitNot)MakeKitNot ,777
FROM data1 a 
WHERE a.is7=1
GROUP BY a.ProMRP,a.ProMRPCategory
UNION ALL
SELECT a.ProMRP,a.ProMRPCategory
,SUM(a.PurKit)PurKit,SUM(a.PurKitNot)PurKitNot 
,SUM(a.MakeKit)MakeKit,SUM(a.MakeKitNot)MakeKitNot ,151515
FROM data1 a 
WHERE a.is15=1
GROUP BY a.ProMRP,a.ProMRPCategory
UNION ALL
SELECT a.ProMRP,a.ProMRPCategory
,SUM(a.PurKit)PurKit,SUM(a.PurKitNot)PurKitNot 
,SUM(a.MakeKit)MakeKit,SUM(a.MakeKitNot)MakeKitNot ,212121
FROM data1 a 
WHERE a.is21=1
GROUP BY a.ProMRP,a.ProMRPCategory



--3x天工单齐套率
DECLARE @totalMOFullSetRate3 VARCHAR(20)
DECLARE @totalMONum3 INT
DECLARE @totalUnMoNum3 INT
SELECT @totalMONum3=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
SELECT @totalUnMoNum3=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
SELECT @totalMOFullSetRate3=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum3-@totalUnMoNum3)/CONVERT(DECIMAL(18,4),@totalMONum3)*100))+'%'


DECLARE @shichanRate3 VARCHAR(20)
DECLARE @shichan3 INT
DECLARE @shichanUn3 INT
SELECT @shichan3=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0
SELECT @shichanUn3=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0

SELECT @shichanRate3=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@shichan3-@shichanUn3)/CONVERT(DECIMAL(18,4),@shichan3)*100))+'%'


DECLARE @fxRate3 VARCHAR(20)
DECLARE @fx3 INT
DECLARE @fxUn3 INT
SELECT @fx3=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0
SELECT @fxUn3=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0

SELECT @fxRate3=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@fx3-@fxUn3)/CONVERT(DECIMAL(18,4),@fx3)*100))+'%'



--功放3x天工单齐套率
DECLARE @totalMOFullSetRate1003 VARCHAR(20)
DECLARE @totalMONum1003 INT
DECLARE @totalUnMoNum1003 INT
SELECT @totalMONum1003=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.ProductLine='功放' AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)=0 AND PATINDEX('%返修%',a.DocType)=0 
SELECT @totalUnMoNum1003=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.ProductLine='功放' AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存' 
AND PATINDEX('%试产%',a.DocType)=0 AND PATINDEX('%返修%',a.DocType)=0 


--对讲机3x天工单齐套率 --对讲机的工单数=总工单数-功放工单数
DECLARE @totalMOFullSetRate2003 VARCHAR(20)
DECLARE @totalMONum2003 INT=@totalMONum3-@totalMONum1003-ISNULL(@shichan3,0)-ISNULL(@fx3,0)
DECLARE @totalUnMoNum2003 INT=@totalUnMoNum3-@totalUnMoNum1003-ISNULL(@shichanUn3,0)-ISNULL(@fxUn3,0)
SELECT @totalMOFullSetRate2003=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum2003-@totalUnMoNum2003)/CONVERT(DECIMAL(18,4),@totalMONum2003)*100))+'%'

SET @html=N'<h2 style="color:red;font-weight:bold;">3天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum3-@totalUnMoNum3))+'/'+CONVERT(VARCHAR(30),@totalMONum3)+'='+@totalMOFullSetRate3+'</h2>'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">对讲机3天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum2003-@totalUnMoNum2003))+'/'+CONVERT(VARCHAR(30),@totalMONum2003)+'='+@totalMOFullSetRate2003+'</h2>'
IF @totalMONum1003<>0
BEGIN
SELECT @totalMOFullSetRate1003=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum1003-@totalUnMoNum1003)/CONVERT(DECIMAL(18,4),@totalMONum1003)*100))+'%'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">功放3天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum1003-@totalUnMoNum1003))+'/'+CONVERT(VARCHAR(30),@totalMONum1003)+'='+@totalMOFullSetRate1003+'</h2>'
END 
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">试产3天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@shichan3-@shichanUn3))+'/'+CONVERT(VARCHAR(30),@shichan3)+'='+@shichanRate3+'</h2>'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">返修3天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@fx3-@fxUn3))+'/'+CONVERT(VARCHAR(30),@fx3)+'='+@fxRate3+'</h2>'
--采购3天齐套率=包材、配件2天+电子、结构3天
;
WITH data1 AS
(
SELECT a.DocNo,a.IsLack FROM #tempTable a WHERE a.ActualReqDate<@Date3
AND a.MRPCode IN ('MRP104','MRP106')
UNION ALL
SELECT a.DocNo,a.IsLack FROM #tempTable a WHERE a.ActualReqDate<@Date2
AND a.MRPCode IN ('MRP105','MRP113')
),
TotalCount as
(
SELECT COUNT(DISTINCT a.docno)Total FROM data1 a
),
LackCount AS
(
SELECT COUNT(DISTINCT a.docNo)lc FROM data1 a WHERE a.IsLack='缺料'
)
SELECT @html=@html+N'<h2 style="color:red;font-weight:bold;">采购3天齐套率（齐套工单/总工单数）：'+ISNULL(CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(1.00-(SELECT * FROM LackCount)/CONVERT(DECIMAL(18,4),(SELECT * FROM TotalCount a)))*100.00))+'%','')



--2天包材、配件
;WITH data1 AS
(
SELECT *FROM #tempResult WHERE type=2 and  MRPCode IN ('MRP105','MRP113') 
),data2 AS
(
SELECT *FROM #tempResult WHERE type=22 and  MRPCode IN ('MRP105','MRP113') 
)
SELECT @html=@html+N'<H2 bgcolor="#7CFC00">3天齐套率(齐套的料号/总的料号数量)</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#cae7fc"><th nowrap="nowrap" rowspan="2">类别</th><th nowrap="nowrap" rowspan="2">负责人</th>
<th nowrap="nowrap" rowspan="2">MRP分类</th>
<th nowrap="nowrap" colspan="4">物料</th>
<th nowrap="nowrap" colspan="7">工单</th>
</tr>'+
'<tr bgcolor="#cae7fc">
<th nowrap="nowrap">物料数量</th><th nowrap="nowrap">齐套物料数</th><th nowrap="nowrap">不齐套物料数</th>
<th nowrap="nowrap">料号齐套率</th><th nowrap="nowrap">工单总数</th><th nowrap="nowrap">齐套工单数</th>
<th nowrap="nowrap">齐套外购件数</th><th nowrap="nowrap">不齐套外购件数</th>
<th nowrap="nowrap">齐套自制件数</th><th nowrap="nowrap">不齐套自制件数</th>
<th nowrap="nowrap">工单齐套率</th>
</tr>'
+ISNULL(CAST((SELECT td='原材料','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory)+'_2天',''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.UnLackPurchaseCount,0)+ISNULL(a.UnLackMakeCount,0),'',td=ISNULL(a.LackPurchaseCount,0)+ISNULL(a.LackMakeCount,0),''
,td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0)
,'',td='','',td='','',td='','',td='','',td=ISNULL(b.Rate,'')
FROM data1 a FULL JOIN data2 b ON a.Operator=b.Operator AND a.MRPCode=b.MRPCode
ORDER BY a.Type,CASE WHEN a.MRPCode='MRP104'THEN 1
WHEN a.MRPCode='MRP106' THEN 2 
WHEN a.MRPCode='MRP105' THEN 3
WHEN a.MRPCode='MRP113' THEN 4 ELSE 5 END   FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')

--3天原材料
;WITH data1 AS
(
SELECT *FROM #tempResult WHERE type=3 and  MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
),data2 AS
(
SELECT *FROM #tempResult WHERE type=33 and  MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
)
SELECT @html=@html+N''
+ISNULL(CAST((SELECT td='原材料','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.UnLackPurchaseCount,0)+ISNULL(a.UnLackMakeCount,0),'',td=ISNULL(a.LackPurchaseCount,0)+ISNULL(a.LackMakeCount,0),''
,td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0)
,'',td='','',td='','',td='','',td='','',td=ISNULL(b.Rate,'')
FROM data1 a FULL JOIN data2 b ON a.Operator=b.Operator AND a.MRPCode=b.MRPCode
ORDER BY a.Type,CASE WHEN a.MRPCode='MRP104'THEN 1
WHEN a.MRPCode='MRP106' THEN 2 
WHEN a.MRPCode='MRP105' THEN 3
WHEN a.MRPCode='MRP113' THEN 4 ELSE 5 END   FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')


;WITH data1 AS
(
SELECT *FROM #tempResult WHERE type=3 and  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107','MRP117','MRP115','MRP116','MRP119') 
),
data2 AS
(
SELECT * FROM #tempResult WHERE type=33 and  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107','MRP117','MRP115','MRP116','MRP119') 
)
SELECT @html=@html+N''
+ISNULL(CAST((SELECT td='产成品','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.UnLackPurchaseCount,0)+ISNULL(a.UnLackMakeCount,0),'',td=ISNULL(a.LackPurchaseCount,0)+ISNULL(a.LackMakeCount,0),''
,td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0),''
,'',td=ISNULL(c.PurKit,''),'',td=ISNULL(ABS(c.PurKitNot),''),'',td=ISNULL(c.MakeKit,''),'',td=ISNULL(ABS(c.MakeKitNot),'')
,'',td=ISNULL(b.Rate,'')
FROM data1 a FULL JOIN data2 b ON a.Operator=b.Operator AND  a.MRPCode=b.MRPCode
LEFT JOIN #tempKit c ON b.MRPCode=c.MRPCode AND c.type=333
ORDER BY a.Type,a.Operator DESC,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')+N'</table><br/>'




--7天工单齐套率
DECLARE @totalMOFullSetRate7 VARCHAR(20)
DECLARE @totalMONum7 INT
DECLARE @totalUnMoNum7 INT
SELECT @totalMONum7=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date7 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
SELECT @totalUnMoNum7=COUNT(DISTINCT a.DocNo) FROM #tempTable a
WHERE ( a.IsLack='缺料') AND  a.ActualReqDate<@Date7 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
SELECT @totalMOFullSetRate7=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum7-@totalUnMoNum7)/CONVERT(DECIMAL(18,4),@totalMONum7)*100))+'%'



DECLARE @shichanRate7 VARCHAR(20)
DECLARE @shichan7 INT
DECLARE @shichanUn7 INT
SELECT @shichan7=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0
SELECT @shichanUn7=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0

SELECT @shichanRate7=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@shichan7-@shichanUn7)/CONVERT(DECIMAL(18,4),@shichan7)*100))+'%'



DECLARE @fxRate7 VARCHAR(20)
DECLARE @fx7 INT
DECLARE @fxUn7 INT
SELECT @fx7=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0
SELECT @fxUn7=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0

SELECT @fxRate7=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@fx7-@fxUn7)/CONVERT(DECIMAL(18,4),@fx7)*100))+'%'



--功放7x天工单齐套率
DECLARE @totalMOFullSetRate1007 VARCHAR(20)
DECLARE @totalMONum1007 INT
DECLARE @totalUnMoNum1007 INT
SELECT @totalMONum1007=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date7 AND a.ProductLine='功放' AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)=0 AND PATINDEX('%返修%',a.DocType)=0 
SELECT @totalUnMoNum1007=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date7 AND a.ProductLine='功放' AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)=0 AND PATINDEX('%返修%',a.DocType)=0 

--对讲机7x天工单齐套率 --对讲机的工单数=总工单数-功放工单数
DECLARE @totalMOFullSetRate2007 VARCHAR(20)
DECLARE @totalMONum2007 INT=@totalMONum7-@totalMONum1007-ISNULL(@shichan7,0)-ISNULL(@fx7,0)
DECLARE @totalUnMoNum2007 INT=@totalUnMoNum7-@totalUnMoNum1007-ISNULL(@shichanUn7,0)-ISNULL(@fxUn7,0)
SELECT @totalMOFullSetRate2007=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum2007-@totalUnMoNum2007)/CONVERT(DECIMAL(18,4),@totalMONum2007)*100))+'%'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">七天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum7-@totalUnMoNum7))+'/'+CONVERT(VARCHAR(30),@totalMONum7)+'='+@totalMOFullSetRate7+'</h2>'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">对讲机7天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum2007-@totalUnMoNum2007))+'/'+CONVERT(VARCHAR(30),@totalMONum2007)+'='+@totalMOFullSetRate2007+'</h2>'
IF @totalMONum1007<>0
BEGIN
	SELECT @totalMOFullSetRate1007=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum1007-@totalUnMoNum1007)/CONVERT(DECIMAL(18,4),@totalMONum1007)*100))+'%'
	SET @html=@html+N'<h2 style="color:red;font-weight:bold;">功放7天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum1007-@totalUnMoNum1007))+'/'+CONVERT(VARCHAR(30),@totalMONum1007)+'='+@totalMOFullSetRate1007+'</h2>'
END 
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">试产7天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@shichan7-@shichanUn7))+'/'+CONVERT(VARCHAR(30),@shichan7)+'='+@shichanRate7+'</h2>'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">返修7天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@fx7-@fxUn7))+'/'+CONVERT(VARCHAR(30),@fx7)+'='+@fxRate7+'</h2>'


;
WITH data1 AS
(
SELECT * FROM #tempResult WHERE type=7 AND  MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
),data2 AS
(
SELECT * FROM #tempResult WHERE type=77 AND  MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
)
SELECT @html=@html+N'<H2 bgcolor="#7CFC00">7天齐套率(齐套的料号/总的料号数量)</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#cae7fc"><th nowrap="nowrap" rowspan="2">类别</th><th nowrap="nowrap" rowspan="2">负责人</th>
<th nowrap="nowrap" rowspan="2">MRP分类</th>
<th nowrap="nowrap" colspan="4">物料</th>
<th nowrap="nowrap" colspan="7">工单</th>
</tr>'+
'<tr bgcolor="#cae7fc">
<th nowrap="nowrap">物料数量</th><th nowrap="nowrap">齐套物料数</th><th nowrap="nowrap">不齐套物料数</th>
<th nowrap="nowrap">料号齐套率</th><th nowrap="nowrap">工单总数</th><th nowrap="nowrap">齐套工单数</th>
<th nowrap="nowrap">齐套外购件数</th><th nowrap="nowrap">不齐套外购件数</th>
<th nowrap="nowrap">齐套自制件数</th><th nowrap="nowrap">不齐套自制件数</th>
<th nowrap="nowrap">工单齐套率</th>
</tr>'
+ISNULL(CAST((SELECT td='原材料','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.UnLackPurchaseCount,0)+ISNULL(a.UnLackMakeCount,0),'',td=ISNULL(a.LackPurchaseCount,0)+ISNULL(a.LackMakeCount,0),''
,td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0)
,'',td='','',td='','',td='','',td='','',td=ISNULL(b.Rate,'')
FROM data1 a full JOIN data2 b ON a.Operator=b.Operator AND a.MRPCode=b.MRPCode
--WHERE a.type=7 AND a.MRPCode IN ('MRP104','MRP105','MRP106','MRP113')
ORDER BY a.Type,CASE WHEN a.MRPCode='MRP104'THEN 1
WHEN a.MRPCode='MRP106' THEN 2 
WHEN a.MRPCode='MRP105' THEN 3
WHEN a.MRPCode='MRP113' THEN 4 ELSE 5 END   FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')

;
WITH data1 AS
(
SELECT * FROM #tempResult WHERE type=7 AND  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107','MRP117','MRP115','MRP116','MRP119')
),data2 AS
(
SELECT * FROM #tempResult WHERE type=77 AND  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107','MRP117','MRP115','MRP116','MRP119')
)
SELECT @html=@html+N''
+ISNULL(CAST((SELECT td='产成品','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.UnLackPurchaseCount,0)+ISNULL(a.UnLackMakeCount,0),'',td=ISNULL(a.LackPurchaseCount,0)+ISNULL(a.LackMakeCount,0),''
,td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0),''
,'',td=ISNULL(c.PurKit,''),'',td=ISNULL(ABS(c.PurKitNot),''),'',td=ISNULL(c.MakeKit,''),'',td=ISNULL(ABS(c.MakeKitNot),'')
,'',td=ISNULL(b.Rate,'')
FROM data1 a FULL JOIN data2 b ON a.Operator=b.Operator AND  a.MRPCode=b.MRPCode
LEFT JOIN #tempKit c ON b.MRPCode=c.MRPCode AND c.type=777
ORDER BY  a.Type,a.Operator DESC,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')+N'</table><br/>'



--15天工单齐套率
DECLARE @totalMOFullSetRate15 VARCHAR(20)
DECLARE @totalMONum15 INT
DECLARE @totalUnMoNum15 INT
SELECT @totalMONum15=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date15 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工') AND a.DocNo<>'安全库存'
SELECT @totalUnMoNum15=COUNT(DISTINCT a.DocNo) FROM #tempTable a
WHERE ( a.IsLack='缺料')  AND a.ActualReqDate<@Date15 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
SELECT @totalMOFullSetRate15=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum15-@totalUnMoNum15)/CONVERT(DECIMAL(18,4),@totalMONum15)*100))+'%'



DECLARE @shichanRate15 VARCHAR(20)
DECLARE @shichan15 INT
DECLARE @shichanUn15 INT
SELECT @shichan15=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0
SELECT @shichanUn15=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0

SELECT @shichanRate15=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@shichan15-@shichanUn15)/CONVERT(DECIMAL(18,4),@shichan15)*100))+'%'



DECLARE @fxRate15 VARCHAR(20)
DECLARE @fx15 INT
DECLARE @fxUn15 INT
SELECT @fx15=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0
SELECT @fxUn15=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0

SELECT @fxRate15=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@fx15-@fxUn15)/CONVERT(DECIMAL(18,4),@fx15)*100))+'%'


--功放15x天工单齐套率
DECLARE @totalMOFullSetRate10015 VARCHAR(20)
DECLARE @totalMONum10015 INT
DECLARE @totalUnMoNum10015 INT
SELECT @totalMONum10015=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date15 AND a.ProductLine='功放' AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)=0 AND PATINDEX('%返修%',a.DocType)=0 
SELECT @totalUnMoNum10015=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE  (a.IsLack='缺料') AND a.ActualReqDate<@Date15 AND a.ProductLine='功放' AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)=0 AND PATINDEX('%返修%',a.DocType)=0 

--对讲机15x天工单齐套率 --对讲机的工单数=总工单数-功放工单数
DECLARE @totalMOFullSetRate20015 VARCHAR(20)
DECLARE @totalMONum20015 INT=@totalMONum15-@totalMONum10015-ISNULL(@shichan15,0)-ISNULL(@fx15,0)
DECLARE @totalUnMoNum20015 INT=@totalUnMoNum15-@totalUnMoNum10015-ISNULL(@shichanUn15,0)-ISNULL(@fxUn15,0)
SELECT @totalMOFullSetRate20015=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum20015-@totalUnMoNum20015)/CONVERT(DECIMAL(18,4),@totalMONum20015)*100))+'%'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">14天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum15-@totalUnMoNum15))+'/'+CONVERT(VARCHAR(30),@totalMONum15)+'='+@totalMOFullSetRate15+'</h2>'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">对讲机14天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum20015-@totalUnMoNum20015))+'/'+CONVERT(VARCHAR(30),@totalMONum20015)+'='+@totalMOFullSetRate20015+'</h2>'
IF @totalmonum10015<>0
BEGIN
	SELECT @totalMOFullSetRate10015=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum10015-@totalUnMoNum10015)/CONVERT(DECIMAL(18,4),@totalMONum10015)*100))+'%'
	SET @html=@html+N'<h2 style="color:red;font-weight:bold;">功放14天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum10015-@totalUnMoNum10015))+'/'+CONVERT(VARCHAR(30),@totalMONum10015)+'='+@totalMOFullSetRate10015+'</h2>'
END 
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">试产14天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@shichan15-@shichanUn15))+'/'+CONVERT(VARCHAR(30),@shichan15)+'='+@shichanRate15+'</h2>'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">返修14天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@fx15-@fxUn15))+'/'+CONVERT(VARCHAR(30),@fx15)+'='+@fxRate15+'</h2>'

--采购14天齐套率=包材、配件3天+电子、结构14天
;
WITH data1 AS
(
SELECT a.DocNo,a.IsLack FROM #tempTable a WHERE a.ActualReqDate<@Date15
AND a.MRPCode IN ('MRP104','MRP106')
UNION ALL
SELECT a.DocNo,a.IsLack FROM #tempTable a WHERE a.ActualReqDate<@Date3
AND a.MRPCode IN ('MRP105','MRP113')
),
TotalCount as
(
SELECT COUNT(DISTINCT a.docno)Total FROM data1 a
),
LackCount AS
(
SELECT COUNT(DISTINCT a.docNo)lc FROM data1 a WHERE a.IsLack='缺料'
)
SELECT @html=@html+N'<h2 style="color:red;font-weight:bold;">采购14天齐套率（齐套工单/总工单数）：'+ISNULL(CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(1.00-(SELECT * FROM LackCount)/CONVERT(DECIMAL(18,4),(SELECT * FROM TotalCount a)))*100.00))+'%','')


;
WITH data1 AS
(
SELECT * FROM #tempResult WHERE type=15 AND  MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
),data2 AS
(
SELECT * FROM #tempResult WHERE type=1515 AND  MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
)
SELECT @html=@html+N'<H2 bgcolor="#7CFC00">14天齐套率(齐套的料号/总的料号数量)</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#cae7fc"><th nowrap="nowrap" rowspan="2">类别</th><th nowrap="nowrap" rowspan="2">负责人</th>
<th nowrap="nowrap" rowspan="2">MRP分类</th>
<th nowrap="nowrap" colspan="4">物料</th>
<th nowrap="nowrap" colspan="7">工单</th>
</tr>'+
'<tr bgcolor="#cae7fc">
<th nowrap="nowrap">物料数量</th><th nowrap="nowrap">齐套物料数</th><th nowrap="nowrap">不齐套物料数</th>
<th nowrap="nowrap">料号齐套率</th><th nowrap="nowrap">工单总数</th><th nowrap="nowrap">齐套工单数</th>
<th nowrap="nowrap">齐套外购件数</th><th nowrap="nowrap">不齐套外购件数</th>
<th nowrap="nowrap">齐套自制件数</th><th nowrap="nowrap">不齐套自制件数</th>
<th nowrap="nowrap">工单齐套率</th>
</tr>'
+ISNULL(CAST((SELECT td='原材料','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.UnLackPurchaseCount,0)+ISNULL(a.UnLackMakeCount,0),'',td=ISNULL(a.LackPurchaseCount,0)+ISNULL(a.LackMakeCount,0),''
,td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0)
,'',td='','',td='','',td='','',td='','',td=ISNULL(b.Rate,'')
FROM data1 a full JOIN data2 b ON a.Operator=b.Operator AND a.MRPCode=b.MRPCode
--WHERE a.type=15 AND a.MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
ORDER BY a.Type,CASE WHEN a.MRPCode='MRP104'THEN 1
WHEN a.MRPCode='MRP106' THEN 2 
WHEN a.MRPCode='MRP105' THEN 3
WHEN a.MRPCode='MRP113' THEN 4 ELSE 5 END   FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')
;
WITH data1 AS
(
SELECT * FROM #tempResult WHERE type=15 AND  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107','MRP117','MRP115','MRP116','MRP119')
),data2 AS
(
SELECT * FROM #tempResult WHERE type=1515 AND  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107','MRP117','MRP115','MRP116','MRP119')
)
SELECT @html=@html+N''
+ISNULL(CAST((SELECT td='产成品','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.UnLackPurchaseCount,0)+ISNULL(a.UnLackMakeCount,0),'',td=ISNULL(a.LackPurchaseCount,0)+ISNULL(a.LackMakeCount,0),''
,td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0),''
,'',td=ISNULL(c.PurKit,''),'',td=ISNULL(ABS(c.PurKitNot),''),'',td=ISNULL(c.MakeKit,''),'',td=ISNULL(ABS(c.MakeKitNot),'')
,'',td=ISNULL(b.Rate,'')
FROM data1 a FULL JOIN data2 b ON a.Operator=b.Operator AND  a.MRPCode=b.MRPCode
LEFT JOIN #tempKit c ON b.MRPCode=c.MRPCode AND c.type=151515
ORDER BY a.Type,a.Operator DESC,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')+N'</table><br/>'



--21天工单齐套率
DECLARE @totalMOFullSetRate21 VARCHAR(20)
DECLARE @totalMONum21 INT
DECLARE @totalUnMoNum21 INT
SELECT @totalMONum21=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date21 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
SELECT @totalUnMoNum21=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date21 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
SELECT @totalMOFullSetRate21=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum21-@totalUnMoNum21)/CONVERT(DECIMAL(18,4),@totalMONum21)*100))+'%'


DECLARE @shichanRate21 VARCHAR(20)
DECLARE @shichan21 INT
DECLARE @shichanUn21 INT
SELECT @shichan21=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date21 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0
SELECT @shichanUn21=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date21 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0

SELECT @shichanRate21=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@shichan21-@shichanUn21)/CONVERT(DECIMAL(18,4),@shichan21)*100))+'%'


DECLARE @fxRate21 VARCHAR(20)
DECLARE @fx21 INT
DECLARE @fxUn21 INT
SELECT @fx21=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date21 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0
SELECT @fxUn21=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date21 AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0

SELECT @fxRate21=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@fx21-@fxUn21)/CONVERT(DECIMAL(18,4),@fx21)*100))+'%'



--功放3x天工单齐套率
DECLARE @totalMOFullSetRate10021 VARCHAR(20)
DECLARE @totalMONum10021 INT
DECLARE @totalUnMoNum10021 INT
SELECT @totalMONum10021=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date21 AND a.ProductLine='功放' AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)=0 AND PATINDEX('%返修%',a.DocType)=0 
SELECT @totalUnMoNum10021=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date21 AND a.ProductLine='功放' AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外') AND a.DocNo<>'安全库存' 
AND PATINDEX('%试产%',a.DocType)=0 AND PATINDEX('%返修%',a.DocType)=0 


--对讲机3x天工单齐套率 --对讲机的工单数=总工单数-功放工单数
DECLARE @totalMOFullSetRate20021 VARCHAR(20)
DECLARE @totalMONum20021 INT=@totalMONum21-@totalMONum10021-ISNULL(@shichan21,0)-ISNULL(@fx21,0)
DECLARE @totalUnMoNum20021 INT=@totalUnMoNum21-@totalUnMoNum10021-ISNULL(@shichanUn21,0)-ISNULL(@fxUn21,0)
SELECT @totalMOFullSetRate20021=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum20021-@totalUnMoNum20021)/CONVERT(DECIMAL(18,4),@totalMONum20021)*100))+'%'

SET @html=@html+N'<h2 style="color:red;font-weight:bold;">21天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum21-@totalUnMoNum21))+'/'+CONVERT(VARCHAR(30),@totalMONum21)+'='+@totalMOFullSetRate21+'</h2>'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">对讲机21天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum20021-@totalUnMoNum20021))+'/'+CONVERT(VARCHAR(30),@totalMONum20021)+'='+@totalMOFullSetRate20021+'</h2>'
IF @totalMONum10021<>0
BEGIN
SELECT @totalMOFullSetRate10021=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum10021-@totalUnMoNum10021)/CONVERT(DECIMAL(18,4),@totalMONum10021)*100))+'%'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">功放21天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum10021-@totalUnMoNum10021))+'/'+CONVERT(VARCHAR(30),@totalMONum10021)+'='+@totalMOFullSetRate10021+'</h2>'
END 
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">试产21天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@shichan21-@shichanUn21))+'/'+CONVERT(VARCHAR(30),@shichan21)+'='+@shichanRate21+'</h2>'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">返修21天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@fx21-@fxUn21))+'/'+CONVERT(VARCHAR(30),@fx21)+'='+@fxRate21+'</h2>'



;WITH data1 AS
(
SELECT *FROM #tempResult WHERE type=21 and  MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
),data2 AS
(
SELECT *FROM #tempResult WHERE type=2121 and  MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
)
SELECT @html=@html+N'<H2 bgcolor="#7CFC00">21天齐套率(齐套的料号/总的料号数量)</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#cae7fc"><th nowrap="nowrap" rowspan="2">类别</th><th nowrap="nowrap" rowspan="2">负责人</th>
<th nowrap="nowrap" rowspan="2">MRP分类</th>
<th nowrap="nowrap" colspan="4">物料</th>
<th nowrap="nowrap" colspan="7">工单</th>
</tr>'+
'<tr bgcolor="#cae7fc">
<th nowrap="nowrap">物料数量</th><th nowrap="nowrap">齐套物料数</th><th nowrap="nowrap">不齐套物料数</th>
<th nowrap="nowrap">料号齐套率</th><th nowrap="nowrap">工单总数</th><th nowrap="nowrap">齐套工单数</th>
<th nowrap="nowrap">齐套外购件数</th><th nowrap="nowrap">不齐套外购件数</th>
<th nowrap="nowrap">齐套自制件数</th><th nowrap="nowrap">不齐套自制件数</th>
<th nowrap="nowrap">工单齐套率</th>
</tr>'
+ISNULL(CAST((SELECT td='原材料','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.UnLackPurchaseCount,0)+ISNULL(a.UnLackMakeCount,0),'',td=ISNULL(a.LackPurchaseCount,0)+ISNULL(a.LackMakeCount,0),''
,td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0)
,'',td='','',td='','',td='','',td='','',td=ISNULL(b.Rate,'')
FROM data1 a FULL JOIN data2 b ON a.Operator=b.Operator AND a.MRPCode=b.MRPCode
ORDER BY a.Type,CASE WHEN a.MRPCode='MRP104'THEN 1
WHEN a.MRPCode='MRP106' THEN 2 
WHEN a.MRPCode='MRP105' THEN 3
WHEN a.MRPCode='MRP113' THEN 4 ELSE 5 END   FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')



;WITH data1 AS
(
SELECT *FROM #tempResult WHERE type=21 and  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107','MRP117','MRP115','MRP116','MRP119') 
),
data2 AS
(
SELECT * FROM #tempResult WHERE type=2121 and  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107','MRP117','MRP115','MRP116','MRP119') 
)
SELECT @html=@html+N''
+ISNULL(CAST((SELECT td='产成品','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.UnLackPurchaseCount,0)+ISNULL(a.UnLackMakeCount,0),'',td=ISNULL(a.LackPurchaseCount,0)+ISNULL(a.LackMakeCount,0),''
,td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0),''
,'',td=ISNULL(c.PurKit,''),'',td=ISNULL(ABS(c.PurKitNot),''),'',td=ISNULL(c.MakeKit,''),'',td=ISNULL(ABS(c.MakeKitNot),'')
,'',td=ISNULL(b.Rate,'')
FROM data1 a FULL JOIN data2 b ON a.Operator=b.Operator AND  a.MRPCode=b.MRPCode
LEFT JOIN #tempKit c ON b.MRPCode=c.MRPCode AND c.type=212121
ORDER BY a.Type,a.Operator DESC,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')+N'</table><br/>'







SELECT @html=@html+N'<H2 bgcolor="#7CFC00">马来14天齐套率(齐套的料号/总的料号数量)</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#cae7fc"><th nowrap="nowrap">类别</th><th nowrap="nowrap">负责人</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">物料数量</th><th nowrap="nowrap">未齐套物料数</th>
<th nowrap="nowrap">齐套物料数</th><th nowrap="nowrap">齐套率</th></tr>'
+ISNULL(CAST((SELECT td='原材料','',td=ISNULL(a.Operator,''),'',td=a.MRPCategory,''
,td=a.totalCount,'',td=a.LackCount,'',td=a.UnLackCount,'',td=a.Rate
FROM #tempResult a 
WHERE a.type=152 AND a.MRPCode IN ('MRP104','MRP105','MRP106','MRP113')
ORDER BY a.Type,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')
--
SELECT @html=@html+N''
+ISNULL(CAST((SELECT td='产成品','', td=ISNULL(a.Operator,''),'',td=a.MRPCategory,''
,td=a.totalCount,'',td=a.LackCount,'',td=a.UnLackCount,'',td=a.Rate
FROM #tempResult a 
WHERE a.type=152 AND a.MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107','MRP117','MRP115','MRP116','MRP119')
ORDER BY a.Type,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')
SET @html=@html+N'</table><br/>'




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
WHERE CONVERT(DATE,CopyDate)=CONVERT(DATE,@Date)
AND (PATINDEX('SO%',DocNo)>0 OR  PATINDEX('FO%',DocNo)>0)


--工单的实际需求时间=实际需求时间-原材料采购后处理期
--委外WPO实际需求时间=实际需求时间-采购组件采购前处理提前期-原材料采购后处理期
UPDATE #tempTable 
SET ActualReqDate=CASE WHEN #tempTable.DocNo LIKE'WPO%' THEN  DATEADD(DAY,(ISNULL(a.PurBackwardProcessLT,0)+ISNULL(b.PurForwardProcessLT,0))*(-1),ActualReqDate)
ELSE DATEADD(DAY,(ISNULL(a.PurBackwardProcessLT,0))*(-1),ActualReqDate) END 
FROM CBO_MrpInfo a,dbo.CBO_MrpInfo b WHERE a.ItemMaster=#tempTable.ItemMaster AND b.ItemMaster=#tempTable.ProductID
AND PATINDEX('SO%',#tempTable.DocNo)=0
AND PATINDEX('FO%',#tempTable.DocNo)=0


--安全库存欠交数量
;
WITH data1 AS
(
SELECT a.Code,MIN(a.SafetyStockQty)SafetyStockQty,MAX(a.RN)RN,MIN(a.WhavailiableAmount)WhavailiableAmount FROM #tempTable a
WHERE --a.ActualReqDate<@SD1  AND 
a.SafetyStockQty>0
GROUP BY a.Code
)
SELECT a.Code
,a.SafetyStockQty SafeQtyLack INTO #tempLackSafe
FROM data1 a
--SELECT a.Code
--,CASE WHEN a.WhavailiableAmount<0 THEN a.SafetyStockQty
--WHEN a.WhavailiableAmount>a.SafetyStockQty THEN 0
--ELSE a.SafetyStockQty-a.WhavailiableAmount END SafeQtyLack INTO #tempLackSafe
--FROM data1 a

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
SELECT code,MAX(a.WhavailiableAmount+a.ReqQty)WhQty,min(a.WhAvailiableAmount)WhAvailiableAmount,MIN(a.SafetyStockQty)SafetyStockQty
FROM #tempTable a  
GROUP BY a.Code 
)
SELECT a.*,b.WhQty,b.WhAvailiableAmount,b.SafetyStockQty 
INTO #tempW8 
FROM data2  a LEFT JOIN data3 b ON a.Code=b.Code

--新逻辑
BEGIN
DECLARE @Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='300')
--采购未交数据集合
IF OBJECT_ID(N'tempdb.dbo.#tempDeficiency',N'U') IS NULL
CREATE TABLE #tempDeficiency
(
Code VARCHAR(50),
DeficiencyQty INT,
RemainQty INT,--供应工单后采购订单剩余数量
Duration VARCHAR(10),
RN int
)
ELSE
BEGIN
TRUNCATE TABLE #tempDeficiency
END	

--8周交货计划汇总
IF OBJECT_ID(N'tempdb.dbo.#tempSend',N'U') IS NULL
BEGIN
	CREATE TABLE #tempSend
	(Code VARCHAR(50)
	,Name NVARCHAR(255)
	,SPECS NVARCHAR(300)
	,w0 INT,w1 INT,w2 INT,w3 INT, w4 INT ,w5 INT ,w6 INT,w7 INT ,w8 INT
	,w02 INT,w12 INT,w22 INT,w32 INT, w42 INT ,w52 INT ,w62 INT,w72 INT ,w82 INT
	,Total INT--8周欠料汇总
	,MRPCategory VARCHAR(50)
	,RN INT--按供应商排序 
	)
END
ELSE
BEGIN
	TRUNCATE TABLE #tempSend
END

--查询所有未交供应商信息
;WITH ReturnedData AS--在检收货单集合
(
SELECT 
b.SrcDoc_SrcDocNo,b.SrcDoc_SrcDocLineNo,b.SrcDoc_SrcDocSubLineNo
,b.ItemInfo_ItemCode,SUM(ISNULL(b.RtnFillQtyTU,0))TotalReturnedQty
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement  LEFT JOIN dbo.CBO_Supplier_Trl s1 ON a.Supplier_Supplier=s1.ID
WHERE a.Org=1001708020135665
AND a.Status IN (4,5) AND b.Status IN (4,5)
AND a.ReceivementType=1
GROUP BY  b.SrcDoc_SrcDocNo,b.SrcDoc_SrcDocLineNo,b.SrcDoc_SrcDocSubLineNo,b.ItemInfo_ItemCode
),
RcvedData AS
(
SELECT
b.SrcDoc_SrcDocNo,b.SrcDoc_SrcDocLineNo,b.SrcDoc_SrcDocSubLineNo
,b.ItemInfo_ItemCode,SUM(b.RcvQtyTU-ISNULL(c.TotalReturnedQty,0))TotalRcvQty
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement 
LEFT JOIN ReturnedData c ON a.DocNo=c.SrcDoc_SrcDocNo AND b.DocLineNo=c.SrcDoc_SrcDocLineNo
WHERE a.Org=1001708020135665
AND a.Status IN (4,5) AND b.Status IN (4,5)
AND a.ReceivementType=0
GROUP BY  b.SrcDoc_SrcDocNo,b.SrcDoc_SrcDocLineNo,b.SrcDoc_SrcDocSubLineNo,b.ItemInfo_ItemCode
),
data1 AS
(
SELECT 
s.ID Supplier,a.DocNo,b.DocLineNo,c.SubLineNo,b.ItemInfo_ItemCode
,c.SupplierConfirmQtyTU
,c.SupplierConfirmQtyTU-ISNULL(r.TotalRcvQty,0)DeficiencyQtyTU
,c.PlanArriveDate
,ROW_NUMBER()OVER(ORDER BY c.PlanArriveDate)RN--按计划到货日期排序
,CASE WHEN c.PlanArriveDate <@SD1  THEN 'w0'
WHEN c.PlanArriveDate>=@SD1 AND c.PlanArriveDate<@ED1 THEN 'w1'
WHEN c.PlanArriveDate>=DATEADD(DAY,7,@SD1) AND c.PlanArriveDate<DATEADD(DAY,7,@ED1) 
THEN 'w2'
WHEN c.PlanArriveDate>=DATEADD(DAY,14,@SD1) AND c.PlanArriveDate<DATEADD(DAY,14,@ED1) 
THEN 'w3'
WHEN c.PlanArriveDate>=DATEADD(DAY,21,@SD1) AND c.PlanArriveDate<DATEADD(DAY,21,@ED1) 
THEN 'w4'
WHEN c.PlanArriveDate>=DATEADD(DAY,28,@SD1) AND c.PlanArriveDate<DATEADD(DAY,28,@ED1) 
THEN 'w5'
WHEN c.PlanArriveDate>=DATEADD(DAY,35,@SD1) AND c.PlanArriveDate<DATEADD(DAY,35,@ED1) 
THEN 'w6'
WHEN c.PlanArriveDate>=DATEADD(DAY,42,@SD1) AND c.PlanArriveDate<DATEADD(DAY,42,@ED1) 
THEN 'w7'
WHEN c.PlanArriveDate>=DATEADD(DAY,49,@SD1) AND c.PlanArriveDate<DATEADD(DAY,49,@ED1) 
THEN 'w8'
ELSE '' END Duration
--,s.DescFlexField_PrivateDescSeg3
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
INNER JOIN dbo.CBO_ItemMaster m ON c.ItemInfo_ItemID=m.ID
LEFT JOIN RcvedData r ON a.DocNo=r.SrcDoc_SrcDocNo AND b.DocLineNo=r.SrcDoc_SrcDocLineNo AND c.SubLineNo=r.SrcDoc_SrcDocSubLineNo
LEFT JOIN dbo.CBO_Supplier s ON a.Supplier_Supplier=s.ID LEFT JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND ISNULL(s1.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.Org=1001708020135665 AND a.Status=2 AND b.Status=2 AND c.DeficiencyQtyTU>0
AND a.Cancel_Canceled=0--非终止状态订单
AND c.PlanArriveDate<DATEADD(DAY,49,@ED1)
)
INSERT INTO #tempDeficiency
SELECT a.ItemInfo_ItemCode,SUM(a.DeficiencyQtyTU)DeficiencyQtyTU,SUM(a.DeficiencyQtyTU)RemainQty,a.Duration
,ROW_NUMBER()OVER(ORDER BY a.ItemInfo_ItemCode,a.Duration)RN
FROM data1 a
WHERE a.DeficiencyQtyTU>0
GROUP BY a.ItemInfo_ItemCode,a.Duration

IF OBJECT_ID(N'tempdb.dbo.#tempSupResult',N'U') IS NULL
BEGIN
CREATE TABLE #tempSupResult(Code VARCHAR(50),Qty INT,Duration VARCHAR(4),IsSupMO bit)
END
ELSE
BEGIN
TRUNCATE TABLE #tempSupResult
END

--计算供应商交料计划
DECLARE @RN INT
DECLARE @code VARCHAR(50),@w0 int,@w1 int ,@w2 int ,@w3 INT,@w4 INT,@w5 int,@w6 int ,@w7 int ,@w8 int 
DECLARE @code2 VARCHAR(50),@Qty decimal(18,4),@Duration varchar(4)
DECLARE curSup CURSOR
FOR
--库存在这里算了
SELECT Code,w0,ISNULL(w1,0)-ISNULL(SafetyStockQty,0),w2,w3,w4,w5,w6,w7,w8 FROM #tempW8 WHERE whAvailiableAmount-ISNULL(SafetyStockQty,0)<0 --获取有欠料的料号
OPEN curSup
FETCH NEXT FROM curSup INTO @code,@w0,@w1,@w2,@w3,@w4,@w5,@w6,@w7,@w8
WHILE @@fetch_status=0
BEGIN
	DECLARE @tempLackQty INT=ISNULL(@w0,0)*(-1)--欠料数量
	,@tempWeek VARCHAR(4)='w0'--欠料周
	DECLARE curDeficiency CURSOR
    FOR
	SELECT Code,DeficiencyQty,RN FROM #tempDeficiency WHERE Code=@code ORDER BY RN	--按计划到货日期排序
	OPEN curDeficiency
	FETCH NEXT FROM curDeficiency INTO @code2,@Qty,@RN
	WHILE	@@FETCH_STATUS=0
	BEGIN
		DECLARE @QtyData INT--交料数量
		--当供应商未交数量能够满足当前欠料，未交数量尾数移到一下周继续计算。
		--例如：第一周欠交100，供应商采购行未交数量为1000，则多出的900未交移到第二周继续计算。
		WHILE @Qty>0
		BEGIN
			WHILE ISNULL(@tempLackQty,0)=0--当本周欠料数量=0，取下周欠料数量
			BEGIN 
				SET @tempWeek= CASE WHEN @tempWeek='w0' THEN  'w1' 
									WHEN @tempWeek='w1' THEN  'w2' 
									WHEN @tempWeek='w2' THEN  'w3' 
									WHEN @tempWeek='w3' THEN  'w4' 
									WHEN @tempWeek='w4' THEN  'w5' 
									WHEN @tempWeek='w5' THEN  'w6' 
									WHEN @tempWeek='w6' THEN  'w7' 
									WHEN @tempWeek='w7' THEN  'w8' 
									ELSE '' END 
				SET @tempLackQty=CASE 	WHEN @tempWeek='w1' THEN  ISNULL(@w1,0)*(-1) 
										WHEN @tempWeek='w2' THEN  ISNULL(@w2,0)*(-1)
										WHEN @tempWeek='w3' THEN  ISNULL(@w3,0)*(-1)
										WHEN @tempWeek='w4' THEN  ISNULL(@w4,0)*(-1)
										WHEN @tempWeek='w5' THEN  ISNULL(@w5,0)*(-1)
										WHEN @tempWeek='w6' THEN  ISNULL(@w6,0)*(-1)
										WHEN @tempWeek='w7' THEN  ISNULL(@w7,0)*(-1)
										WHEN @tempWeek='w8' THEN  ISNULL(@w8,0)*(-1)
										ELSE 0 END 
				IF ISNULL(@tempWeek,'')=''--如果超过8周了，退出循环
				break;
			END 
			IF ISNULL(@tempWeek,'')=''
			break;--如果超过8周了，退出循环
			IF @Qty<=@tempLackQty--供应商未交数量<=当周欠交数量
			BEGIN
				SET @QtyData=@Qty
				SET @tempLackQty=@tempLackQty-@Qty
				SET @Qty=0
			END 
			ELSE--供应商未交数量>当周欠交数量
            BEGIN
				SET @QtyData=@tempLackQty
				SET @Qty=@Qty-@tempLackQty
				SET @tempLackQty=0
			END 

			UPDATE #tempDeficiency SET RemainQty=@Qty WHERE RN=@RN

			--插入供应商交货计划
			INSERT INTO #tempSupResult
				        ( Code, Qty, Duration,IsSupMO )
				VALUES  ( @code2, -- Code - varchar(50)
				          @QtyData, -- Qty - decimal(18, 4)
				          @tempWeek , -- Duration - varchar(4)
						  1
				          )
						
		END          		       

		FETCH NEXT FROM curDeficiency INTO @code2,@Qty,@RN
	END 
	CLOSE curDeficiency
	DEALLOCATE curDeficiency--关闭curDeficiency游标    
	FETCH NEXT FROM curSup INTO @code,@w0,@w1,@w2,@w3,@w4,@w5,@w6,@w7,@w8
END 
CLOSE curSup
DEALLOCATE curSup--关闭curSup游标    


INSERT INTO #tempSupResult
        (  Code, Qty, Duration,IsSupMO )
SELECT Code,RemainQty,CASE WHEN Duration='w0'  THEN 'w5'
WHEN Duration='w1'  THEN 'w5'
WHEN Duration='w2'  THEN 'w5'
WHEN Duration='w3'  THEN 'w5'
ELSE Duration END ,0
FROM #tempDeficiency WHERE RemainQty>0


END 
--End 新逻辑
BEGIN
	;
	WITH SupMO AS--根据供应商交货计划，“周”行专列，按周汇总
	(
	SELECT * FROM (SELECT * FROM #tempSupResult  a WHERE a.IsSupMO=1) a
	PIVOT(SUM(a.Qty) FOR duration IN ([w0],[w1],[w2],[w3],[w4],[w5],[w6],[w7],[w8])) AS t
	),
	NotSupMO AS
	(
	SELECT * FROM (SELECT * FROM #tempSupResult  a WHERE a.IsSupMO=0) a
	PIVOT(SUM(a.Qty) FOR duration IN ([w0],[w1],[w2],[w3],[w4],[w5],[w6],[w7],[w8])) AS t
	),
	data1 AS
	(
	SELECT ISNULL(a.Code,b.Code)Code,a.w0,a.w1,a.w2,a.w3,a.w4,a.w5,a.w6,a.w7,a.w8 
	,b.w0 w02,b.w1 w12,b.w2 w22,b.w3 w32,b.w4 w42,b.w5 w52,b.w6 w62,b.w7 w72,b.w8 w82
	FROM SupMO a FULL JOIN NotSupMO b ON  a.Code=b.Code
	),
	data2 AS--按料号汇总每家供应商8周欠料数量
	(
	SELECT a.Code,sum(a.Qty)Total FROM #tempSupResult a GROUP BY a.Code
	)
	INSERT INTO #tempSend
	SELECT m.Code,m.Name,m.SPECS
	,r.w0,r.w1,r.w2,r.w3,r.w4,r.w5,r.w6,r.w7,r.w8
	,r.w02,r.w12,r.w22,r.w32,r.w42,r.w52,r.w62,r.w72,r.w82
	,ISNULL(r2.Total,0)Total,mrp.Name,DENSE_RANK()OVER(ORDER BY m.Code)RN 
	FROM data1 r INNER JOIN data2 r2 ON  r.Code=r2.Code  
	LEFT JOIN dbo.CBO_ItemMaster m ON r.Code=m.Code AND m.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
	LEFT JOIN dbo.vw_MRPCategory mrp ON m.DescFlexField_PrivateDescSeg22=mrp.Code
	
END	
	

;
WITH RCVData AS
(
SELECT 
b.ItemInfo_ItemCode,SUM(ISNULL(b.RcvQtyTU,0))RcvQtyTU
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement 
WHERE a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
AND a.Status IN (0,3) AND b.Status IN (0,3)
AND a.ReceivementType=0
GROUP BY b.ItemInfo_ItemCode
)
SELECT @html=@html+N'<H2 bgcolor="#7CFC00">8周未齐套单据汇总列表<span style="color:red;">（不欠料为0）</span></H2>'
+N'<table border="1">'
+N'<tr bgcolor="#cae7fc">
<th nowrap="nowrap" rowspan="3">MRP分类</th>
<th nowrap="nowrap" rowspan="3">Buyer</th>
<th nowrap="nowrap" rowspan="3">MC责任人</th>
<th nowrap="nowrap" rowspan="3">料号</th><th nowrap="nowrap" rowspan="3">品名</th>
<th nowrap="nowrap" rowspan="3">规格</th>
<th nowrap="nowrap" rowspan="3">待检数量</th>
<th nowrap="nowrap" rowspan="3">逾期欠料</th>

<th nowrap="nowrap" colspan="2">第一周</th>
<th nowrap="nowrap"  colspan="2">第二周</th>
<th nowrap="nowrap"  colspan="2">第三周</th>
<th nowrap="nowrap"  colspan="2">第四周</th>
<th nowrap="nowrap"  colspan="2">第五周</th>
<th nowrap="nowrap"  colspan="2">第六周</th>
<th nowrap="nowrap"  colspan="2">第七周</th>
<th nowrap="nowrap"  colspan="2">第八周</th>
<th nowrap="nowrap" rowspan="3">8周采购欠交汇总</th>
<th nowrap="nowrap" rowspan="3">生产工单欠料汇总</th>
<th nowrap="nowrap" rowspan="3">库存现有量</th>
<th nowrap="nowrap" rowspan="3">备注</th>
</tr>'
+'<tr>
<th nowrap="nowrap" colspan="2">'+RIGHT(CONVERT(VARCHAR(20),@SD1),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,@ED1)),5)+'</th>
<th nowrap="nowrap" colspan="2">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,7,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,7,@ED1))),5)+'</th>
<th nowrap="nowrap" colspan="2">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,14,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,14,@ED1))),5)+'</th>
<th nowrap="nowrap" colspan="2">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,21,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,21,@ED1))),5)+'</th>
<th nowrap="nowrap" colspan="2">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,28,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,28,@ED1))),5)+'</th>
<th nowrap="nowrap" colspan="2">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,35,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,35,@ED1))),5)+'</th>
<th nowrap="nowrap" colspan="2">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,42,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,42,@ED1))),5)+'</th>
<th nowrap="nowrap" colspan="2">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,49,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,49,@ED1))),5)+'</th></tr>'
+'<tr>
<th nowrap="nowrap" >安全库存欠料</th>
<th nowrap="nowrap" >计划交货数量</th>
<th nowrap="nowrap" colspan="2">计划交货数量</th>
<th nowrap="nowrap" colspan="2">计划交货数量</th>
<th nowrap="nowrap">计划交货数量</th>
<th nowrap="nowrap">预测交货数量</th>
<th nowrap="nowrap">计划交货数量</th>
<th nowrap="nowrap">预测交货数量</th>
<th nowrap="nowrap">计划交货数量</th>
<th nowrap="nowrap">预测交货数量</th>
<th nowrap="nowrap">计划交货数量</th>
<th nowrap="nowrap">预测交货数量</th>
<th nowrap="nowrap">计划交货数量</th>
<th nowrap="nowrap">预测交货数量</th>
</tr>'
+CAST(( SELECT td=ISNULL(a1.MRPCategory,''),'',td=ISNULL(op1.Name,''),''
,td=ISNULL(op21.Name,''),'',td=a1.Code,'',td=a1.Name,'',td=a1.SPECS,''
,td=CONVERT(DECIMAL(18,0),ISNULL(c.RcvQtyTU,0)),''
,td=ISNULL(a1.w0,0) ,''
,td=CASE WHEN ISNULL(a1.w1,0)<=ISNULL(b.SafeQtyLack,0) THEN ISNULL(a1.w1,0) ELSE ISNULL(b.SafeQtyLack,0) END ,''
,CASE WHEN ISNULL(a1.w1,0)<=ISNULL(b.safeqtylack,0) THEN 0 ELSE ISNULL(a1.w1,0)-ISNULL(b.safeqtylack,0)END  w1data,''
,ISNULL(a1.w2,0) w2data ,''
,ISNULL(a1.w3,0) w3data ,''
,td=ISNULL(a1.w4,0) ,''
,td=ISNULL(a1.w42,0) ,''
,td=ISNULL(a1.w5,0) ,''
,td=ISNULL(a1.w52,0) ,''
,td=ISNULL(a1.w6,0) ,''
,td=ISNULL(a1.w62,0) ,''
,td=ISNULL(a1.w7,0) ,''
,td=ISNULL(a1.w72,0) ,''
,td=ISNULL(a1.w8,0) ,''
,td=ISNULL(a1.w82,0) ,''
,td=ISNULL(a1.Total,0),''
,td=CASE WHEN ISNULL((a.WhAvailiableAmount-ISNULL(b.SafeQtyLack,0))*(-1),0)>0 THEN ISNULL((a.WhAvailiableAmount-ISNULL(b.SafeQtyLack,0))*(-1),0) ELSE 0 END ,''
,td=ISNULL(a.WhQty,0),''
,td=CASE WHEN a1.MRPCategory='客供料' THEN a1.MRPCategory
WHEN (SELECT COUNT(1) FROM #tempTable WHERE WhavailiableAmount<0 AND code=a1.Code AND DocNo LIKE 'SO%')>0 THEN '销售需求：'+CONVERT(VARCHAR(100),(SELECT SUM(ReqQty) FROM #tempTable WHERE WhavailiableAmount<0 AND code=a1.Code AND DocNo LIKE 'SO%'))
WHEN ISNULL((a.WhAvailiableAmount-ISNULL(b.SafeQtyLack,0))*(-1),0)>ISNULL(a1.Total,0) THEN '工单欠料'+CONVERT(VARCHAR(100),ISNULL((a.WhAvailiableAmount-ISNULL(b.SafeQtyLack,0))*(-1),0)-ISNULL(a1.Total,0))+'没有采购未交订单'
ELSE '' END 
FROM #tempSend a1 LEFT JOIN  #tempW8 a  ON a1.Code=a.Code
LEFT JOIN #tempLackSafe b ON a1.Code=b.code
LEFT JOIN dbo.CBO_ItemMaster m ON a1.Code=m.Code AND m.Org=1001708020135665
LEFT JOIN dbo.CBO_Operators op ON m.DescFlexField_PrivateDescSeg23=op.Code AND op.Org=m.Org LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.ID
LEFT JOIN dbo.CBO_Operators op2 ON m.DescFlexField_PrivateDescSeg24=op2.Code AND op2.Org=m.Org LEFT JOIN dbo.CBO_Operators_Trl op21 ON op2.ID=op21.ID
LEFT JOIN RCVData c ON a1.Code=c.ItemInfo_ItemCode
ORDER BY ISNULL(a1.w0,0) desc,ISNULL(a1.w1,0)desc,ISNULL(a1.w2,0)desc,ISNULL(a1.w3,0)DESC
,ISNULL(a1.w4,0)desc,ISNULL(a1.w5,0)desc,ISNULL(a1.w6,0)desc,ISNULL(a1.w7,0)desc,ISNULL(a1.w8,0)desc,a1.code
FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))

+replace (CAST(( SELECT td=ISNULL(a.MRPCategory,''),'',td=ISNULL(a.Buyer,''),''
,td=ISNULL(a.MCName,''),'',td=a.Code,'',td=a.Name,'',td=a.SPEC,''
,td=CONVERT(DECIMAL(18,0),ISNULL(c.RcvQtyTU,0)),''
,td=CASE WHEN ISNULL(a.w0,0)>0 THEN 0 ELSE ISNULL(a.w0,0)*(-1) END ,''
,td=ISNULL(b.SafeQtyLack,0),''
,CASE WHEN ISNULL(a.w1,0)>0 THEN 0 ELSE ISNULL(a.w1,0)*(-1) END w1data ,''
,CASE WHEN ISNULL(a.w2,0)>0 THEN 0 ELSE ISNULL(a.w2,0)*(-1) END w2data,''
,CASE WHEN ISNULL(a.w3,0)>0 THEN 0 ELSE ISNULL(a.w3,0)*(-1) END w3data,''
,td=CASE WHEN ISNULL(a.w4,0)>0 THEN 0 ELSE ISNULL(a.w4,0)*(-1) END ,''
,td=0,''
,td=CASE WHEN ISNULL(a.w5,0)>0 THEN 0 ELSE ISNULL(a.w5,0)*(-1) END ,''
,td=0,''
,td=CASE WHEN ISNULL(a.w6,0)>0 THEN 0 ELSE ISNULL(a.w6,0)*(-1) END ,''
,td=0,''
,td=CASE WHEN ISNULL(a.w7,0)>0 THEN 0 ELSE ISNULL(a.w7,0)*(-1) END ,''
,td=0,''
,td=CASE WHEN ISNULL(a.w8,0)>0 THEN 0 ELSE ISNULL(a.w8,0)*(-1) END ,''
,td=0,''
,td=0,''
,td=ISNULL((a.WhAvailiableAmount-ISNULL(b.SafeQtyLack,0))*(-1),0),''
,td=ISNULL(a.WhQty,0),''
,td=CASE WHEN a.MRPCategory='客供料' THEN a.MRPCategory
WHEN (SELECT COUNT(1) FROM #tempTable WHERE WhavailiableAmount<0 AND code=a.Code AND DocNo LIKE 'SO%')>0 THEN '销售需求：'+CONVERT(VARCHAR(100),(SELECT SUM(ReqQty) FROM #tempTable WHERE WhavailiableAmount<0 AND code=a.Code AND DocNo LIKE 'SO%'))
WHEN ISNULL((a.WhAvailiableAmount-ISNULL(b.SafeQtyLack,0))*(-1),0)>ISNULL(a1.Total,0) THEN '工单欠料'+CONVERT(VARCHAR(100),ISNULL((a.WhAvailiableAmount-ISNULL(b.SafeQtyLack,0))*(-1),0)-ISNULL(a1.Total,0))+'没有采购未交订单'
ELSE '' END 
FROM #tempW8 a LEFT JOIN  #tempSend a1  ON a1.Code=a.Code
LEFT JOIN #tempLackSafe b ON a.Code=b.code
LEFT JOIN RCVData c ON a.Code=c.ItemInfo_ItemCode
WHERE a.WhAvailiableAmount-ISNULL(b.SafeQtyLack,0)<0
AND a1.Code IS NULL
--WHERE a1.WhAvailiableAmount<0
ORDER BY ISNULL(a.w0,0)*(-1),ISNULL(a.w1,0)*(-1),ISNULL(a.w2,0)*(-1),ISNULL(a.w3,0)*(-1),ISNULL(a.w4,0)*(-1),ISNULL(a.w5,0)*(-1),ISNULL(a.w6,0)*(-1),ISNULL(a.w7,0)*(-1),ISNULL(a.w8,0)*(-1),a.code
FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'<tr>','<tr style="background-color:red;">')
+N'</table><br/>'


--马来8周汇总列表
;
WITH data1 as
(
SELECT CASE WHEN a.ActualReqDate <@SD1 AND a.DocNo<>'安全库存' THEN 'w0'
WHEN a.ActualReqDate>=@SD1 AND a.ActualReqDate<@ED1 THEN 'w1'
WHEN a.ActualReqDate>=DATEADD(DAY,7,@SD1) AND a.ActualReqDate<DATEADD(DAY,7,@ED1) THEN 'w2'
WHEN a.ActualReqDate>=DATEADD(DAY,14,@SD1) AND a.ActualReqDate<DATEADD(DAY,14,@ED1) THEN 'w3'
WHEN a.ActualReqDate>=DATEADD(DAY,21,@SD1) AND a.ActualReqDate<DATEADD(DAY,21,@ED1) THEN 'w4'
WHEN a.ActualReqDate>=DATEADD(DAY,28,@SD1) AND a.ActualReqDate<DATEADD(DAY,28,@ED1) THEN 'w5'
WHEN a.ActualReqDate>=DATEADD(DAY,35,@SD1) AND a.ActualReqDate<DATEADD(DAY,35,@ED1) THEN 'w6'
WHEN a.ActualReqDate>=DATEADD(DAY,42,@SD1) AND a.ActualReqDate<DATEADD(DAY,42,@ED1) THEN 'w7'
WHEN a.ActualReqDate>=DATEADD(DAY,49,@SD1) AND a.ActualReqDate<DATEADD(DAY,49,@ED1) THEN 'w8'
WHEN a.DocNo='安全库存'
THEN 'SafeQty'
ELSE '' END Duration
,a.MRPCategory,a.Operators,a.Code,a.Name,a.SPEC,a.LackAmount
FROM #tempMalai a 
),
data2 AS
(
SELECT * 
FROM data1 a  
PIVOT(SUM(a.LackAmount) FOR duration IN ([w0],[w1],[w2],[w3],[w4],[w5],[w6],[w7],[w8],[SafeQty])) AS t
),
data3 AS
(
SELECT code,MAX(a.WhavailiableAmount+a.ReqQty)WhQty,min(a.WhAvailiableAmount)WhAvailiableAmount--,MIN(b.SafetyStockQty)SafetyStockQty
FROM #tempMalai a   LEFT JOIN dbo.CBO_InventoryInfo b ON a.Itemmaster=b.ItemMaster
GROUP BY a.Code 
)
SELECT a.*,b.WhQty,b.WhAvailiableAmount--,CONVERT(DECIMAL(18,0),b.SafetyStockQty)SafetyStockQty 
INTO #tempMW8 
FROM data2 a LEFT JOIN data3 b ON a.Code=b.Code

SELECT @html=@html+N'<H2 bgcolor="#7CFC00">马来8周未齐套单据汇总列表<span style="color:red;">（不欠料为0）</span></H2>'
+N'<table border="1">'
+N'<tr bgcolor="#cae7fc">
<th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">Buyer</th>
<th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th>
<th nowrap="nowrap">逾期欠料</th>
<th nowrap="nowrap">安全库存欠料</th>
<th nowrap="nowrap">'+RIGHT(CONVERT(VARCHAR(20),@SD1),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,@ED1)),5)+'</th>
<th nowrap="nowrap">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,7,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,7,@ED1))),5)+'</th>
<th nowrap="nowrap">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,14,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,14,@ED1))),5)+'</th>
<th nowrap="nowrap">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,21,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,21,@ED1))),5)+'</th>
<th nowrap="nowrap">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,28,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,28,@ED1))),5)+'</th>
<th nowrap="nowrap">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,35,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,35,@ED1))),5)+'</th>
<th nowrap="nowrap">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,42,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,42,@ED1))),5)+'</th>
<th nowrap="nowrap">'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,49,@SD1)),5)+'~'+RIGHT(CONVERT(VARCHAR(20),DATEADD(DAY,-1,DATEADD(DAY,49,@ED1))),5)+'</th>
<th nowrap="nowrap">8周欠料数量</th>
<th nowrap="nowrap">库存现有量</th>
</tr>'
+ISNULL(CAST(( SELECT td=ISNULL(a.MRPCategory,''),'',td=ISNULL(a.Operators,''),'',td=a.Code,'',td=a.Name,'',td=a.SPEC,''
,td=CASE WHEN ISNULL(a.w0,0)>0 THEN 0 ELSE ISNULL(a.w0,0)*(-1) END ,''
,td=CASE WHEN ISNULL(a.SafeQty,0)>0 THEN 0 ELSE ISNULL(a.SafeQty,0)*(-1)END ,''
,td=CASE WHEN ISNULL(a.w1,0)>0 THEN 0 ELSE ISNULL(a.w1,0)*(-1) END ,''
--,td=CASE WHEN ISNULL(a.w1,0)>0 THEN 0 ELSE ISNULL(a.w1,0)*(-1) END ,''
,td=CASE WHEN ISNULL(a.w2,0)>0 THEN 0 ELSE ISNULL(a.w2,0)*(-1) END ,''
,td=CASE WHEN ISNULL(a.w3,0)>0 THEN 0 ELSE ISNULL(a.w3,0)*(-1) END ,''
,td=CASE WHEN ISNULL(a.w4,0)>0 THEN 0 ELSE ISNULL(a.w4,0)*(-1) END ,''
,td=CASE WHEN ISNULL(a.w5,0)>0 THEN 0 ELSE ISNULL(a.w5,0)*(-1) END ,''
,td=CASE WHEN ISNULL(a.w6,0)>0 THEN 0 ELSE ISNULL(a.w6,0)*(-1) END ,''
,td=CASE WHEN ISNULL(a.w7,0)>0 THEN 0 ELSE ISNULL(a.w7,0)*(-1) END ,''
,td=CASE WHEN ISNULL(a.w8,0)>0 THEN 0 ELSE ISNULL(a.w8,0)*(-1) END ,''
--,td=a.WhAvailiableAmount*(-1)+a.SafetyStockQty,''
,td=a.WhAvailiableAmount*(-1),''
,td=a.WhQty
FROM #tempMW8 a WHERE a.WhAvailiableAmount<0
ORDER BY ISNULL(a.w0,0),ISNULL(a.w1,0),ISNULL(a.w2,0),ISNULL(a.w3,0),ISNULL(a.w4,0),ISNULL(a.w5,0),ISNULL(a.w6,0),ISNULL(a.w7,0),ISNULL(a.w8,0),a.code FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')+N'</table><br/>'

--保存齐套汇总结果集
--保存齐套汇总结果集
INSERT INTO Auctus_FullSetCheckSummary
SELECT a.MRPCategory,a.Buyer,a.MCName,a.Code,a.Name,a.SPEC,ISNULL(a.w0,0), ISNULL(a.w1,0),ISNULL(a.w2,0),ISNULL(a.w3,0),ISNULL(a.w4,0),ISNULL(a.w5,0),ISNULL(a.w6,0),ISNULL(a.w7,0),ISNULL(a.w8,0)
,a.WhQty,a.WhAvailiableAmount,@Date
FROM #tempW8 a
UNION ALL
SELECT a.MRPCategory,a.Operators,'',a.Code,a.Name,a.SPEC,ISNULL(a.w0,0), ISNULL(a.w1,0),ISNULL(a.w2,0),ISNULL(a.w3,0),ISNULL(a.w4,0),ISNULL(a.w5,0),ISNULL(a.w6,0),ISNULL(a.w7,0),ISNULL(a.w8,0)
,a.WhQty,a.WhAvailiableAmount,@Date
FROM #tempMW8 a


declare @strbody varchar(800)
declare @style Varchar(2000)
SET @style=	'<style>table,table tr th, table tr td { border:2px solid #cecece; } table {text-align: center; border-collapse: collapse; padding:2px;}</style>'
set @strbody=@style+N'<H2>Dear All,</H2><H2></br>&nbsp;&nbsp;以下是截止'+convert(varchar(19),@Date56,120)+'（不包含'+convert(varchar(19),@Date56,120)+'）的工单齐套数据，请相关人员知悉。谢谢！</H2>'
set @html=@strbody+@html+N'</br><H2>以上由系统发出无需回复!</H2>'
SET @html=REPLACE(@html,'<w1data>','<td>')
SET @html=REPLACE(@html,'</w1data>','</td>')
SET @html=REPLACE(@html,'<w2data>','<td colspan="2">')
SET @html=REPLACE(@html,'</w2data>','</td>')
SET @html=REPLACE(@html,'<w3data>','<td colspan="2">')
SET @html=REPLACE(@html,'</w3data>','</td>')

 EXEC msdb.dbo.sp_send_dbmail 
	@profile_name=db_Automail, 
	@recipients='ufsc@auctus.cn;', 
	@copy_recipients='zougl@auctus.cn;hudz@auctus.cn;',
	@blind_copy_recipients='liufei@auctus.com',
	--@recipients='liufei@auctus.com;', 
	--@copy_recipients='zougl@auctus.cn;hudz@auctus.cn;', 
	@subject ='未齐套单据汇总列表（8周）',
	@body = @html,
	@body_format = 'HTML'; 
	



END 