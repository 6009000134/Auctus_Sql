/*
标题：3天齐套率考核
需求：高李琼
开发：liufei
时间：2018-12-08

Update（2018-12-19）
逻辑理解错误，进行修正。按工单分组，若A员工在工单MO1中的料都齐套了，那么A的MO1工单算齐套，B员工MO1中的料缺料，B的MO1工单算不齐套
ADD（2019-5-7）
内部生产料号不参与考核

ADD(2019-5-14)
试产工单、功放工单单独拿出来计算
ADD(2019-6-4)
包材齐套考核只取一天
ADD(2019-6-17)
将逻辑修改成和邮件一样，原材料按备料单行取数据，PMC取工单生产料号负责人
buyer计算逻辑：      假如工单A的备料单行有杨密的10个料号且此工单的10个料号都齐套，则算杨密齐套1个工单，齐套率=齐套工单数/总工单数
PMC计算逻辑：      假如工单A生产的料号B属于李园，那么当工单A下面的所有备料单行（除内部生产的备料单行）全齐套了，则算李园齐套1个工单，齐套率=齐套工单数/总工单数
ADD(2019-8-1)
MRP分类增加了配件（配件料品是原包材料品修改过去的），配件与包材计算方式一样
ADD(2019-12-11)
按3天齐套率逻辑，所有人员增加14天齐套率考核
*/
ALTER PROC [dbo].[sp_Auctus_FullSetCheckRate]
(
@Org BIGINT,
@SD DATETIME,
@ED DATETIME
)
AS
BEGIN
--DECLARE @Org BIGINT,@SD DATETIME,@ED DATETIME
SET @ED=DATEADD(DAY,1,@ED);
--按执行采购、工单
IF OBJECT_ID(N'tempdb.dbo.#tempInfo',N'U') IS NULL
CREATE TABLE #tempInfo
(
DocNo VARCHAR(50),
ResultFlag nVARCHAR(20),
buyer nVARCHAR(20),
CopyDate DATETIME,
IS3 INT,
IS14 INT
)
ELSE
TRUNCATE TABLE #tempInfo
INSERT INTO #tempInfo--三天数据
        ( DocNo, ResultFlag,buyer,CopyDate,IS3,IS14 )
		SELECT DocNo
,CASE WHEN ResultFlag='齐套' THEN ResultFlag ELSE '缺料' END
,Buyer
,CopyDate,CASE WHEN ActualReqDate<DATEADD(DAY,2,CopyDate) THEN 1 ELSE 0 END ,1 FROM dbo.Auctus_FullSetCheckResult8
WHERE CopyDate BETWEEN @SD AND @ED AND MRPCategory<>'内部生产'
AND MRPCategory IN ('电子','结构','包材','配件')
AND CASE WHEN (MRPCategory='包材' OR MRPCategory='配件')AND ActualReqDate>CopyDate  THEN 1 ELSE 0 END<>1
AND ActualReqDate<DATEADD(DAY,13,CopyDate)

INSERT INTO #tempInfo--三天数据
SELECT 
a.DocNo,CASE WHEN a.ResultFlag='齐套' THEN a.ResultFlag ELSE '缺料' END,c1.Name,a.CopyDate
,CASE WHEN ActualReqDate<DATEADD(DAY,2,CopyDate) THEN 1 ELSE 0 END ,1
FROM dbo.Auctus_FullSetCheckResult8 a LEFT JOIN dbo.CBO_ItemMaster b ON a.ProductID=b.ID
LEFT JOIN dbo.CBO_Operators c ON b.DescFlexField_PrivateDescSeg24=c.Code LEFT JOIN dbo.CBO_Operators_Trl c1 ON c.ID=c1.ID
WHERE CopyDate BETWEEN @SD AND @ED AND a.MRPCategory<>'内部生产' AND b.DescFlexField_PrivateDescSeg22 NOT IN ('MRP104','MRP105','MRP106','MRP113')
AND CASE WHEN (a.MRPCategory='包材' OR a.MRPCategory='配件')AND a.ActualReqDate>a.CopyDate  THEN 1 ELSE 0 END=0
AND ActualReqDate<DATEADD(DAY,13,CopyDate)

--齐套率=齐套工单数/总工单数

--每人对应总工单数
--SELECT a.buyer,COUNT(DISTINCT a.DocNo)MoTotal,a.CopyDate FROM #tempInfo a GROUP BY a.buyer,a.copydate

--找每个人不齐套工单数
;
WITH data1 AS
(
SELECT a.buyer,a.DocNo,a.CopyDate FROM #tempInfo a WHERE a.IS3=1 GROUP BY a.buyer,a.DocNo,a.CopyDate
),
data2 AS
(
SELECT DISTINCT a.DocNo,a.CopyDate,a.buyer FROM #tempInfo a  WHERE a.ResultFlag='缺料' AND a.IS3=1
),
data3 AS
(
SELECT a.*,'缺料' Flag  FROM data1 a LEFT JOIN data2 b ON a.DocNo=b.DocNo AND a.buyer=b.buyer AND a.CopyDate=b.CopyDate WHERE b.DocNo IS NOT NULL
),
MOTotal AS
(
SELECT a.buyer,COUNT(DISTINCT a.DocNo)MoTotal,a.CopyDate FROM #tempInfo a WHERE a.IS3=1 GROUP BY a.buyer,a.CopyDate
),
data4 AS
(
SELECT a.buyer,COUNT(a.buyer)MOLackCount,a.CopyDate FROM data3 a GROUP BY a.buyer,a.CopyDate
),
Result AS
(
SELECT a.*,b.MOLackCount,a.MoTotal-ISNULL(b.MOLackCount,0) FullSetCount 
FROM MOTotal a LEFT JOIN data4 b ON a.buyer=b.buyer AND a.CopyDate=b.CopyDate
),
data114 AS
(
SELECT a.buyer,a.DocNo,a.CopyDate FROM #tempInfo a WHERE a.IS14=1 GROUP BY a.buyer,a.DocNo,a.CopyDate
),
data214 AS
(
SELECT DISTINCT a.DocNo,a.CopyDate,a.buyer FROM #tempInfo a  WHERE a.ResultFlag='缺料' AND a.IS14=1
),
data314 AS
(
SELECT a.*,'缺料' Flag  FROM data114 a LEFT JOIN data214 b ON a.DocNo=b.DocNo AND a.buyer=b.buyer AND a.CopyDate=b.CopyDate WHERE b.DocNo IS NOT NULL
),
MOTotal14 AS
(
SELECT a.buyer,COUNT(DISTINCT a.DocNo)MoTotal,a.CopyDate FROM #tempInfo a WHERE a.IS14=1 GROUP BY a.buyer,a.CopyDate
),
data414 AS
(
SELECT a.buyer,COUNT(a.buyer)MOLackCount,a.CopyDate FROM data314 a GROUP BY a.buyer,a.CopyDate
),
Result14 AS
(
SELECT a.*,b.MOLackCount,a.MoTotal-ISNULL(b.MOLackCount,0) FullSetCount 
FROM MOTotal14 a LEFT JOIN data414 b ON a.buyer=b.buyer AND a.CopyDate=b.CopyDate
),
datas AS
(
SELECT 
a.DocNo,a.IsLack,a.CopyDate,CASE WHEN a.IsLack='缺料' THEN 1 ELSE 0 END flag
--,CASE WHEN a.MRPCategory='包材'AND a.ActualReqDate>a.CopyDate  THEN 1 ELSE 0 END
--,a.MRPCategory,a.ActualReqDate
--,a.* 
FROM dbo.Auctus_FullSetCheckResult8 a 
WHERE CopyDate BETWEEN @SD AND @ED AND a.MRPCategory<>'内部生产' 
AND ActualReqDate<DATEADD(DAY,2,CopyDate)
--AND CASE WHEN a.MRPCategory='包材'AND a.ActualReqDate>a.CopyDate  THEN 1 ELSE 0 END=0
),
datas14 AS
(
SELECT 
a.DocNo,a.IsLack,a.CopyDate,CASE WHEN a.IsLack='缺料' THEN 1 ELSE 0 END flag
FROM dbo.Auctus_FullSetCheckResult8 a 
WHERE CopyDate BETWEEN @SD AND @ED AND a.MRPCategory<>'内部生产' 
AND ActualReqDate<DATEADD(DAY,13,CopyDate)
),
Docs AS
(
SELECT COUNT(DISTINCT docno)totalNo,a.CopyDate FROM dbo.Auctus_FullSetCheckResult8 a 
WHERE CopyDate BETWEEN @SD AND @ED AND a.MRPCategory<>'内部生产' 
AND ActualReqDate<DATEADD(DAY,2,CopyDate)
GROUP BY a.CopyDate
),
UnLackDocs AS
(
SELECT COUNT(t.DocNo)UnLackCount,t.CopyDate FROM 
(SELECT a.DocNo,a.CopyDate FROM datas a GROUP BY a.DocNo,a.CopyDate HAVING SUM(flag)=0) t GROUP BY t.CopyDate
),
Docs14 AS
(
SELECT COUNT(DISTINCT docno)totalNo,a.CopyDate FROM dbo.Auctus_FullSetCheckResult8 a 
WHERE CopyDate BETWEEN @SD AND @ED AND a.MRPCategory<>'内部生产' 
AND ActualReqDate<DATEADD(DAY,13,CopyDate)
GROUP BY a.CopyDate
),
UnLackDocs14 AS
(
SELECT COUNT(t.DocNo)UnLackCount,t.CopyDate FROM 
(SELECT a.DocNo,a.CopyDate FROM datas14 a GROUP BY a.DocNo,a.CopyDate HAVING SUM(flag)=0) t GROUP BY t.CopyDate
)
SELECT a.buyer,a.MoTotal,FORMAT(a.CopyDate,'yyyy-MM-dd')CopyDate,ISNULL(a.MOLackCount,0)MOLackCount,a.FullSetCount,CONVERT(DECIMAL(18,2),a.FullSetCount/CONVERT(DECIMAL(18,4),a.MoTotal)*100) Rate 
FROM Result a
--ORDER BY a.CopyDate,a.buyer
UNION ALL
SELECT '三天齐套率',a.totalNo,FORMAT(a.CopyDate,'yyyy-MM-dd')CopyDate,a.totalNo-ISNULL(b.UnLackCount,0) MOLackCount,ISNULL(b.UnLackCount,0)FullSetCount,FORMAT(b.UnLackCount/CONVERT(DECIMAL(18,4),a.totalNo)*100,'##.##') Rate
FROM Docs a LEFT JOIN UnLackDocs b ON a.CopyDate=b.CopyDate
UNION ALL
SELECT '14天齐套率',a.totalNo,FORMAT(a.CopyDate,'yyyy-MM-dd')CopyDate,a.totalNo-ISNULL(b.UnLackCount,0) MOLackCount,ISNULL(b.UnLackCount,0)FullSetCount,FORMAT(b.UnLackCount/CONVERT(DECIMAL(18,4),a.totalNo)*100,'##.##') Rate
FROM Docs14 a LEFT JOIN UnLackDocs14 b ON a.CopyDate=b.CopyDate
UNION ALL
SELECT a.buyer+'_14',a.MoTotal,FORMAT(a.CopyDate,'yyyy-MM-dd')CopyDate,ISNULL(a.MOLackCount,0)MOLackCount,a.FullSetCount,CONVERT(DECIMAL(18,2),a.FullSetCount/CONVERT(DECIMAL(18,4),a.MoTotal)*100) Rate 
FROM Result14 a
ORDER BY CopyDate

END





