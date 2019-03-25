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
*/
ALTER PROC [dbo].[sp_Auctus_Mail_AllSetCheckWarning]
AS
BEGIN
DECLARE @html NVARCHAR(MAX)=''
DECLARE @Date7 DATE
DECLARE @Date3 DATE
DECLARE @Date15 DATE
SET @Date7=DATEADD(DAY,7,GETDATE()) --7天齐套预警
SET @Date3=DATEADD(DAY,3,GETDATE()) --3天齐套预警
SET @Date15=DATEADD(DAY,15,GETDATE())--15天齐套预警
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
TRUNCATE TABLE #tempTable
INSERT INTO #tempTable EXEC sp_Auctus_AllSetCheckWithDemandCode2 1001708020135665,'','','',@Date15,'1','1','0'


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
RN INT	 
)
END
ELSE 
BEGIN
TRUNCATE TABLE #tempMalai
END
 INSERT INTO #tempMalai
 EXEC sp_Auctus_MalaiSetCheck 1001708020135665,'125',@Date15



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
,ISNULL(CASE a.MRPCategory WHEN '内部生产' THEN ISNULL(a.MCName,'')
WHEN 'SMT委外' THEN ISNULL(a.MCName,'')
WHEN '伟丰' THEN ISNULL(a.MCName,'')
WHEN '马来西亚' THEN ISNULL(a.MCName,'')
WHEN '结构委外' THEN ISNULL(a.MCName,'')
ELSE NULL END,a.Buyer)Operator --负责人：有采购取采购 ，无采购取PMC
,CASE WHEN  a.PRList IS NOT NULL OR a.POList IS NOT NULL OR a.RCVList IS NOT NULL OR a.IsLack='缺料'THEN 1
ELSE 0 END ResultFlag--缺料标识
FROM #tempTable a --LEFT JOIN dbo.CBO_Operators b ON a.DescFlexField_PrivateDescSeg23=b.Code LEFT JOIN dbo.CBO_Operators_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
WHERE (ISNULL(a.MRPCategory,'')<>'' or ISNULL(a.Buyer,'')<>'') AND a.ActualReqDate<@Date3
),
Result AS
(
SELECT a.Code,a.MRPCategory,a.MRPCode,a.Operator,SUM(a.ResultFlag)Result--Result=1，说明有缺料的数据，Result=0说明只有齐套数据 
FROM data1 a GROUP BY a.Code,a.MRPCategory,a.MRPCode,a.Operator
),
Result2 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Operator)LackCount FROM Result  a WHERE a.Result>0 GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
Result3 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Operator)totalCount FROM Result  a GROUP BY a.Operator,a.MRPCategory,a.MRPCode
)
INSERT INTO #tempResult
SELECT a.*,ISNULL(b.LackCount,0)LackCount,a.totalCount-ISNULL(b.LackCount,0) UnLackCount
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.totalCount-ISNULL(b.LackCount,0))/CONVERT(DECIMAL(18,4),a.totalCount)*100))+'%' Rate
,3
FROM Result3 a LEFT JOIN Result2 b ON a.Operator=b.Operator AND a.MRPCategory=b.MRPCategory

--7天齐套料品数据
;
WITH data1 AS
(
SELECT DISTINCT a.Code,a.MRPCategory,a.MRPCode
,ISNULL(CASE a.MRPCategory WHEN '内部生产' THEN ISNULL(a.MCName,'')
WHEN 'SMT委外' THEN ISNULL(a.MCName,'')
WHEN '伟丰' THEN ISNULL(a.MCName,'')
WHEN '马来西亚' THEN ISNULL(a.MCName,'')
WHEN '结构委外' THEN ISNULL(a.MCName,'')
ELSE NULL END,b1.Name)Operator --负责人：有采购取采购 ，无采购取PMC
,CASE WHEN  a.PRList IS NOT NULL OR a.POList IS NOT NULL OR a.RCVList IS NOT NULL OR a.IsLack='缺料'THEN 1
ELSE 0 END ResultFlag--缺料标识
FROM #tempTable a LEFT JOIN dbo.CBO_Operators b ON a.DescFlexField_PrivateDescSeg23=b.Code LEFT JOIN dbo.CBO_Operators_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
WHERE (ISNULL(a.MRPCategory,'')<>'' or ISNULL(b1.Name,'')<>'') AND a.ActualReqDate<@Date7
),
Result AS
(
SELECT a.Code,a.MRPCategory,a.MRPCode,a.Operator,SUM(a.ResultFlag)Result--Result=1，说明有缺料的数据，Result=0说明只有齐套数据 
FROM data1 a GROUP BY a.Code,a.MRPCategory,a.MRPCode,a.Operator
),
Result2 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Operator)LackCount FROM Result  a WHERE a.Result>0 GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
Result3 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Operator)totalCount FROM Result  a GROUP BY a.Operator,a.MRPCategory,a.MRPCode
)
INSERT INTO #tempResult
SELECT a.*,ISNULL(b.LackCount,0)LackCount,a.totalCount-ISNULL(b.LackCount,0) UnLackCount
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.totalCount-ISNULL(b.LackCount,0))/CONVERT(DECIMAL(18,4),a.totalCount)*100))+'%' Rate
,7
FROM Result3 a LEFT JOIN Result2 b ON a.Operator=b.Operator AND a.MRPCategory=b.MRPCategory

--15天齐套料品数据
;
WITH data1 AS
(
SELECT DISTINCT a.Code,a.MRPCategory,a.MRPCode
,ISNULL(CASE a.MRPCategory WHEN '内部生产' THEN ISNULL(a.MCName,'')
WHEN 'SMT委外' THEN ISNULL(a.MCName,'')
WHEN '伟丰' THEN ISNULL(a.MCName,'')
WHEN '马来西亚' THEN ISNULL(a.MCName,'')
WHEN '结构委外' THEN ISNULL(a.MCName,'')
ELSE NULL END,b1.Name)Operator --负责人：有采购取采购 ，无采购取PMC
,CASE WHEN  a.PRList IS NOT NULL OR a.POList IS NOT NULL OR a.RCVList IS NOT NULL OR a.IsLack='缺料'THEN 1
ELSE 0 END ResultFlag--缺料标识
FROM #tempTable a LEFT JOIN dbo.CBO_Operators b ON a.DescFlexField_PrivateDescSeg23=b.Code LEFT JOIN dbo.CBO_Operators_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
WHERE (ISNULL(a.MRPCategory,'')<>'' or ISNULL(b1.Name,'')<>'')
),
Result AS
(
SELECT a.Code,a.MRPCategory,a.MRPCode,a.Operator,SUM(a.ResultFlag)Result--Result=1，说明有缺料的数据，Result=0说明只有齐套数据 
FROM data1 a GROUP BY a.Code,a.MRPCategory,a.MRPCode,a.Operator
),
Result2 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Operator)LackCount FROM Result  a WHERE a.Result>0 GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
Result3 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Operator)totalCount FROM Result  a GROUP BY a.Operator,a.MRPCategory,a.MRPCode
)
INSERT INTO #tempResult
SELECT a.*,ISNULL(b.LackCount,0)LackCount,a.totalCount-ISNULL(b.LackCount,0) UnLackCount
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.totalCount-ISNULL(b.LackCount,0))/CONVERT(DECIMAL(18,4),a.totalCount)*100))+'%' Rate
,15
FROM Result3 a LEFT JOIN Result2 b ON a.Operator=b.Operator AND a.MRPCategory=b.MRPCategory


--15天马来天齐套料品数据
;
WITH data1 AS
(
SELECT DISTINCT a.Code,a.MRPCategory,a.MRPCode
,a.Operators Operator --负责人：有采购取采购 ，无采购取PMC
,CASE WHEN a.IsLack='缺料'THEN 1
ELSE 0 END ResultFlag--缺料标识
FROM #tempMalai a --LEFT JOIN dbo.CBO_Operators b ON a.DescFlexField_PrivateDescSeg23=b.Code LEFT JOIN dbo.CBO_Operators_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
WHERE (ISNULL(a.MRPCategory,'')<>'' or ISNULL(a.Operators,'')<>'')
),
Result AS
(
SELECT a.Code,a.MRPCategory,a.MRPCode,a.Operator,SUM(a.ResultFlag)Result--Result=1，说明有缺料的数据，Result=0说明只有齐套数据 
FROM data1 a GROUP BY a.Code,a.MRPCategory,a.MRPCode,a.Operator
),
Result2 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Operator)LackCount FROM Result  a WHERE a.Result>0 GROUP BY a.Operator,a.MRPCategory,a.MRPCode
),
Result3 AS
(
SELECT a.Operator,a.MRPCategory,a.MRPCode,COUNT(a.Operator)totalCount FROM Result  a GROUP BY a.Operator,a.MRPCategory,a.MRPCode
)
INSERT INTO #tempResult
SELECT a.*,ISNULL(b.LackCount,0)LackCount,a.totalCount-ISNULL(b.LackCount,0) UnLackCount
,CONVERT(VARCHAR(20),CONVERT(DECIMAL(18,2),(a.totalCount-ISNULL(b.LackCount,0))/CONVERT(DECIMAL(18,4),a.totalCount)*100))+'%' Rate
,152
FROM Result3 a LEFT JOIN Result2 b ON a.Operator=b.Operator AND a.MRPCategory=b.MRPCategory





--3x天工单齐套率
DECLARE @totalMOFullSetRate3 VARCHAR(20)
DECLARE @totalMONum3 INT
DECLARE @totalUnMoNum3 INT
SELECT @totalMONum3=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date3
SELECT @totalUnMoNum3=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
WHERE (a.PRList IS NOT NULL OR a.POList IS NOT NULL OR a.RCVList IS NOT NULL OR a.IsLack='缺料') AND a.ActualReqDate<@Date3
SELECT @totalMOFullSetRate3=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum3-@totalUnMoNum3)/CONVERT(DECIMAL(18,4),@totalMONum3)*100))+'%'
SET @html=N'<h2 style="color:red;font-weight:bold;">3天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum3-@totalUnMoNum3))+'/'+CONVERT(VARCHAR(30),@totalMONum3)+'='+@totalMOFullSetRate3+'</h2>'

DECLARE @rowSpan3 INT--3天合并行数
DECLARE @rowSpan32 INT--3天合并行数
SELECT @rowspan3=COUNT(*) FROM #tempResult WHERE type=3 AND MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
SELECT @rowspan32=COUNT(*) FROM #tempResult WHERE type=3 AND MRPCode IN ('MRP104','MRP105','MRP106')
--SELECT * FROM #tempResult WHERE type=3 ORDER BY type,MRPCode

SELECT @html=@html+N'<H2 bgcolor="#7CFC00">3天齐套率(齐套的料号/总的料号数量)</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">类别</th><th nowrap="nowrap">负责人</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">物料数量</th><th nowrap="nowrap">未齐套物料数</th>
<th nowrap="nowrap">齐套物料数</th><th nowrap="nowrap">齐套率</th></tr>'
+CAST((SELECT td='原材料','',td=ISNULL(a.Operator,''),'',td=a.MRPCategory,''
,td=a.totalCount,'',td=a.LackCount,'',td=a.UnLackCount,'',td=a.Rate
FROM #tempResult a 
WHERE a.type=3 AND a.MRPCode IN ('MRP104','MRP105','MRP106')
ORDER BY a.Type,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))

SELECT @html=@html+N''
+CAST((SELECT td='产成品','', td=ISNULL(a.Operator,''),'',td=a.MRPCategory,''
,td=a.totalCount,'',td=a.LackCount,'',td=a.UnLackCount,'',td=a.Rate
FROM #tempResult a 
WHERE a.type=3 AND a.MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
ORDER BY a.Type,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))+N'</table><br/>'





--7天工单齐套率
DECLARE @totalMOFullSetRate7 VARCHAR(20)
DECLARE @totalMONum7 INT
DECLARE @totalUnMoNum7 INT
SELECT @totalMONum7=COUNT(DISTINCT a.DocNo) FROM #tempTable a WHERE a.ActualReqDate<@Date7
SELECT @totalUnMoNum7=COUNT(DISTINCT a.DocNo) FROM #tempTable a
WHERE (a.PRList IS NOT NULL OR a.POList IS NOT NULL OR a.RCVList IS NOT NULL OR a.IsLack='缺料') AND  a.ActualReqDate<@Date7
SELECT @totalMOFullSetRate7=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum7-@totalUnMoNum7)/CONVERT(DECIMAL(18,4),@totalMONum7)*100))+'%'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">七天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum7-@totalUnMoNum7))+'/'+CONVERT(VARCHAR(30),@totalMONum7)+'='+@totalMOFullSetRate7+'</h2>'

DECLARE @rowSpan7 INT--7天合并行数
DECLARE @rowSpan72 INT--7天合并行数

SELECT @rowspan7=COUNT(*) FROM #tempResult WHERE type=7 AND MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
SELECT @rowspan72=COUNT(*) FROM #tempResult WHERE type=7 AND MRPCode IN ('MRP104','MRP105','MRP106')

SELECT @html=@html+N'<H2 bgcolor="#7CFC00">7天齐套率(齐套的料号/总的料号数量)</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">类别</th><th nowrap="nowrap">负责人</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">物料数量</th><th nowrap="nowrap">未齐套物料数</th>
<th nowrap="nowrap">齐套物料数</th><th nowrap="nowrap">齐套率</th></tr>'
+CAST((SELECT td='原材料','',td=ISNULL(a.Operator,''),'',td=a.MRPCategory,''
,td=a.totalCount,'',td=a.LackCount,'',td=a.UnLackCount,'',td=a.Rate
FROM #tempResult a 
WHERE a.type=7 AND a.MRPCode IN ('MRP104','MRP105','MRP106')
ORDER BY a.Type,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))

SELECT @html=@html+N''
+CAST((SELECT td='产成品','',td=ISNULL(a.Operator,''),'',td=a.MRPCategory,''
,td=a.totalCount,'',td=a.LackCount,'',td=a.UnLackCount,'',td=a.Rate
FROM #tempResult a 
WHERE a.type=7 AND a.MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
ORDER BY a.Type,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))+N'</table><br/>'


--15天工单齐套率
DECLARE @totalMOFullSetRate15 VARCHAR(20)
DECLARE @totalMONum15 INT
DECLARE @totalUnMoNum15 INT
SELECT @totalMONum15=COUNT(DISTINCT a.DocNo) FROM #tempTable a 
SELECT @totalUnMoNum15=COUNT(DISTINCT a.DocNo) FROM #tempTable a
WHERE (a.PRList IS NOT NULL OR a.POList IS NOT NULL OR a.RCVList IS NOT NULL OR a.IsLack='缺料') 
SELECT @totalMOFullSetRate15=CONVERT(VARCHAR(30),CONVERT(DECIMAL(18,2),(@totalMONum15-@totalUnMoNum15)/CONVERT(DECIMAL(18,4),@totalMONum15)*100))+'%'
SET @html=@html+N'<h2 style="color:red;font-weight:bold;">15天齐套率（齐套工单/总工单数）：'+CONVERT(VARCHAR(30),(@totalMONum15-@totalUnMoNum15))+'/'+CONVERT(VARCHAR(30),@totalMONum15)+'='+@totalMOFullSetRate15+'</h2>'

DECLARE @rowSpan15 INT--15天合并行数
DECLARE @rowSpan152 INT--15天合并行数

SELECT @rowspan15=COUNT(*) FROM #tempResult WHERE type=15 AND MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
SELECT @rowspan152=COUNT(*) FROM #tempResult WHERE type=15 AND MRPCode IN ('MRP104','MRP105','MRP106')

SELECT @html=@html+N'<H2 bgcolor="#7CFC00">15天齐套率(齐套的料号/总的料号数量)</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">类别</th><th nowrap="nowrap">负责人</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">物料数量</th><th nowrap="nowrap">未齐套物料数</th>
<th nowrap="nowrap">齐套物料数</th><th nowrap="nowrap">齐套率</th></tr>'
+CAST((SELECT td='原材料','',td=ISNULL(a.Operator,''),'',td=a.MRPCategory,''
,td=a.totalCount,'',td=a.LackCount,'',td=a.UnLackCount,'',td=a.Rate
FROM #tempResult a 
WHERE a.type=15 AND a.MRPCode IN ('MRP104','MRP105','MRP106')
ORDER BY a.Type,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))

SELECT @html=@html+N''
+CAST((SELECT td='产成品','',td=ISNULL(a.Operator,''),'',td=a.MRPCategory,''
,td=a.totalCount,'',td=a.LackCount,'',td=a.UnLackCount,'',td=a.Rate
FROM #tempResult a 
WHERE a.type=15 AND a.MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
ORDER BY a.Type,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))+N'</table><br/>'


SELECT @html=@html+N'<H2 bgcolor="#7CFC00">马来15天齐套率(齐套的料号/总的料号数量)</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">类别</th><th nowrap="nowrap">负责人</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">物料数量</th><th nowrap="nowrap">未齐套物料数</th>
<th nowrap="nowrap">齐套物料数</th><th nowrap="nowrap">齐套率</th></tr>'
+CAST((SELECT td='原材料','',td=ISNULL(a.Operator,''),'',td=a.MRPCategory,''
,td=a.totalCount,'',td=a.LackCount,'',td=a.UnLackCount,'',td=a.Rate
FROM #tempResult a 
WHERE a.type=152 AND a.MRPCode IN ('MRP104','MRP105','MRP106')
ORDER BY a.Type,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))
--
SELECT @html=@html+N''
+ISNULL(CAST((SELECT td='产成品','', td=ISNULL(a.Operator,''),'',td=a.MRPCategory,''
,td=a.totalCount,'',td=a.LackCount,'',td=a.UnLackCount,'',td=a.Rate
FROM #tempResult a 
WHERE a.type=152 AND a.MRPCode IN ('MRP100','MRP101','MRP102','MRP103','MRP107')
ORDER BY a.Type,a.MRPCode  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX)),'')+N'</table><br/>'








SELECT @html=@html+N'<H2 bgcolor="#7CFC00">7天未齐套单据列表</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">需求分类号</th><th nowrap="nowrap">订单号</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">负责人</th>
<th nowrap="nowrap">Buyer</th><th nowrap="nowrap">母件料号</th><th nowrap="nowrap">母件品名</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th><th nowrap="nowrap">需求量</th><th nowrap="nowrap">实际需求时间</th><th nowrap="nowrap">缺料数量</th>
<th nowrap="nowrap">库存可用量</th><th nowrap="nowrap">安全库存量</th><th nowrap="nowrap">请购单</th><th nowrap="nowrap">请购数量</th><th nowrap="nowrap">采购单</th><th nowrap="nowrap">采购数量</th><th nowrap="nowrap">收货单</th><th nowrap="nowrap">实收数量</th><th nowrap="nowrap">齐套标识</th></tr>'
+CAST((SELECT td=ISNULL(a.DemandCode2,''),'',td=a.DocNo,'',td=ISNULL(a.MRPCategory,''),''
,td=CASE a.MRPCategory WHEN '内部生产' THEN ISNULL(a.MCName,'')
WHEN 'SMT委外' THEN ISNULL(a.MCName,'')
WHEN '伟丰' THEN ISNULL(a.MCName,'')
WHEN '马来西亚' THEN ISNULL(a.MCName,'')
WHEN '结构委外' THEN ISNULL(a.MCName,'')
ELSE '' END ,''
,td=ISNULL(b1.Name,''),''
,td=c.Code,'',td=c.Name,''
,td=a.Code,'',td=a.Name,'',td=a.SPEC,''
,td=a.ReqQty,'',td=CONVERT(DATE,a.ActualReqDate),'',td=a.LackAmount,'',td=a.WhavailiableAmount,'',td=a.SafetyStockQty,'',td=ISNULL(a.PRList,''),'',td=ISNULL(CONVERT(VARCHAR(20),a.PRApprovedQty),'')
,'',td=ISNULL(a.POList,''),'',td=ISNULL(CONVERT(VARCHAR(20),a.POReqQtyTu),''),'',td=ISNULL(a.RCVList,''),'',td=ISNULL(CONVERT(VARCHAR(20),''),a.RcvQtyTU),'',td=a.ResultFlag
FROM #tempTable a  LEFT JOIN dbo.CBO_Operators b ON a.DescFlexField_PrivateDescSeg23=b.Code LEFT JOIN dbo.CBO_Operators_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_ItemMaster c ON a.ProductID=c.ID
WHERE (a.PRList IS NOT NULL OR a.POList IS NOT NULL OR a.RCVList IS NOT NULL OR a.IsLack='缺料')  AND a.ActualReqDate<@Date7
ORDER BY a.RN  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))+N'</table><br/>'



SET @html=@html++N'<H2 bgcolor="#7CFC00">马来物料15天未齐套单据列表</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">订单号</th><th nowrap="nowrap">行号</th>
<th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">负责人</th>
<th nowrap="nowrap">执行采购</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th>
<th nowrap="nowrap">需求量</th><th nowrap="nowrap">需求日期</th><th nowrap="nowrap">缺料数量</th>
<th nowrap="nowrap">库存可用量</th><th nowrap="nowrap">安全库存量</th><th nowrap="nowrap">齐套标识</th></tr>'
+CAST((SELECT td=a.DocNo,'',td=a.DocLineNo,'',td=ISNULL(a.MRPCategory,''),''
,td=CASE a.MRPCategory WHEN '内部生产' THEN ISNULL(a.Operators,'')
WHEN 'SMT委外' THEN ISNULL(a.Operators,'')
WHEN '伟丰' THEN ISNULL(a.Operators,'')
WHEN '马来西亚' THEN ISNULL(a.Operators,'')
WHEN '结构委外' THEN ISNULL(a.Operators,'')
ELSE '' END ,''
,td=ISNULL(a.Operators,''),''
,td=a.Code,'',td=a.Name,'',td=a.SPEC,''
,td=a.ReqQty,'',td=CONVERT(DATE,a.ActualReqDate),'',td=a.LackAmount,'',td=a.WhavailiableAmount,'',td=CONVERT(DECIMAL(18,0),b.SafetyStockQty),'',td=a.IsLack
FROM #tempMalai a LEFT JOIN dbo.CBO_InventoryInfo b ON a.Itemmaster=b.ItemMaster
WHERE a.IsLack='缺料'
ORDER BY a.RN  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))+N'</table><br/>'

SELECT @html=@html+N'<H2 bgcolor="#7CFC00">7-15天未齐套单据列表</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">需求分类号</th><th nowrap="nowrap">订单号</th><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">负责人</th>
<th nowrap="nowrap">Buyer</th><th nowrap="nowrap">母件料号</th><th nowrap="nowrap">母件品名</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th><th nowrap="nowrap">需求量</th><th nowrap="nowrap">实际需求时间</th><th nowrap="nowrap">缺料数量</th>
<th nowrap="nowrap">库存可用量</th><th nowrap="nowrap">安全库存量</th><th nowrap="nowrap">请购单</th><th nowrap="nowrap">请购数量</th><th nowrap="nowrap">采购单</th><th nowrap="nowrap">采购数量</th><th nowrap="nowrap">收货单</th><th nowrap="nowrap">实收数量</th><th nowrap="nowrap">齐套标识</th></tr>'
+CAST((SELECT td=ISNULL(a.DemandCode2,''),'',td=a.DocNo,'',td=ISNULL(a.MRPCategory,''),''
,td=CASE a.MRPCategory WHEN '内部生产' THEN ISNULL(a.MCName,'')
WHEN 'SMT委外' THEN ISNULL(a.MCName,'')
WHEN '伟丰' THEN ISNULL(a.MCName,'')
WHEN '马来西亚' THEN ISNULL(a.MCName,'')
WHEN '结构委外' THEN ISNULL(a.MCName,'')
ELSE '' END ,''
,td=ISNULL(b1.Name,''),''
,td=c.Code,'',td=c.Name,''
,td=a.Code,'',td=a.Name,'',td=a.SPEC,''
,td=a.ReqQty,'',td=CONVERT(DATE,a.ActualReqDate),'',td=a.LackAmount,'',td=a.WhavailiableAmount,'',td=a.SafetyStockQty,'',td=ISNULL(a.PRList,''),'',td=ISNULL(CONVERT(VARCHAR(20),a.PRApprovedQty),'')
,'',td=ISNULL(a.POList,''),'',td=ISNULL(CONVERT(VARCHAR(20),a.POReqQtyTu),''),'',td=ISNULL(a.RCVList,''),'',td=ISNULL(CONVERT(VARCHAR(20),''),a.RcvQtyTU),'',td=a.ResultFlag
FROM #tempTable a  LEFT JOIN dbo.CBO_Operators b ON a.DescFlexField_PrivateDescSeg23=b.Code LEFT JOIN dbo.CBO_Operators_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_ItemMaster c ON a.ProductID=c.ID
WHERE (a.PRList IS NOT NULL OR a.POList IS NOT NULL OR a.RCVList IS NOT NULL OR a.IsLack='缺料')  AND a.ActualReqDate>=@Date7
ORDER BY a.RN  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))+N'</table><br/>'





declare @strbody varchar(800)
declare @style Varchar(200)
SET @style=	'<style>table,table tr th, table tr td { border:1px solid #4F94CD; } table {text-align: center; border-collapse: collapse; padding:2px;}</style>'
set @strbody=@style+N'<H2>Dear All,</H2><H2></br>&nbsp;&nbsp;以下是截止'+convert(varchar(19),@Date15,120)+'（不包含'+convert(varchar(19),@Date15,120)+'）的工单齐套数据，请相关人员知悉。谢谢！</H2>'
set @html=@strbody+@html+N'</br><H2>以上由系统发出无需回复!</H2>'


 EXEC msdb.dbo.sp_send_dbmail 
	@profile_name=db_Automail, 
	@recipients='andy@auctus.cn;luojia@auctus.cn;perla_yu@auctus.cn;hanlm@auctus.cn;xiesb@auctus.cn;yangm@auctus.cn;linbh@auctus.cn;caidy@auctus.cn;lize@auctus.cn;
	caijuan@auctus.cn;lisd@auctus.com;gaolq@auctus.cn;liyuan@auctus.cn;zengting@auctus.cn;xianghj@auctus.cn;wuwx@auctus.cn;lijq@auctus.cn;tanglj@auctus.cn;xuwj@auctus.cn;licq@auctus.com;zhouxy@auctus.com;ligg@auctus.cn;lixw@auctus.com;', 
	@copy_recipients='zougl@auctus.cn;',
	@blind_copy_recipients='liufei@auctus.com',
	--@recipients='liufei@auctus.cn;', 
	--@copy_recipients='zougl@auctus.cn;hudz@auctus.cn;', 
	@subject ='15天未齐套单据列表',
	@body = @html,
	@body_format = 'HTML'; 



END 






