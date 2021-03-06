USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_TimeRateOfMO]    Script Date: 2018/8/14 10:15:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
工单结案及时率报表 2018.06.08
*/
ALTER PROC [dbo].[sp_Auctus_TimeRateOfMO]
(
@Org BIGINT,--组织
@DisplayName VARCHAR(50)--期间
)
AS 
BEGIN
DECLARE @StartDate DATETIME--开始时间
DECLARE @EndDate DATETIME--结束时间
--结果集表参数
DECLARE @result TABLE(DocNo VARCHAR(50),AcDate DATETIME,ActualCompleteDate DATETIME,AcTime DATETIME,DiffResult INT,Flag DECIMAL(18,4))
SET @StartDate=@DisplayName+'-01'
SET @EndDate=DATEADD(MONTH,1,@StartDate)


;
WITH data1 AS--未关闭但已完工，即无业务结束时间，但是完工数量和生产数量相等的工单
(
SELECT a.DocNo,MAX(ISNULL(a.ActualCompleteDate,GETDATE()))AcDate,MAX(a.ActualCompleteDate)ActualCompleteDate,MAX(b.ActualRcvTime)AcTime 
FROM mo_mo a LEFT JOIN dbo.MO_CompleteRpt b ON a.ID=b.MO
WHERE (a.DocState<>3 OR a.ActualCompleteDate>@EndDate)--未关闭工单无业务结束时间
AND a.CreatedOn<@EndDate--考核之前开的工单
AND b.ActualRcvTime<@EndDate
AND a.Org=@Org
GROUP BY a.DocNo
HAVING MAX(ISNULL(a.ProductQty,0))=SUM(ISNULL(b.CompleteQty,0))
),
data2 AS--当月关闭
(
SELECT a.DocNo,MAX(a.ActualCompleteDate)AcDate,MAX(a.ActualCompleteDate)ActualCompleteDate,MAX(b.ActualRcvTime)AcTime 
FROM dbo.MO_MO a LEFT JOIN dbo.MO_CompleteRpt b ON a.ID=b.MO
WHERE a.DocState=3 AND a.CreatedOn<@EndDate AND a.ActualCompleteDate >= @StartDate AND a.ActualCompleteDate<@EndDate
AND a.Org=@Org
GROUP BY a.DocNo
),
data3 AS--合并结果集 
(
SELECT * FROM data1
UNION
SELECT * FROM data2
),
Result AS
(
SELECT *,DATEDIFF(DAY,AcTime,acdate)DiffResult,CASE WHEN DATEDIFF(DAY,AcTime,acdate)>3 THEN 0.0000 ELSE 1.0000 END Flag  FROM data3 
)
INSERT INTO @result
SELECT * FROM Result 
SELECT * FROM @result a ORDER BY DiffResult DESC,a.AcDate desc
END











