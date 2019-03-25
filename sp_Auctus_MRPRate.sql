/*
MRP��ʱ�µ���
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
SELECT DATEADD(DAY,-1,a.cd)����,a.TotalCount MRP�ܼ�¼��,b.PRCount �µ�����,CONVERT(VARCHAR(50),CONVERT(DECIMAL(18,2),b.PRCount/CONVERT(DECIMAL(18,4),a.TotalCount)*100))+'%' �µ���ʱ�� FROM  Total a LEFT JOIN TurnPR b ON a.cd=b.cd

END

