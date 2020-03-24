--七天齐套预警
/*
(2019-3-26)
sp_Auctus_Mail_AllSetCheckWarning中的未齐套明细单据改成了60天汇总表格
此存储过程发送未齐套明细单据给PMC和采购
(2019-8-23)
增加采购开发列
(2020-3-24)
3、7、2周齐套表格增加工单齐套率列
*/
ALTER PROC [dbo].[sp_Auctus_Mail_AllSetCheckWarningDetail]
AS
BEGIN

DECLARE @html NVARCHAR(MAX)=''
DECLARE @Date DATE
DECLARE @Date7 DATE
DECLARE @Date3 DATE
DECLARE @Date15 DATE
DECLARE @SD1 DATE,@ED1 DATE
SET @Date=GETDATE()
SET @SD1=DATEADD(DAY,2+(-1)*DATEPART(WEEKDAY,@Date),@Date)--第一周第一天（周日）
SET @ED1=DATEADD(DAY,7,@SD1)--第一周最后一天（周6）
SET @Date7=DATEADD(DAY,7,@Date) --7天齐套预警
SET @Date3=DATEADD(DAY,3,@Date) --3天齐套预警
SET @Date15=DATEADD(DAY,7,@ED1)--15天齐套预警


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

--INSERT INTO #tempTable EXEC sp_Auctus_AllSetCheckWithDemandCode2 1001708020135665,'','','',@Date15,'1','1','0'


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
WHERE CopyDate>CONVERT(DATE,@Date) AND ActualReqDate<@Date15


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
 EXEC sp_Auctus_MalaiSetCheck 1001708020135665,'125','2000-01-01',@Date15



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




--3\7\15天齐套料品数据
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



--15天马来天齐套料品数据
;
WITH data1 AS
(
SELECT DISTINCT a.Code,a.MRPCategory,a.MRPCode
,a.Operators Operator --负责人：有采购取采购 ，无采购取PMC
,CASE WHEN a.IsLack='缺料'THEN 1
ELSE 0 END ResultFlag--缺料标识
FROM #tempMalai a 
WHERE (ISNULL(a.MRPCategory,'')<>'' or ISNULL(a.Operators,'')<>'')
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



---------------------------------------------------------

--按人员统计工单齐套率


;
WITH data1 AS
(
SELECT c1.Name Op,b.DescFlexField_PrivateDescSeg22 ProMRP,mrp.Name ProMRPCategory,a.*
,CASE WHEN a.ActualReqDate<@Date3 THEN 1 ELSE 0 END IS3
,CASE WHEN a.ActualReqDate<@Date7 THEN 1 ELSE 0 END IS7
,CASE WHEN a.ActualReqDate<@Date15 THEN 1 ELSE 0 END IS15
FROM #tempTable a LEFT JOIN dbo.CBO_ItemMaster b ON a.ProductID=b.ID
LEFT JOIN dbo.CBO_Operators c ON b.DescFlexField_PrivateDescSeg24=c.Code LEFT JOIN dbo.CBO_Operators_Trl c1 ON c.ID=c1.ID
LEFT JOIN #tempMRPCategory mrp ON b.DescFlexField_PrivateDescSeg22=mrp.Code
WHERE a.ActualReqDate<@Date15 AND a.MRPCategory<>'内部生产' AND b.DescFlexField_PrivateDescSeg22 NOT IN ('MRP104','MRP105','MRP106','MRP113')
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
)
INSERT INTO #TempResult
SELECT a.Op,a.ProMRPCategory,a.ProMRP,a.total,ISNULL(b.untotal,0)untotal,a.total-ISNULL(b.untotal,0),CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.total-ISNULL(b.untotal,0))/CONVERT(DECIMAL(18,4),a.total)*100))+'%' Rate,a.T FROM TotalCount3 a LEFT JOIN UnTotalCount3 b ON a.Op=b.Op AND b.ProMRP = a.ProMRP
UNION
SELECT a.Op,a.ProMRPCategory,a.ProMRP,a.total,ISNULL(b.untotal,0)untotal,a.total-ISNULL(b.untotal,0),CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.total-ISNULL(b.untotal,0))/CONVERT(DECIMAL(18,4),a.total)*100))+'%' Rate,a.T FROM TotalCount7 a LEFT JOIN UnTotalCount7 b ON a.Op=b.Op AND b.ProMRP = a.ProMRP
UNION
SELECT a.Op,a.ProMRPCategory,a.ProMRP,a.total,ISNULL(b.untotal,0)untotal,a.total-ISNULL(b.untotal,0),CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.total-ISNULL(b.untotal,0))/CONVERT(DECIMAL(18,4),a.total)*100))+'%' Rate,a.T FROM TotalCount15 a LEFT JOIN UnTotalCount15 b ON a.Op=b.Op AND b.ProMRP = a.ProMRP

--SELECT * FROM #tempResult
;
WITH data1 AS
(
SELECT a.DocNo,a.Code,a.IsLack,a.Buyer,a.MRPCode,a.MRPCategory
,CASE WHEN a.ActualReqDate<@Date3 THEN 1 ELSE '' END IS3
,CASE WHEN a.ActualReqDate<@Date7 THEN 1 ELSE '' END IS7
,CASE WHEN a.ActualReqDate<@Date15 THEN 1 ELSE '' END IS15
FROM #tempTable a WHERE a.MRPCategory IN ('电子','结构','包材','配件')
AND a.ActualReqDate<@Date15
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
)
INSERT INTO #tempResult
SELECT a.Buyer,a.MRPCategory,a.MRPCode,a.Total,ISNULL(b.Total,0) UnTotal,a.Total-ISNULL(b.Total,0),CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.Total-ISNULL(b.Total,0))/CONVERT(DECIMAL(18,4),a.Total)*100))+'%',a.T 
FROM Total a LEFT JOIN UnTotal b ON a.Buyer=b.Buyer AND a.T=b.T AND a.MRPCode=b.MRPCode


---------------------------------------------------------



--3x天工单齐套率
DECLARE @totalMOFullSetRate3 VARCHAR(20)
DECLARE @totalMONum3 INT
DECLARE @totalUnMoNum3 INT
SELECT @totalMONum3=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3 AND a.MRPCategory<>'内部生产'
SELECT @totalUnMoNum3=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.IsLack='缺料') AND a.ActualReqDate<@Date3  AND a.MRPCategory<>'内部生产'
SELECT @totalMOFullSetRate3=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum3-@totalUnMoNum3)/CONVERT(DECIMAL(18,4),@totalMONum3)*100))+'%'
SET @html=N'<h2 style="color:red;font-weight:bold;">3天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum3-@totalUnMoNum3))+'/'+CONVERT(VARCHAR(30),@totalMONum3)+'='+@totalMOFullSetRate3+'</h2>'


;
WITH data1 AS
(
SELECT *FROM #tempResult WHERE type=3 and  MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
),
data2 AS
(
SELECT *FROM #tempResult WHERE type=33 and  MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
)
SELECT @html=@html+N'<H2 bgcolor="#7CFC00">3天齐套率(齐套的料号/总的料号数量)</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#cae7fc"><th nowrap="nowrap">类别</th><th nowrap="nowrap">负责人</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">物料数量</th><th nowrap="nowrap">未齐套物料数</th>
<th nowrap="nowrap">齐套物料数</th><th nowrap="nowrap">料号齐套率</th><th nowrap="nowrap">工单总数</th>
<th nowrap="nowrap">齐套工单数</th><th nowrap="nowrap">工单齐套率</th></tr>'
+ISNULL(CAST((SELECT td='原材料','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.LackCount,0),'',td=ISNULL(a.UnLackCount,0),'',td=ISNULL(a.Rate,''),''
,td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0),'',td=ISNULL(b.Rate,'')
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
SELECT @totalMONum7=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date7 AND a.MRPCategory<>'内部生产'
SELECT @totalUnMoNum7=COUNT(DISTINCT a.DocNo) FROM #tempTable a
WHERE (a.IsLack='缺料') AND  a.ActualReqDate<@Date7 AND a.MRPCategory<>'内部生产'
SELECT @totalMOFullSetRate7=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum7-@totalUnMoNum7)/CONVERT(DECIMAL(18,4),@totalMONum7)*100))+'%'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">7天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum7-@totalUnMoNum7))+'/'+CONVERT(VARCHAR(30),@totalMONum7)+'='+@totalMOFullSetRate7+'</h2>'


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
SELECT @totalMONum15=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE  a.MRPCategory<>'内部生产'
SELECT @totalUnMoNum15=COUNT(DISTINCT a.DocNo) FROM #tempTable a
WHERE (a.IsLack='缺料') AND a.MRPCategory<>'内部生产'
SELECT @totalMOFullSetRate15=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum15-@totalUnMoNum15)/CONVERT(DECIMAL(18,4),@totalMONum15)*100))+'%'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">2周齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum15-@totalUnMoNum15))+'/'+CONVERT(VARCHAR(30),@totalMONum15)+'='+@totalMOFullSetRate15+'</h2>'



;
WITH data1 AS
(
SELECT * FROM #tempResult WHERE type=15 AND  MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
),data2 AS
(
SELECT * FROM #tempResult WHERE type=1515 AND  MRPCode IN ('MRP104','MRP105','MRP106','MRP113') 
)
SELECT @html=@html+N'<H2 bgcolor="#7CFC00">2周齐套率(齐套的料号/总的料号数量)</H2>'
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
SELECT * FROM #tempResult WHERE type=15 AND  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
),data2 AS
(
SELECT * FROM #tempResult WHERE type=1515 AND  MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
)
SELECT @html=@html+N''
+ISNULL(CAST((SELECT td='产成品','', td=ISNULL(a.Operator,b.Operator),'',td=ISNULL(a.MRPCategory,b.MRPCategory),''
,td=ISNULL(a.totalCount,0),'',td=ISNULL(a.LackCount,0),'',td=ISNULL(a.UnLackCount,0),'',td=ISNULL(a.Rate,''),'',td=ISNULL(b.totalCount,0),'',td=ISNULL(b.UnLackCount,0),'',td=ISNULL(b.Rate,'')
FROM data1 a full JOIN data2 b ON a.Operator=b.Operator  AND a.MRPCode=b.MRPCode
--WHERE a.type=7 AND a.MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
ORDER BY  a.Type,a.Operator DESC,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')+N'</table><br/>'



set @html=@html+N'<H2 bgcolor="#7CFC00">马来2周齐套率(齐套的料号/总的料号数量)</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">类别</th><th nowrap="nowrap">负责人</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">物料数量</th><th nowrap="nowrap">未齐套物料数</th>
<th nowrap="nowrap">齐套物料数</th><th nowrap="nowrap">齐套率</th></tr>'
SET @html=@html+ISNULL(CAST((SELECT td='原材料','',td=ISNULL(a.Operator,''),'',td=a.MRPCategory,''
,td=a.totalCount,'',td=a.LackCount,'',td=a.UnLackCount,'',td=a.Rate
FROM #tempResult a 
WHERE a.type=152 AND a.MRPCode IN ('MRP104','MRP105','MRP106','MRP113')
ORDER BY a.Type,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')
--
SET  @html=@html+ISNULL(CAST((SELECT td='产成品','', td=ISNULL(a.Operator,''),'',td=a.MRPCategory,''
,td=a.totalCount,'',td=a.LackCount,'',td=a.UnLackCount,'',td=a.Rate
FROM #tempResult a 
WHERE a.type=152 AND a.MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
ORDER BY a.Type,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')
SET @html=@html+N'</table><br/>'


--UPDATE #tempTable 
--SET ActualReqDate=CASE WHEN #tempTable.DocNo LIKE'WPO%' THEN  DATEADD(DAY,(ISNULL(a.PurBackwardProcessLT,0)+ISNULL(b.PurForwardProcessLT,0))*(-1),ActualReqDate)
--ELSE DATEADD(DAY,(ISNULL(a.PurBackwardProcessLT,0))*(-1),ActualReqDate) END 
--FROM CBO_MrpInfo a,dbo.CBO_MrpInfo b WHERE a.ItemMaster=#tempTable.ItemMaster AND b.ItemMaster=#tempTable.ProductID



SET @html=@html+N'<H2 bgcolor="#7CFC00">逾期未齐套单据列表</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">需求分类号</th><th nowrap="nowrap">工单号</th><th nowrap="nowrap">工单料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">负责人</th>
<th nowrap="nowrap">Buyer</th><th nowrap="nowrap">开发采购</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th><th nowrap="nowrap">需求量</th><th nowrap="nowrap">实际需求时间</th><th nowrap="nowrap">缺料数量</th>
<th nowrap="nowrap">库存可用量</th><th nowrap="nowrap">安全库存量</th><th nowrap="nowrap">请购单</th><th nowrap="nowrap">请购数量</th><th nowrap="nowrap">采购单</th><th nowrap="nowrap">采购数量</th><th nowrap="nowrap">收货单</th><th nowrap="nowrap">实收数量</th><th nowrap="nowrap">齐套标识</th></tr>'

SET @html=@html+ISNULL(CAST((SELECT td=ISNULL(a.DemandCode2,''),'',td=a.DocNo,'',td=a.ProductCode,'',td=a.ProductName,'',td=ISNULL(a.MRPCategory,''),''
,td=CASE a.MRPCategory WHEN '内部生产' THEN ISNULL(a.MCName,'')
WHEN 'SMT委外' THEN ISNULL(a.MCName,'')
WHEN '伟丰' THEN ISNULL(a.MCName,'')
WHEN '马来西亚' THEN ISNULL(a.MCName,'')
WHEN '结构委外' THEN ISNULL(a.MCName,'')
ELSE '' END ,''
,td=ISNULL(b1.Name,''),'',td=ISNULL(co1.Name,''),''
,td=a.Code,'',td=a.Name,'',td=ISNULL(a.SPEC,''),''
,td=a.ReqQty,'',td=CONVERT(DATE,a.ActualReqDate),'',td=a.LackAmount,'',td=a.WhavailiableAmount,'',td=a.SafetyStockQty,'',td=ISNULL(a.PRList,''),'',td=ISNULL(CONVERT(VARCHAR(20),a.PRApprovedQty),'')
,'',td=ISNULL(a.POList,''),'',td=ISNULL(CONVERT(VARCHAR(20),a.POReqQtyTu),''),'',td=ISNULL(a.RCVList,''),'',td=ISNULL(CONVERT(VARCHAR(20),''),a.RcvQtyTU),'',td=a.ResultFlag
FROM #tempTable a  LEFT JOIN dbo.CBO_Operators b ON a.DescFlexField_PrivateDescSeg23=b.Code LEFT JOIN dbo.CBO_Operators_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemMaster=c.ID LEFT JOIN dbo.CBO_Operators co ON c.DescFlexField_PrivateDescSeg6=co.code LEFT JOIN cbo_operators_trl co1 ON co.ID=co1.id AND ISNULL(co1.SysMLFlag,'zh-cn')='zh-cn'
WHERE (a.IsLack='缺料')  AND a.ActualReqDate<@SD1
ORDER BY a.RN  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')
SET @html=@html+N'</table><br/>'




SET @html=@html+N'<H2 bgcolor="#7CFC00">第一周（'+CONVERT(VARCHAR(50),@SD1)+'~'+CONVERT(VARCHAR(50),DATEADD(DAY,-1,@ED1))+'）未齐套单据列表</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">需求分类号</th><th nowrap="nowrap">工单号</th><th nowrap="nowrap">工单料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">负责人</th>
<th nowrap="nowrap">Buyer</th><th nowrap="nowrap">开发采购</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th><th nowrap="nowrap">需求量</th><th nowrap="nowrap">实际需求时间</th><th nowrap="nowrap">缺料数量</th>
<th nowrap="nowrap">库存可用量</th><th nowrap="nowrap">安全库存量</th><th nowrap="nowrap">请购单</th><th nowrap="nowrap">请购数量</th><th nowrap="nowrap">采购单</th><th nowrap="nowrap">采购数量</th><th nowrap="nowrap">收货单</th><th nowrap="nowrap">实收数量</th><th nowrap="nowrap">齐套标识</th></tr>'

SET @html=@html+ISNULL(CAST((SELECT td=ISNULL(a.DemandCode2,''),'',td=a.DocNo,'',td=a.ProductCode,'',td=a.ProductName,'',td=ISNULL(a.MRPCategory,''),''
,td=CASE a.MRPCategory WHEN '内部生产' THEN ISNULL(a.MCName,'')
WHEN 'SMT委外' THEN ISNULL(a.MCName,'')
WHEN '伟丰' THEN ISNULL(a.MCName,'')
WHEN '马来西亚' THEN ISNULL(a.MCName,'')
WHEN '结构委外' THEN ISNULL(a.MCName,'')
ELSE '' END ,''
,td=ISNULL(b1.Name,''),'',td=ISNULL(co1.Name,''),''
,td=a.Code,'',td=a.Name,'',td=ISNULL(a.SPEC,''),''
,td=a.ReqQty,'',td=CONVERT(DATE,a.ActualReqDate),'',td=a.LackAmount,'',td=a.WhavailiableAmount,'',td=a.SafetyStockQty,'',td=ISNULL(a.PRList,''),'',td=ISNULL(CONVERT(VARCHAR(20),a.PRApprovedQty),'')
,'',td=ISNULL(a.POList,''),'',td=ISNULL(CONVERT(VARCHAR(20),a.POReqQtyTu),''),'',td=ISNULL(a.RCVList,''),'',td=ISNULL(CONVERT(VARCHAR(20),''),a.RcvQtyTU),'',td=a.ResultFlag
FROM #tempTable a  LEFT JOIN dbo.CBO_Operators b ON a.DescFlexField_PrivateDescSeg23=b.Code LEFT JOIN dbo.CBO_Operators_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemMaster=c.ID LEFT JOIN dbo.CBO_Operators co ON c.DescFlexField_PrivateDescSeg6=co.code LEFT JOIN cbo_operators_trl co1 ON co.ID=co1.id AND ISNULL(co1.SysMLFlag,'zh-cn')='zh-cn'
WHERE (a.IsLack='缺料')  AND a.ActualReqDate<@ED1 AND a.ActualReqDate>=@SD1
ORDER BY a.RN  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')
SET @html=@html+N'</table><br/>'

SET @html=@html+N'<H2 bgcolor="#7CFC00">第二周（'+CONVERT(VARCHAR(50),@ED1)+'~'+CONVERT(VARCHAR(50),DATEADD(DAY,6,@ED1))+'）未齐套单据列表</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">需求分类号</th><th nowrap="nowrap">工单号</th><th nowrap="nowrap">工单料号</th>
<th nowrap="nowrap">品名</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">负责人</th>
<th nowrap="nowrap">Buyer</th><th nowrap="nowrap">开发采购</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th><th nowrap="nowrap">需求量</th><th nowrap="nowrap">实际需求时间</th><th nowrap="nowrap">缺料数量</th>
<th nowrap="nowrap">库存可用量</th><th nowrap="nowrap">安全库存量</th><th nowrap="nowrap">请购单</th><th nowrap="nowrap">请购数量</th><th nowrap="nowrap">采购单</th><th nowrap="nowrap">采购数量</th><th nowrap="nowrap">收货单</th><th nowrap="nowrap">实收数量</th><th nowrap="nowrap">齐套标识</th></tr>'
SET @html=@html+ISNULL(CAST((SELECT td=ISNULL(a.DemandCode2,''),'',td=a.DocNo,'',td=a.ProductCode,'',td=a.ProductName,'',td=ISNULL(a.MRPCategory,''),''
,td=CASE a.MRPCategory WHEN '内部生产' THEN ISNULL(a.MCName,'')
WHEN 'SMT委外' THEN ISNULL(a.MCName,'')
WHEN '伟丰' THEN ISNULL(a.MCName,'')
WHEN '马来西亚' THEN ISNULL(a.MCName,'')
WHEN '结构委外' THEN ISNULL(a.MCName,'')
ELSE '' END ,''
,td=ISNULL(b1.Name,''),'',td=ISNULL(co1.Name,''),''
,td=a.Code,'',td=a.Name,'',td=ISNULL(a.SPEC,''),''
,td=a.ReqQty,'',td=CONVERT(DATE,a.ActualReqDate),'',td=a.LackAmount,'',td=a.WhavailiableAmount,'',td=a.SafetyStockQty,'',td=ISNULL(a.PRList,''),'',td=ISNULL(CONVERT(VARCHAR(20),a.PRApprovedQty),'')
,'',td=ISNULL(a.POList,''),'',td=ISNULL(CONVERT(VARCHAR(20),a.POReqQtyTu),''),'',td=ISNULL(a.RCVList,''),'',td=ISNULL(CONVERT(VARCHAR(20),''),a.RcvQtyTU),'',td=a.ResultFlag
FROM #tempTable a  LEFT JOIN dbo.CBO_Operators b ON a.DescFlexField_PrivateDescSeg23=b.Code LEFT JOIN dbo.CBO_Operators_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemMaster=c.ID LEFT JOIN dbo.CBO_Operators co ON c.DescFlexField_PrivateDescSeg6=co.code LEFT JOIN cbo_operators_trl co1 ON co.ID=co1.id AND ISNULL(co1.SysMLFlag,'zh-cn')='zh-cn'
WHERE (a.IsLack='缺料')  AND a.ActualReqDate>=@ED1 AND a.ActualReqDate<DATEADD(DAY,7,@ED1)
ORDER BY a.RN  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')
SET @html=@html+N'</table><br/>'



SET @html=@html++N'<H2 bgcolor="#7CFC00">马来物料逾期未齐套单据列表</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">订单号</th><th nowrap="nowrap">行号</th>
<th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">负责人</th>
<th nowrap="nowrap">执行采购</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th>
<th nowrap="nowrap">需求量</th><th nowrap="nowrap">需求日期</th><th nowrap="nowrap">缺料数量</th>
<th nowrap="nowrap">库存可用量</th><th nowrap="nowrap">安全库存量</th><th nowrap="nowrap">齐套标识</th></tr>'
SET @html=@html+ISNULL(CAST((SELECT td=ISNULL(a.DocNo,a.SOList),'',td=ISNULL(a.DocLineNo,''),'',td=ISNULL(a.MRPCategory,''),''
,td=CASE a.MRPCategory WHEN '内部生产' THEN ISNULL(a.Operators,'')
WHEN 'SMT委外' THEN ISNULL(a.Operators,'')
WHEN '伟丰' THEN ISNULL(a.Operators,'')
WHEN '马来西亚' THEN ISNULL(a.Operators,'')
WHEN '结构委外' THEN ISNULL(a.Operators,'')
ELSE '' END ,''
,td=ISNULL(a.Operators,''),''
,td=a.Code,'',td=a.Name,'',td=ISNULL(a.SPEC,''),''
,td=a.ReqQty,'',td=CONVERT(DATE,a.ActualReqDate),'',td=a.LackAmount,'',td=a.WhavailiableAmount,'',td=CONVERT(DECIMAL(18,0),b.SafetyStockQty),'',td=a.IsLack
FROM #tempMalai a LEFT JOIN dbo.CBO_InventoryInfo b ON a.Itemmaster=b.ItemMaster
WHERE a.IsLack='缺料'  AND a.ActualReqDate<@SD1
ORDER BY a.RN  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')
SET @html=@html+N'</table><br/>'

SET @html=@html++N'<H2 bgcolor="#7CFC00">马来物料第一周（'+CONVERT(VARCHAR(50),@SD1)+'~'+CONVERT(VARCHAR(50),DATEADD(DAY,-1,@ED1))+'）未齐套单据列表</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">订单号</th><th nowrap="nowrap">行号</th>
<th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">负责人</th>
<th nowrap="nowrap">执行采购</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th>
<th nowrap="nowrap">需求量</th><th nowrap="nowrap">需求日期</th><th nowrap="nowrap">缺料数量</th>
<th nowrap="nowrap">库存可用量</th><th nowrap="nowrap">安全库存量</th><th nowrap="nowrap">齐套标识</th></tr>'
SET @html=@html+ISNULL(CAST((SELECT td=ISNULL(a.DocNo,a.SOList),'',td=ISNULL(a.DocLineNo,''),'',td=ISNULL(a.MRPCategory,''),''
,td=CASE a.MRPCategory WHEN '内部生产' THEN ISNULL(a.Operators,'')
WHEN 'SMT委外' THEN ISNULL(a.Operators,'')
WHEN '伟丰' THEN ISNULL(a.Operators,'')
WHEN '马来西亚' THEN ISNULL(a.Operators,'')
WHEN '结构委外' THEN ISNULL(a.Operators,'')
ELSE '' END ,''
,td=ISNULL(a.Operators,''),''
,td=a.Code,'',td=a.Name,'',td=ISNULL(a.SPEC,''),''
,td=a.ReqQty,'',td=CONVERT(DATE,a.ActualReqDate),'',td=a.LackAmount,'',td=a.WhavailiableAmount,'',td=CONVERT(DECIMAL(18,0),b.SafetyStockQty),'',td=a.IsLack
FROM #tempMalai a LEFT JOIN dbo.CBO_InventoryInfo b ON a.Itemmaster=b.ItemMaster
WHERE a.IsLack='缺料'  AND a.ActualReqDate>=@SD1 AND a.ActualReqDate<@ED1
ORDER BY a.RN  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')
SET @html=@html+N'</table><br/>'

SET @html=@html++N'<H2 bgcolor="#7CFC00">马来物料第二周（'+CONVERT(VARCHAR(50),@ED1)+'~'+CONVERT(VARCHAR(50),DATEADD(DAY,6,@ED1))+'）未齐套单据列表</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">订单号</th><th nowrap="nowrap">行号</th>
<th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">负责人</th>
<th nowrap="nowrap">执行采购</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th>
<th nowrap="nowrap">需求量</th><th nowrap="nowrap">需求日期</th><th nowrap="nowrap">缺料数量</th>
<th nowrap="nowrap">库存可用量</th><th nowrap="nowrap">安全库存量</th><th nowrap="nowrap">齐套标识</th></tr>'

SET @html=@html+ISNULL(CAST((SELECT td=ISNULL(a.DocNo,a.SOList),'',td=ISNULL(a.DocLineNo,''),'',td=ISNULL(a.MRPCategory,''),''
,td=CASE a.MRPCategory WHEN '内部生产' THEN ISNULL(a.Operators,'')
WHEN 'SMT委外' THEN ISNULL(a.Operators,'')
WHEN '伟丰' THEN ISNULL(a.Operators,'')
WHEN '马来西亚' THEN ISNULL(a.Operators,'')
WHEN '结构委外' THEN ISNULL(a.Operators,'')
ELSE '' END ,''
,td=ISNULL(a.Operators,''),''
,td=a.Code,'',td=a.Name,'',td=ISNULL(a.SPEC,''),''
,td=a.ReqQty,'',td=CONVERT(DATE,a.ActualReqDate),'',td=a.LackAmount,'',td=a.WhavailiableAmount,'',td=CONVERT(DECIMAL(18,0),b.SafetyStockQty),'',td=a.IsLack
FROM #tempMalai a LEFT JOIN dbo.CBO_InventoryInfo b ON a.Itemmaster=b.ItemMaster
WHERE a.IsLack='缺料'  AND a.ActualReqDate>=@ED1 AND a.ActualReqDate<DATEADD(DAY,7,@ED1)
ORDER BY a.RN  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')
SET @html=@html+N'</table><br/>'




declare @strbody varchar(800)
declare @style Varchar(200)
SET @style=	'<style>table,table tr th, table tr td { border:1px solid #4F94CD; } table {text-align: center; border-collapse: collapse; padding:2px;}</style>'
set @strbody=@style+N'<H2>Dear All,</H2><H2></br>&nbsp;&nbsp;以下是截止'+convert(varchar(19),@Date15,120)+'（不包含'+convert(varchar(19),@Date15,120)+'）的工单齐套数据，请相关人员知悉。谢谢！</H2>'
set @html=@strbody+@html+N'</br><H2>以上由系统发出无需回复!</H2>'



 EXEC msdb.dbo.sp_send_dbmail 
	@profile_name=db_Automail, 
	--@recipients='huangxinhua@auctus.cn;xiesb@auctus.cn;yangm@auctus.cn;linbh@auctus.cn;lisd@auctus.cn;liyuan@auctus.cn;wuwx@auctus.cn;lixw@auctus.com;dengyao@auctus.cn;liyan@auctus.cn;zhangjie@auctus.com;', 
	@recipients='ufscd@auctus.cn;', 
	@copy_recipients='zougl@auctus.cn;hudz@auctus.cn;',
	@blind_copy_recipients='liufei@auctus.com',
	--@recipients='liufei@auctus.cn;', 
	--@copy_recipients='zougl@auctus.cn;hudz@auctus.cn;', 
	@subject ='未齐套单据明细',
	@body = @html,
	@body_format = 'HTML'; 



END 






