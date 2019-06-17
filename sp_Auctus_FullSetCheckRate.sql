
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
*/
ALTER PROC [dbo].[sp_Auctus_FullSetCheckRate]
(
@Org BIGINT,
@SD DATETIME,
@ED DATETIME
)
AS
BEGIN
--按执行采购、工单
IF OBJECT_ID(N'tempdb.dbo.#tempInfo',N'U') IS NULL
CREATE TABLE #tempInfo
(
DocNo VARCHAR(50),
ResultFlag nVARCHAR(20),
buyer nVARCHAR(20),
CopyDate DATETIME
)
ELSE
TRUNCATE TABLE #tempInfo
INSERT INTO #tempInfo
        ( DocNo, ResultFlag, buyer,CopyDate )
		SELECT DocNo
,CASE WHEN FixedLT<3 AND ResultFlag='缺料' AND DATEADD(DAY,(-1)*FixedLT,ActualReqDate)>CopyDate THEN '齐套'
ELSE ResultFlag END ResultFlag2
,CASE WHEN PATINDEX('%试产%',DocType)>0 THEN '试产工单' 
WHEN PATINDEX('%功放%',ProductLine)>0 THEN '功放工单'
ELSE buyer END buyer
--,Buyer
,CopyDate FROM dbo.Auctus_FullSetCheckResult
WHERE CopyDate BETWEEN @SD AND @ED AND MRPCategory<>'内部生产'
AND CASE WHEN MRPCategory='包材'AND ActualReqDate>CopyDate  THEN 1 ELSE 0 END<>1

--齐套率=齐套工单数/总工单数

--每人对应总工单数
--SELECT a.buyer,COUNT(DISTINCT a.DocNo)MoTotal,a.CopyDate FROM #tempInfo a GROUP BY a.buyer,a.copydate

--找每个人不齐套工单数
;
WITH data1 AS
(
SELECT a.buyer,a.DocNo,a.CopyDate FROM #tempInfo a GROUP BY a.buyer,a.DocNo,a.CopyDate
),
data2 AS
(
SELECT DISTINCT a.DocNo,a.CopyDate,a.buyer FROM #tempInfo a WHERE a.ResultFlag='缺料'
),
data3 AS
(
SELECT a.*,'缺料' Flag  FROM data1 a LEFT JOIN data2 b ON a.DocNo=b.DocNo AND a.buyer=b.buyer AND a.CopyDate=b.CopyDate WHERE b.DocNo IS NOT NULL
),
MOTotal AS
(
SELECT a.buyer,COUNT(DISTINCT a.DocNo)MoTotal,a.CopyDate FROM #tempInfo a GROUP BY a.buyer,a.CopyDate
),
data4 AS
(
SELECT a.buyer,COUNT(a.buyer)MOLackCount,a.CopyDate FROM data3 a GROUP BY a.buyer,a.CopyDate
),
Result AS
(
SELECT a.*,b.MOLackCount,a.MoTotal-ISNULL(b.MOLackCount,0) FullSetCount FROM MOTotal a LEFT JOIN data4 b ON a.buyer=b.buyer AND a.CopyDate=b.CopyDate
)
SELECT a.buyer,a.MoTotal,CONVERT(CHAR(10),a.CopyDate,121)CopyDate,ISNULL(a.MOLackCount,0)MOLackCount,a.FullSetCount,CONVERT(DECIMAL(18,2),a.FullSetCount/CONVERT(DECIMAL(18,4),a.MoTotal)*100) Rate FROM Result a
ORDER BY a.CopyDate,a.buyer

END





