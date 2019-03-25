/*
MRP及时下单率
*/
ALTER PROC sp_Auctus_MRPRate
(
@Org BIGINT,
@StartDate DATE,
@EndDate DATE
)
AS
BEGIN  
--DECLARE @StartDate DATE
--DECLARE @EndDate DATE
--SET @StartDate='2018-07-01'
--SET @EndDate='2018-09-10'
SET @EndDate=DATEADD(DAY,1,@EndDate)
;
WITH TurnPR AS
(
SELECT COUNT(a.ID)PRCount,CONVERT(DATE,a.CopyDate)cd FROM dbo.Auctus_MRP_PlanOrder a LEFT JOIN dbo.MRP_PlanOrderConsumption b  ON a.ID=b.PlanOrder
WHERE b.id IS NOT NULL AND a.CopyDate>=@StartDate AND a.CopyDate<@EndDate
GROUP BY CONVERT(DATE,a.CopyDate)
),
Total AS
(
SELECT COUNT(a.ID)TotalCount,CONVERT(DATE,a.CopyDate)cd FROM dbo.Auctus_MRP_PlanOrder a LEFT JOIN dbo.MRP_PlanOrderConsumption b  ON a.ID=b.PlanOrder
WHERE a.CopyDate>=@StartDate AND a.CopyDate<@EndDate
GROUP BY CONVERT(DATE,a.CopyDate)
)
SELECT DATEADD(DAY,-1,a.cd)日期,a.TotalCount MRP总记录数,b.PRCount 下单条数,CONVERT(VARCHAR(50),CONVERT(DECIMAL(18,2),b.PRCount/CONVERT(DECIMAL(18,4),a.TotalCount)*100))+'%' 下单及时率 FROM  Total a LEFT JOIN TurnPR b ON a.cd=b.cd

END

