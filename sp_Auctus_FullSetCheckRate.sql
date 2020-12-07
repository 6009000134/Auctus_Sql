USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_FullSetCheckRate]    Script Date: 2020/5/7 17:56:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
update(2020-4-7)
内部生产拆分为：包装、组装、后焊、功放、前加工

--Add By Daniel 2020-04-24
1.增加包材2天齐套率数据推送-----（考核指标：100%为达成）；对应责任人：蔡晓婷；
2.调整包材3天齐套率数据推送-----（考核指标：90%为达成），对应责任人：蔡晓婷；
5.调整采购两周齐套率数据推送-----（考核指标：85%为达成）；对应责任人为：贺群花（数据来源包材3天+电子、结构两周数据）；
6.调整采购三天齐套率数据推送-----（考核指标：99%为达成）；对应责任人为：贺群花（数据来源包材2天+电子、结构3天数据）；
注：执行采购所考虑的工单齐套率指所有物料分配的所有工单，但不包括内部生产工单；

exec  sp_Auctus_FullSetCheckRate1 null,'2020-04-24','2020-04-27'
*/
ALTER PROC [dbo].[sp_Auctus_FullSetCheckRate]
(
	@Org BIGINT,
	@SD DATETIME,
	@ED DATETIME
)
AS
BEGIN
--DECLARE @Org BIGINT,@SD DATETIME='2020-5-6',@ED DATETIME='2020-5-9'
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
	IS14 INT,
	MType VARCHAR(50)
)
ELSE
TRUNCATE TABLE #tempInfo


--最终结果集合
IF OBJECT_ID(N'tempdb.dbo.#tempResult',N'U') IS NULL
CREATE TABLE #tempResult
(
	buyer VARCHAR(50),
	MoTotal INT,
	CopyDate DATE,
	MOLackCount INT,
	FullSetCount INT,
	Rate VARCHAR(50)	
)
ELSE
TRUNCATE TABLE #tempResult




INSERT INTO #tempInfo--包材、配件
        ( DocNo, ResultFlag,buyer,CopyDate,IS3,IS14,MType )
		SELECT DocNo
,CASE WHEN ResultFlag='齐套' THEN ResultFlag ELSE '缺料' END
,Buyer
,CopyDate,CASE WHEN ActualReqDate<DATEADD(DAY,1,CopyDate) THEN 1 ELSE 0 END ,1 ,'采购'
FROM dbo.Auctus_FullSetCheckResult8
WHERE CopyDate BETWEEN @SD AND @ED --AND MRPCategory NOT IN ('包装','组装','后焊','功放','前加工')
AND MRPCategory IN ('包材','配件')
--AND CASE WHEN (MRPCategory='包材' OR MRPCategory='配件')AND ActualReqDate>CopyDate  THEN 1 ELSE 0 END<>1
AND ActualReqDate<DATEADD(DAY,2,CopyDate)


INSERT INTO #tempInfo--电子、结构
        ( DocNo, ResultFlag,buyer,CopyDate,IS3,IS14,MType )
		SELECT DocNo
,CASE WHEN ResultFlag='齐套' THEN ResultFlag ELSE '缺料' END
,Buyer
,CopyDate,CASE WHEN ActualReqDate<DATEADD(DAY,2,CopyDate) THEN 1 ELSE 0 END ,1 ,'采购'
FROM dbo.Auctus_FullSetCheckResult8
WHERE CopyDate BETWEEN @SD AND @ED --AND MRPCategory NOT IN ('包装','组装','后焊','功放','前加工')
AND MRPCategory IN ('电子','结构')
--AND CASE WHEN (MRPCategory='包材' OR MRPCategory='配件')AND ActualReqDate>CopyDate  THEN 1 ELSE 0 END<>1
AND ActualReqDate<DATEADD(DAY,13,CopyDate)



INSERT INTO #tempInfo--非内部生产料品
SELECT 
a.DocNo,CASE WHEN a.ResultFlag='齐套' THEN a.ResultFlag ELSE '缺料' END,c1.Name,a.CopyDate
,CASE WHEN ActualReqDate<DATEADD(DAY,2,CopyDate) THEN 1 ELSE 0 END ,1,'PMC'
FROM dbo.Auctus_FullSetCheckResult8 a LEFT JOIN dbo.CBO_ItemMaster b ON a.ProductID=b.ID
LEFT JOIN dbo.CBO_Operators c ON b.DescFlexField_PrivateDescSeg24=c.Code LEFT JOIN dbo.CBO_Operators_Trl c1 ON c.ID=c1.ID
WHERE CopyDate BETWEEN @SD AND @ED 
AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工')--备料单中内部生产的不考虑
AND b.DescFlexField_PrivateDescSeg22 NOT IN ('MRP104','MRP105','MRP106','MRP113')--过滤一些芯片工单
AND CASE WHEN (a.MRPCategory='包材' OR a.MRPCategory='配件')AND a.ActualReqDate>a.CopyDate  THEN 1 ELSE 0 END=0--包材、配件取1天数据
AND ActualReqDate<DATEADD(DAY,13,CopyDate)

--齐套率=齐套工单数/总工单数

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
WHERE CopyDate BETWEEN @SD AND @ED AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工')
AND ActualReqDate<DATEADD(DAY,2,CopyDate)
--AND CASE WHEN a.MRPCategory='包材'AND a.ActualReqDate>a.CopyDate  THEN 1 ELSE 0 END=0
),
datas14 AS
(
SELECT 
a.DocNo,a.IsLack,a.CopyDate,CASE WHEN a.IsLack='缺料' THEN 1 ELSE 0 END flag
FROM dbo.Auctus_FullSetCheckResult8 a 
WHERE CopyDate BETWEEN @SD AND @ED AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工')
AND ActualReqDate<DATEADD(DAY,13,CopyDate)
),
Docs AS
(
SELECT COUNT(DISTINCT docno)totalNo,a.CopyDate FROM dbo.Auctus_FullSetCheckResult8 a 
WHERE CopyDate BETWEEN @SD AND @ED AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工') 
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
WHERE CopyDate BETWEEN @SD AND @ED AND a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工')
AND ActualReqDate<DATEADD(DAY,13,CopyDate)
GROUP BY a.CopyDate
),
UnLackDocs14 AS
(
SELECT COUNT(t.DocNo)UnLackCount,t.CopyDate FROM 
(SELECT a.DocNo,a.CopyDate FROM datas14 a GROUP BY a.DocNo,a.CopyDate HAVING SUM(flag)=0) t GROUP BY t.CopyDate
)
INSERT INTO #tempResult
        ( buyer ,
          MoTotal ,
          CopyDate ,
          MOLackCount ,
          FullSetCount ,
          Rate
        )
SELECT CASE WHEN a.buyer='蔡晓婷' THEN '蔡晓婷_2' else a.buyer END
,a.MoTotal,FORMAT(a.CopyDate,'yyyy-MM-dd')CopyDate,ISNULL(a.MOLackCount,0)MOLackCount,a.FullSetCount,CONVERT(DECIMAL(18,2),a.FullSetCount/CONVERT(DECIMAL(18,4),a.MoTotal)*100) Rate 
FROM Result a
--ORDER BY a.CopyDate,a.buyer
UNION ALL
SELECT '三天齐套率',a.totalNo,FORMAT(a.CopyDate,'yyyy-MM-dd')CopyDate,a.totalNo-ISNULL(b.UnLackCount,0) MOLackCount,ISNULL(b.UnLackCount,0)FullSetCount,FORMAT(b.UnLackCount/CONVERT(DECIMAL(18,4),a.totalNo)*100,'##.##') Rate
FROM Docs a LEFT JOIN UnLackDocs b ON a.CopyDate=b.CopyDate
UNION ALL
SELECT '14天齐套率',a.totalNo,FORMAT(a.CopyDate,'yyyy-MM-dd')CopyDate,a.totalNo-ISNULL(b.UnLackCount,0) MOLackCount,ISNULL(b.UnLackCount,0)FullSetCount,FORMAT(b.UnLackCount/CONVERT(DECIMAL(18,4),a.totalNo)*100,'##.##') Rate
FROM Docs14 a LEFT JOIN UnLackDocs14 b ON a.CopyDate=b.CopyDate
UNION ALL
SELECT CASE WHEN a.buyer='蔡晓婷' THEN '蔡晓婷_3' else a.buyer+'_14' END 
,a.MoTotal,FORMAT(a.CopyDate,'yyyy-MM-dd')CopyDate,ISNULL(a.MOLackCount,0)MOLackCount,a.FullSetCount,CONVERT(DECIMAL(18,2),a.FullSetCount/CONVERT(DECIMAL(18,4),a.MoTotal)*100) Rate 
FROM Result14 a
--ORDER BY CopyDate


--,'包材','配件'

END

 

 

 
;WITH data1 AS
(
SELECT a.DocNo,a.ResultFlag,a.CopyDate FROM #tempInfo a WHERE a.IS3=1 AND a.MType='采购'
),
TotalCount as
(
SELECT COUNT(DISTINCT a.docno)MoTotal,a.CopyDate  FROM data1 a GROUP BY a.CopyDate
),
LackCount AS
(
SELECT COUNT(DISTINCT a.docNo)MOLackCount,a.CopyDate  FROM data1 a WHERE a.ResultFlag='缺料' GROUP BY a.CopyDate
),
data14 AS
(
SELECT a.DocNo,a.ResultFlag,a.CopyDate FROM #tempInfo a WHERE a.IS14=1 AND a.MType='采购'
),
TotalCount14 as
(
SELECT COUNT(DISTINCT a.docno)MoTotal,a.CopyDate  FROM data14 a GROUP BY a.CopyDate
),
LackCount14 AS
(
SELECT COUNT(DISTINCT a.docNo)MOLackCount,a.CopyDate  FROM data14 a WHERE a.ResultFlag='缺料' GROUP BY a.CopyDate
)
INSERT INTO #tempResult
        ( buyer ,
          MoTotal ,
          CopyDate ,
          MOLackCount ,
          FullSetCount ,
          Rate
        )
SELECT '采购_3天'buyer,a.MoTotal,FORMAT(a.CopyDate,'yyyy-MM-dd'),ISNULL(b.MOLackCount,0)MOLackCount,a.MoTotal-ISNULL(b.MOLackCount,0)FullSetCount
,FORMAT((a.MoTotal-ISNULL(b.MOLackCount,0))/CONVERT(DECIMAL(18,4),a.MoTotal)*100.00,'#.##')+'%'Rate
FROM TotalCount a LEFT JOIN LackCount b ON a.CopyDate=b.CopyDate
UNION ALL
SELECT '采购_14天'buyer,a.MoTotal,FORMAT(a.CopyDate,'yyyy-MM-dd'),ISNULL(b.MOLackCount,0)MOLackCount,a.MoTotal-ISNULL(b.MOLackCount,0)FullSetCount
,FORMAT((a.MoTotal-ISNULL(b.MOLackCount,0))/CONVERT(DECIMAL(18,4),a.MoTotal)*100.00,'#.##')+'%'Rate
FROM TotalCount14 a LEFT JOIN LackCount14 b ON a.CopyDate=b.CopyDate
--ORDER BY a.CopyDate

SELECT * FROM #tempResult
ORDER BY CopyDate

 
