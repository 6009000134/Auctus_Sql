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

*/
ALTER PROC [dbo].[sp_Auctus_Mail_AllSetCheckWarning]
AS
BEGIN
DECLARE @html NVARCHAR(MAX)=''
DECLARE @Date DATE
DECLARE @Date7 DATE
DECLARE @Date3 DATE
DECLARE @Date15 DATE
DECLARE @Date21 DATE
DECLARE @Date56 DATE
SET @Date=GETDATE()
SET @Date7=DATEADD(DAY,7,GETDATE()) --7天齐套预警
SET @Date3=DATEADD(DAY,3,GETDATE()) --3天齐套预警
SET @Date15=DATEADD(DAY,14,GETDATE())--14天齐套预警
--SET @Date15=DATEADD(DAY,15,GETDATE())--15天齐套预警
SET @Date21=DATEADD(DAY,21,GETDATE())--21天齐套预警
SET @Date56=DATEADD(DAY,56,GETDATE())--15天齐套预警
--8周起始日期天汇总列表
DECLARE @SD1 DATE,@ED1 DATE
SET @SD1=DATEADD(DAY,2+(-1)*DATEPART(WEEKDAY,GETDATE()),GETDATE())
SET @ED1=DATEADD(DAY,7,@SD1)
SET @Date56=DATEADD(DAY,56,@SD1)--15天齐套预警

--料品扩展字段的值集
 IF object_id('tempdb.dbo.#tempMRPCategory') is NULL
 CREATE TABLE #tempMRPCategory(Code VARCHAR(50),Name NVARCHAR(255),Type VARCHAR(50))
 ELSE
 TRUNCATE TABLE #tempMRPCategory
 --MRP分类值集
 INSERT INTO #tempMRPCategory
         ( Code, Name, Type )
SELECT T.Code,T.Name,'MRPCategory' FROM ( SELECT  A.[ID] as [ID], A.[Code] as [Code], A1.[Name] as [Name], A.[SysVersion] as [SysVersion], A.[ID] as [MainID], A2.[Code] as SysMlFlag
 , ROW_NUMBER() OVER(ORDER BY A.[Code] asc, (A.[ID] + 17) asc ) AS rownum  FROM  Base_DefineValue as A  left join Base_Language as A2 on (A2.Code = 'zh-CN')
  and (A2.Effective_IsEffective = 1)  left join [Base_DefineValue_Trl] as A1 on (A1.SysMlFlag = 'zh-CN') and (A1.SysMlFlag = A2.Code) and (A.[ID] = A1.[ID])
   WHERE  (((((((A.[ValueSetDef] = (SELECT ID FROM Base_ValueSetDef WHERE code='MRPCategory') ) and (A.[Effective_IsEffective] = 1)) and (A.[Effective_EffectiveDate] <= GETDATE())) 
   AND (A.[Effective_DisableDate] >= GETDATE())) and (1 = 1)) and (1 = 1)) and (1 = 1))) T



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
WHERE CopyDate>CONVERT(DATE,@Date)


----删除1条缺料的数据都没有的料号
--DELETE FROM #tempTable WHERE Code IN (
--SELECT t.Code
--FROM (
--SELECT a.Code,CASE WHEN a.islack='缺料' THEN 1 ELSE 0 END flag FROM #tempTable a) t
--GROUP BY t.Code
--HAVING SUM(t.flag)=0
--)


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
 
 INSERT INTO Auctus_Malai SELECT *,GETDATE() FROM #tempMalai 
 
-- --删除1条缺料的数据都没有的料号
--DELETE FROM #tempMalai WHERE Code IN (
--SELECT t.Code
--FROM (
--SELECT a.Code,CASE WHEN a.islack='缺料' THEN 1 ELSE 0 END flag FROM #tempMalai a) t
--GROUP BY t.Code
--HAVING SUM(t.flag)=0
--)

IF OBJECT_ID(N'tempdb.dbo.#tempResult',N'U') IS NULL
CREATE TABLE #tempResult
(
Operator NVARCHAR(20),
MRPCategory VARCHAR(50),
MRPCode VARCHAR(50),
totalCount INT,
LackCount INT,
UnLackCount INT,
Rate VARCHAR(20),
Type int
)
ELSE
TRUNCATE TABLE #tempResult




--3天齐套料品数据
;
WITH data1 AS
(
SELECT DISTINCT a.Code,a.MRPCategory,a.MRPCode
,CASE WHEN a.MRPCategory='电子' OR a.MRPCategory='结构' OR a.MRPCategory='包材' OR a.MRPCategory='配件' THEN ISNULL(a.Buyer,'')
ELSE ISNULL(a.MCName,'')END   Operator --负责人：有采购取采购 ，无采购取PMC
,CASE WHEN  a.IsLack='缺料'THEN 1
ELSE 0 END ResultFlag--缺料标识
,CASE WHEN a.ActualReqDate<@Date3 THEN 1 ELSE 0 END IS3
,CASE WHEN a.ActualReqDate<@Date7 THEN 1 ELSE 0 END IS7
,CASE WHEN a.ActualReqDate<@Date15 THEN 1 ELSE 0 END IS15
,CASE WHEN a.ActualReqDate<@Date21 THEN 1 ELSE 0 END IS21
FROM #tempTable a --LEFT JOIN dbo.CBO_Operators b ON a.DescFlexField_PrivateDescSeg23=b.Code LEFT JOIN dbo.CBO_Operators_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
WHERE (ISNULL(a.MRPCategory,'')<>'' or ISNULL(a.Buyer,'')<>'') --AND a.ActualReqDate<@Date3
AND a.DocNo<>'安全库存'
),
Result3 AS
(
SELECT a.Code,a.MRPCategory,a.MRPCode,ISNULL(a.Operator,'')Operator,SUM(a.ResultFlag)Result--Result=1，说明有缺料的数据，Result=0说明只有齐套数据 
FROM data1 a 
WHERE a.IS3=1
GROUP BY a.Code,a.MRPCategory,a.MRPCode,a.Operator
),
LackResult3 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)LackCount FROM Result3  a WHERE a.Result>0 GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
TotalResult3 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)totalCount FROM Result3  a GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
Result7 AS
(
SELECT a.Code,a.MRPCategory,a.MRPCode,ISNULL(a.Operator,'')Operator,SUM(a.ResultFlag)Result--Result=1，说明有缺料的数据，Result=0说明只有齐套数据 
FROM data1 a 
WHERE a.IS7=1
GROUP BY a.Code,a.MRPCategory,a.MRPCode,a.Operator
),
LackResult7 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)LackCount FROM Result7  a WHERE a.Result>0 GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
TotalResult7 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)totalCount FROM Result7  a GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
Result15 AS
(
SELECT a.Code,a.MRPCategory,a.MRPCode,ISNULL(a.Operator,'')Operator,SUM(a.ResultFlag)Result--Result=1，说明有缺料的数据，Result=0说明只有齐套数据 
FROM data1 a 
WHERE a.IS15=1
GROUP BY a.Code,a.MRPCategory,a.MRPCode,a.Operator
),
LackResult15 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)LackCount FROM Result15  a WHERE a.Result>0 GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
TotalResult15 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)totalCount FROM Result15  a GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
Result21 AS
(
SELECT a.Code,a.MRPCategory,a.MRPCode,ISNULL(a.Operator,'')Operator,SUM(a.ResultFlag)Result--Result=1，说明有缺料的数据，Result=0说明只有齐套数据 
FROM data1 a 
WHERE a.IS21=1
GROUP BY a.Code,a.MRPCategory,a.MRPCode,a.Operator
),
LackResult21 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)LackCount FROM Result21  a WHERE a.Result>0 GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
TotalResult21 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Code)totalCount FROM Result21  a GROUP BY a.Operator,a.MRPCategory,a.MRPCode
)
INSERT INTO #tempResult
SELECT a.*,ISNULL(b.LackCount,0)LackCount,a.totalCount-ISNULL(b.LackCount,0) UnLackCount
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.totalCount-ISNULL(b.LackCount,0))/CONVERT(DECIMAL(18,4),a.totalCount)*100))+'%' Rate
,3
FROM  TotalResult3 a LEFT JOIN LackResult3 b ON a.Operator=b.Operator AND a.MRPCategory=b.MRPCategory
UNION ALL
SELECT a.*,ISNULL(b.LackCount,0)LackCount,a.totalCount-ISNULL(b.LackCount,0) UnLackCount
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.totalCount-ISNULL(b.LackCount,0))/CONVERT(DECIMAL(18,4),a.totalCount)*100))+'%' Rate
,7
FROM TotalResult7  a LEFT JOIN LackResult7 b ON a.Operator=b.Operator AND a.MRPCategory=b.MRPCategory
UNION ALL
SELECT a.*,ISNULL(b.LackCount,0)LackCount,a.totalCount-ISNULL(b.LackCount,0) UnLackCount
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.totalCount-ISNULL(b.LackCount,0))/CONVERT(DECIMAL(18,4),a.totalCount)*100))+'%' Rate
,15
FROM TotalResult15  a LEFT JOIN LackResult15 b ON a.Operator=b.Operator AND a.MRPCategory=b.MRPCategory
UNION ALL
SELECT a.*,ISNULL(b.LackCount,0)LackCount,a.totalCount-ISNULL(b.LackCount,0) UnLackCount
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.totalCount-ISNULL(b.LackCount,0))/CONVERT(DECIMAL(18,4),a.totalCount)*100))+'%' Rate
,21
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
SELECT a.*,ISNULL(b.LackCount,0)LackCount,a.totalCount-ISNULL(b.LackCount,0) UnLackCount
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.totalCount-ISNULL(b.LackCount,0))/CONVERT(DECIMAL(18,4),a.totalCount)*100))+'%' Rate
,152
FROM Result3 a LEFT JOIN Result2 b ON a.Operator=b.Operator AND a.MRPCategory=b.MRPCategory


--按人员统计工单齐套率


;
WITH data1 AS
(
SELECT c1.Name Op,b.DescFlexField_PrivateDescSeg22 ProMRP,mrp.Name ProMRPCategory,a.*
,CASE WHEN a.ActualReqDate<@Date3 THEN 1 ELSE 0 END IS3
,CASE WHEN a.ActualReqDate<@Date7 THEN 1 ELSE 0 END IS7
,CASE WHEN a.ActualReqDate<@Date15 THEN 1 ELSE 0 END IS15
,CASE WHEN a.ActualReqDate<@Date21 THEN 1 ELSE 0 END IS21
FROM #tempTable a LEFT JOIN dbo.CBO_ItemMaster b ON a.ProductID=b.ID
LEFT JOIN dbo.CBO_Operators c ON b.DescFlexField_PrivateDescSeg24=c.Code LEFT JOIN dbo.CBO_Operators_Trl c1 ON c.ID=c1.ID
LEFT JOIN #tempMRPCategory mrp ON b.DescFlexField_PrivateDescSeg22=mrp.Code
WHERE a.ActualReqDate<@Date21 AND a.MRPCategory<>'内部生产' AND b.DescFlexField_PrivateDescSeg22 NOT IN ('MRP104','MRP105','MRP106','MRP113')
AND a.DocNo<>'安全库存'
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
SELECT a.Op,a.ProMRPCategory,a.ProMRP,a.total,ISNULL(b.untotal,0)untotal,a.total-ISNULL(b.untotal,0),CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.total-ISNULL(b.untotal,0))/CONVERT(DECIMAL(18,4),a.total)*100))+'%' Rate,a.T FROM TotalCount3 a LEFT JOIN UnTotalCount3 b ON a.Op=b.Op AND b.ProMRP = a.ProMRP
UNION
SELECT a.Op,a.ProMRPCategory,a.ProMRP,a.total,ISNULL(b.untotal,0)untotal,a.total-ISNULL(b.untotal,0),CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.total-ISNULL(b.untotal,0))/CONVERT(DECIMAL(18,4),a.total)*100))+'%' Rate,a.T FROM TotalCount7 a LEFT JOIN UnTotalCount7 b ON a.Op=b.Op AND b.ProMRP = a.ProMRP
UNION
SELECT a.Op,a.ProMRPCategory,a.ProMRP,a.total,ISNULL(b.untotal,0)untotal,a.total-ISNULL(b.untotal,0),CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.total-ISNULL(b.untotal,0))/CONVERT(DECIMAL(18,4),a.total)*100))+'%' Rate,a.T FROM TotalCount15 a LEFT JOIN UnTotalCount15 b ON a.Op=b.Op AND b.ProMRP = a.ProMRP
UNION
SELECT a.Op,a.ProMRPCategory,a.ProMRP,a.total,ISNULL(b.untotal,0)untotal,a.total-ISNULL(b.untotal,0),CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.total-ISNULL(b.untotal,0))/CONVERT(DECIMAL(18,4),a.total)*100))+'%' Rate,a.T FROM TotalCount21 a LEFT JOIN UnTotalCount21 b ON a.Op=b.Op AND b.ProMRP = a.ProMRP

--SELECT * FROM #tempResult

;
WITH data1 AS
(
SELECT a.DocNo,a.Code,a.IsLack,a.Buyer,a.MRPCode,a.MRPCategory
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
SELECT a.Buyer,a.MRPCategory,a.MRPCode,a.Total,ISNULL(b.Total,0) UnTotal,a.Total-ISNULL(b.Total,0),CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.Total-ISNULL(b.Total,0))/CONVERT(DECIMAL(18,4),a.Total)*100))+'%',a.T 
FROM Total a LEFT JOIN UnTotal b ON a.Buyer=b.Buyer AND a.T=b.T AND a.MRPCode=b.MRPCode




--3x天工单齐套率
DECLARE @totalMOFullSetRate3 VARCHAR(20)
DECLARE @totalMONum3 INT
DECLARE @totalUnMoNum3 INT
SELECT @totalMONum3=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
SELECT @totalUnMoNum3=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
SELECT @totalMOFullSetRate3=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum3-@totalUnMoNum3)/CONVERT(DECIMAL(18,4),@totalMONum3)*100))+'%'


DECLARE @shichanRate3 VARCHAR(20)
DECLARE @shichan3 INT
DECLARE @shichanUn3 INT
SELECT @shichan3=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0
SELECT @shichanUn3=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0

SELECT @shichanRate3=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@shichan3-@shichanUn3)/CONVERT(DECIMAL(18,4),@shichan3)*100))+'%'


DECLARE @fxRate3 VARCHAR(20)
DECLARE @fx3 INT
DECLARE @fxUn3 INT
SELECT @fx3=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0
SELECT @fxUn3=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0

SELECT @fxRate3=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@fx3-@fxUn3)/CONVERT(DECIMAL(18,4),@fx3)*100))+'%'



--功放3x天工单齐套率
DECLARE @totalMOFullSetRate1003 VARCHAR(20)
DECLARE @totalMONum1003 INT
DECLARE @totalUnMoNum1003 INT
SELECT @totalMONum1003=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.ProductLine='功放' AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)=0 AND PATINDEX('%返修%',a.DocType)=0 
SELECT @totalUnMoNum1003=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.ProductLine='功放' AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存' 
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



;WITH data1 AS
(
SELECT *FROM #tempResult WHERE type=3 and  MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
),data2 AS
(
SELECT *FROM #tempResult WHERE type=33 and  MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
)
SELECT @html=@html+N'<H2 bgcolor="#7CFC00">3天齐套率(齐套的料号/总的料号数量)</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#cae7fc"><th nowrap="nowrap">类别</th><th nowrap="nowrap">负责人</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">物料数量</th><th nowrap="nowrap">未齐套物料数</th>
<th nowrap="nowrap">齐套物料数</th><th nowrap="nowrap">料号齐套率</th><th nowrap="nowrap">工单总数</th><th nowrap="nowrap">齐套工单数</th><th nowrap="nowrap">工单齐套率</th></tr>'
+ISNULL(CAST((SELECT td='原材料','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.LackCount,0),'',td=ISNULL(a.UnLackCount,0),'',td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0),'',td=ISNULL(b.Rate,'')
FROM data1 a FULL JOIN data2 b ON a.Operator=b.Operator AND a.MRPCode=b.MRPCode
--WHERE a.type=3 AND a.MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
ORDER BY a.Type,CASE WHEN a.MRPCode='MRP104'THEN 1
WHEN a.MRPCode='MRP106' THEN 2 
WHEN a.MRPCode='MRP105' THEN 3
WHEN a.MRPCode='MRP113' THEN 4 ELSE 5 END   FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')



;WITH data1 AS
(
SELECT *FROM #tempResult WHERE type=3 and  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107') 
),
data2 AS
(
SELECT * FROM #tempResult WHERE type=33 and  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107') 
)
SELECT @html=@html+N''
+ISNULL(CAST((SELECT td='产成品','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.LackCount,0),'',td=ISNULL(a.UnLackCount,0),'',td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0),'',td=ISNULL(b.Rate,'')
FROM data1 a FULL JOIN data2 b ON a.Operator=b.Operator AND  a.MRPCode=b.MRPCode
ORDER BY a.Type,a.Operator DESC,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')+N'</table><br/>'




--7天工单齐套率
DECLARE @totalMOFullSetRate7 VARCHAR(20)
DECLARE @totalMONum7 INT
DECLARE @totalUnMoNum7 INT
SELECT @totalMONum7=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date7 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
SELECT @totalUnMoNum7=COUNT(DISTINCT a.DocNo) FROM #tempTable a
WHERE ( a.IsLack='缺料') AND  a.ActualReqDate<@Date7 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
SELECT @totalMOFullSetRate7=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum7-@totalUnMoNum7)/CONVERT(DECIMAL(18,4),@totalMONum7)*100))+'%'



DECLARE @shichanRate7 VARCHAR(20)
DECLARE @shichan7 INT
DECLARE @shichanUn7 INT
SELECT @shichan7=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0
SELECT @shichanUn7=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0

SELECT @shichanRate7=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@shichan7-@shichanUn7)/CONVERT(DECIMAL(18,4),@shichan7)*100))+'%'



DECLARE @fxRate7 VARCHAR(20)
DECLARE @fx7 INT
DECLARE @fxUn7 INT
SELECT @fx7=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0
SELECT @fxUn7=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0

SELECT @fxRate7=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@fx7-@fxUn7)/CONVERT(DECIMAL(18,4),@fx7)*100))+'%'



--功放7x天工单齐套率
DECLARE @totalMOFullSetRate1007 VARCHAR(20)
DECLARE @totalMONum1007 INT
DECLARE @totalUnMoNum1007 INT
SELECT @totalMONum1007=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date7 AND a.ProductLine='功放' AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)=0 AND PATINDEX('%返修%',a.DocType)=0 
SELECT @totalUnMoNum1007=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date7 AND a.ProductLine='功放' AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
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
+N'<tr bgcolor="#cae7fc"><th nowrap="nowrap">类别</th><th nowrap="nowrap">负责人</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">物料数量</th><th nowrap="nowrap">未齐套物料数</th>
<th nowrap="nowrap">齐套物料数</th><th nowrap="nowrap">料号齐套率</th><th nowrap="nowrap">工单总数</th><th nowrap="nowrap">齐套工单数</th><th nowrap="nowrap">工单齐套率</th></tr>'
+ISNULL(CAST((SELECT td='原材料','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.LackCount,0),'',td=ISNULL(a.UnLackCount,0),'',td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0),'',td=ISNULL(b.Rate,'')
FROM data1 a full JOIN data2 b ON a.Operator=b.Operator AND a.MRPCode=b.MRPCode
--WHERE a.type=7 AND a.MRPCode IN ('MRP104','MRP105','MRP106','MRP113')
ORDER BY a.Type,CASE WHEN a.MRPCode='MRP104'THEN 1
WHEN a.MRPCode='MRP106' THEN 2 
WHEN a.MRPCode='MRP105' THEN 3
WHEN a.MRPCode='MRP113' THEN 4 ELSE 5 END   FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')

;
WITH data1 AS
(
SELECT * FROM #tempResult WHERE type=7 AND  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
),data2 AS
(
SELECT * FROM #tempResult WHERE type=77 AND  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
)
SELECT @html=@html+N''
+ISNULL(CAST((SELECT td='产成品','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.LackCount,0),'',td=ISNULL(a.UnLackCount,0),'',td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0),'',td=ISNULL(b.Rate,'')
FROM data1 a full JOIN data2 b ON a.Operator=b.Operator  AND a.MRPCode=b.MRPCode
--WHERE a.type=7 AND a.MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
ORDER BY  a.Type,a.Operator DESC,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')+N'</table><br/>'



--15天工单齐套率
DECLARE @totalMOFullSetRate15 VARCHAR(20)
DECLARE @totalMONum15 INT
DECLARE @totalUnMoNum15 INT
SELECT @totalMONum15=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date15 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
SELECT @totalUnMoNum15=COUNT(DISTINCT a.DocNo) FROM #tempTable a
WHERE ( a.IsLack='缺料')  AND a.ActualReqDate<@Date15 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
SELECT @totalMOFullSetRate15=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum15-@totalUnMoNum15)/CONVERT(DECIMAL(18,4),@totalMONum15)*100))+'%'



DECLARE @shichanRate15 VARCHAR(20)
DECLARE @shichan15 INT
DECLARE @shichanUn15 INT
SELECT @shichan15=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0
SELECT @shichanUn15=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0

SELECT @shichanRate15=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@shichan15-@shichanUn15)/CONVERT(DECIMAL(18,4),@shichan15)*100))+'%'



DECLARE @fxRate15 VARCHAR(20)
DECLARE @fx15 INT
DECLARE @fxUn15 INT
SELECT @fx15=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0
SELECT @fxUn15=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0

SELECT @fxRate15=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@fx15-@fxUn15)/CONVERT(DECIMAL(18,4),@fx15)*100))+'%'


--功放15x天工单齐套率
DECLARE @totalMOFullSetRate10015 VARCHAR(20)
DECLARE @totalMONum10015 INT
DECLARE @totalUnMoNum10015 INT
SELECT @totalMONum10015=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date15 AND a.ProductLine='功放' AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)=0 AND PATINDEX('%返修%',a.DocType)=0 
SELECT @totalUnMoNum10015=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE  (a.IsLack='缺料') AND a.ActualReqDate<@Date15 AND a.ProductLine='功放' AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
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
+N'<tr bgcolor="#cae7fc"><th nowrap="nowrap">类别</th><th nowrap="nowrap">负责人</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">物料数量</th><th nowrap="nowrap">未齐套物料数</th>
<th nowrap="nowrap">齐套物料数</th><th nowrap="nowrap">料号齐套率</th><th nowrap="nowrap">工单总数</th><th nowrap="nowrap">齐套工单数</th><th nowrap="nowrap">工单齐套率</th></tr>'
+ISNULL(CAST((SELECT td='原材料','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.LackCount,0),'',td=ISNULL(a.UnLackCount,0),'',td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0),'',td=ISNULL(b.Rate,'')
FROM data1 a full JOIN data2 b ON a.Operator=b.Operator AND a.MRPCode=b.MRPCode
--WHERE a.type=15 AND a.MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
ORDER BY a.Type,CASE WHEN a.MRPCode='MRP104'THEN 1
WHEN a.MRPCode='MRP106' THEN 2 
WHEN a.MRPCode='MRP105' THEN 3
WHEN a.MRPCode='MRP113' THEN 4 ELSE 5 END   FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')
;
WITH data1 AS
(
SELECT * FROM #tempResult WHERE type=15 AND  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
),data2 AS
(
SELECT * FROM #tempResult WHERE type=1515 AND  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
)
SELECT @html=@html+N''
+ISNULL(CAST((SELECT td='产成品','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.LackCount,0),'',td=ISNULL(a.UnLackCount,0),'',td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0),'',td=ISNULL(b.Rate,'')
FROM data1 a  full JOIN data2 b ON a.Operator=b.Operator AND a.MRPCode=b.MRPCode
--WHERE a.type=15 AND a.MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
ORDER BY a.Type,a.Operator DESC,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')+N'</table><br/>'



--21天工单齐套率
DECLARE @totalMOFullSetRate21 VARCHAR(20)
DECLARE @totalMONum21 INT
DECLARE @totalUnMoNum21 INT
SELECT @totalMONum21=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date21 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
SELECT @totalUnMoNum21=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date21 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
SELECT @totalMOFullSetRate21=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum21-@totalUnMoNum21)/CONVERT(DECIMAL(18,4),@totalMONum21)*100))+'%'


DECLARE @shichanRate21 VARCHAR(20)
DECLARE @shichan21 INT
DECLARE @shichanUn21 INT
SELECT @shichan21=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date21 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0
SELECT @shichanUn21=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date21 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)>0

SELECT @shichanRate21=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@shichan21-@shichanUn21)/CONVERT(DECIMAL(18,4),@shichan21)*100))+'%'


DECLARE @fxRate21 VARCHAR(20)
DECLARE @fx21 INT
DECLARE @fxUn21 INT
SELECT @fx21=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date21 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0
SELECT @fxUn21=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date21 AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%返修%',a.DocType)>0

SELECT @fxRate21=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@fx21-@fxUn21)/CONVERT(DECIMAL(18,4),@fx21)*100))+'%'



--功放3x天工单齐套率
DECLARE @totalMOFullSetRate10021 VARCHAR(20)
DECLARE @totalMONum10021 INT
DECLARE @totalUnMoNum10021 INT
SELECT @totalMONum10021=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date21 AND a.ProductLine='功放' AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存'
AND PATINDEX('%试产%',a.DocType)=0 AND PATINDEX('%返修%',a.DocType)=0 
SELECT @totalUnMoNum10021=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date21 AND a.ProductLine='功放' AND a.MRPCategory<>'内部生产' AND a.DocNo<>'安全库存' 
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
+N'<tr bgcolor="#cae7fc"><th nowrap="nowrap">类别</th><th nowrap="nowrap">负责人</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">物料数量</th><th nowrap="nowrap">未齐套物料数</th>
<th nowrap="nowrap">齐套物料数</th><th nowrap="nowrap">料号齐套率</th><th nowrap="nowrap">工单总数</th><th nowrap="nowrap">齐套工单数</th><th nowrap="nowrap">工单齐套率</th></tr>'
+ISNULL(CAST((SELECT td='原材料','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.LackCount,0),'',td=ISNULL(a.UnLackCount,0),'',td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0),'',td=ISNULL(b.Rate,'')
FROM data1 a FULL JOIN data2 b ON a.Operator=b.Operator AND a.MRPCode=b.MRPCode
ORDER BY a.Type,CASE WHEN a.MRPCode='MRP104'THEN 1
WHEN a.MRPCode='MRP106' THEN 2 
WHEN a.MRPCode='MRP105' THEN 3
WHEN a.MRPCode='MRP113' THEN 4 ELSE 5 END   FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')



;WITH data1 AS
(
SELECT *FROM #tempResult WHERE type=21 and  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107') 
),
data2 AS
(
SELECT * FROM #tempResult WHERE type=2121 and  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107') 
)
SELECT @html=@html+N''
+ISNULL(CAST((SELECT td='产成品','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.LackCount,0),'',td=ISNULL(a.UnLackCount,0),'',td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0),'',td=ISNULL(b.Rate,'')
FROM data1 a FULL JOIN data2 b ON a.Operator=b.Operator AND  a.MRPCode=b.MRPCode
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
WHERE a.type=152 AND a.MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
ORDER BY a.Type,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')
SET @html=@html+N'</table><br/>'





--工单的实际需求时间=实际需求时间-原材料采购后处理期
--委外WPO实际需求时间=实际需求时间-采购组件采购前处理提前期-原材料采购后处理期
UPDATE #tempTable 
SET ActualReqDate=CASE WHEN #tempTable.DocNo LIKE'WPO%' THEN  DATEADD(DAY,(ISNULL(a.PurBackwardProcessLT,0)+ISNULL(b.PurForwardProcessLT,0))*(-1),ActualReqDate)
ELSE DATEADD(DAY,(ISNULL(a.PurBackwardProcessLT,0))*(-1),ActualReqDate) END 
FROM CBO_MrpInfo a,dbo.CBO_MrpInfo b WHERE a.ItemMaster=#tempTable.ItemMaster AND b.ItemMaster=#tempTable.ProductID


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
SELECT code,MAX(a.WhavailiableAmount+a.ReqQty)WhQty,min(a.WhAvailiableAmount)WhAvailiableAmount--,MIN(a.SafetyStockQty)SafetyStockQty
FROM #tempTable a  
GROUP BY a.Code 
)
SELECT a.*,b.WhQty,b.WhAvailiableAmount--,b.SafetyStockQty 
INTO #tempW8 
FROM data2  a LEFT JOIN data3 b ON a.Code=b.Code

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
<th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">Buyer</th><th nowrap="nowrap">MC责任人</th>
<th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th>
<th nowrap="nowrap">待检数量</th>
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
+CAST(( SELECT td=ISNULL(a.MRPCategory,''),'',td=ISNULL(a.Buyer,''),'',td=ISNULL(a.MCName,''),'',td=a.Code,'',td=a.Name,'',td=a.SPEC,''
,td=CONVERT(DECIMAL(18,0),ISNULL(c.RcvQtyTU,0)),'',td=CASE WHEN ISNULL(a.w0,0)>0 THEN 0 ELSE ISNULL(a.w0,0)*(-1) END ,''
--,td=CASE WHEN ISNULL(a.SafeQty,0)>0 THEN 0 ELSE ISNULL(a.SafeQty,0)*(-1)END ,''
,td=ISNULL(b.SafeQtyLack,0),''
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
,td=(a.WhAvailiableAmount-ISNULL(b.SafeQtyLack,0))*(-1),''
--,td=a.WhAvailiableAmount*(-1),''
,td=a.WhQty
FROM #tempW8 a LEFT JOIN #tempLackSafe b ON a.Code=b.Code
LEFT JOIN RCVData c ON a.Code=c.ItemInfo_ItemCode
WHERE a.WhAvailiableAmount-ISNULL(b.SafeQtyLack,0)<0
--WHERE a.WhAvailiableAmount<0
ORDER BY ISNULL(a.w0,0),ISNULL(a.w1,0),ISNULL(a.w2,0),ISNULL(a.w3,0),ISNULL(a.w4,0),ISNULL(a.w5,0),ISNULL(a.w6,0),ISNULL(a.w7,0),ISNULL(a.w8,0),a.code FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))+N'</table><br/>'


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
,a.WhQty,a.WhAvailiableAmount,GETDATE()
FROM #tempW8 a
UNION ALL
SELECT a.MRPCategory,a.Operators,'',a.Code,a.Name,a.SPEC,ISNULL(a.w0,0), ISNULL(a.w1,0),ISNULL(a.w2,0),ISNULL(a.w3,0),ISNULL(a.w4,0),ISNULL(a.w5,0),ISNULL(a.w6,0),ISNULL(a.w7,0),ISNULL(a.w8,0)
,a.WhQty,a.WhAvailiableAmount,GETDATE()
FROM #tempMW8 a


declare @strbody varchar(800)
declare @style Varchar(2000)
SET @style=	'<style>table,table tr th, table tr td { border:2px solid #cecece; } table {text-align: center; border-collapse: collapse; padding:2px;}</style>'
set @strbody=@style+N'<H2>Dear All,</H2><H2></br>&nbsp;&nbsp;以下是截止'+convert(varchar(19),@Date56,120)+'（不包含'+convert(varchar(19),@Date56,120)+'）的工单齐套数据，请相关人员知悉。谢谢！</H2>'
set @html=@strbody+@html+N'</br><H2>以上由系统发出无需回复!</H2>'


 EXEC msdb.dbo.sp_send_dbmail 
	@profile_name=db_Automail, 
	--@recipients='andy@auctus.cn;huangxinhua@auctus.cn;perla_yu@auctus.cn;hanlm@auctus.cn;gexj@auctus.cn;xiesb@auctus.cn;yangm@auctus.cn;linbh@auctus.cn;
	--lisd@auctus.cn;gaolq@auctus.cn;liyuan@auctus.cn;zengting@auctus.cn;xianghj@auctus.cn;wuwx@auctus.cn;lijq@auctus.cn;
	--licq@auctus.com;zhouxy@auctus.com;lixw@auctus.com;dengyao@auctus.cn;liyan@auctus.cn;lihj@auctus.cn;heqh@auctus.cn;liugq@auctus.cn;zenggq@auctus.cn;liumz@auctus.cn;huanghl@auctus.cn;zhangjie@auctus.com;', 
	@recipients='ufsc@auctus.cn;', 
	@copy_recipients='zougl@auctus.cn;hudz@auctus.cn;',
	@blind_copy_recipients='liufei@auctus.com',
	--@recipients='liufei@auctus.cn;', 
	--@copy_recipients='zougl@auctus.cn;hudz@auctus.cn;', 
	@subject ='未齐套单据汇总列表（8周）',
	@body = @html,
	@body_format = 'HTML'; 
	



END 