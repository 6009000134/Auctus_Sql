--备份供需资料数据
--CREATE PROC sp_Auctus_BackUpMRP_DSInfo
--(
--@Org BIGINT
--)
--AS
--BEGIN 
DECLARE @Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='300')
DECLARE @Date DATETIME=GETDATE()
DECLARE @RN INT =(SELECT MAX(RN)+1 FROM auctus_MRP_DSINFO)

--判定是否由跑MRP需求
;
WITH et AS
(
SELECT a.planversion,MAX(a.endtime)endtime FROM auctus_MRP_DSINFO a
GROUP BY a.planversion,a.endtime
),
et2 AS
(
SELECT b.ID,ISNULL(b.EndTime,GETDATE())endtime FROM dbo.MRP_PlanName a INNER JOIN dbo.MRP_PlanVersion b ON a.ID=b.PlanName
WHERE a.Org=@Org
),
etResult AS
(
SELECT  a.ID,a.endtime FROM et2 a INNER JOIN et b ON a.ID=b.planversion AND b.endtime>a.endtime
)
SELECT a.*,b.EndTime,@Date,@RN FROM dbo.MRP_DSInfo a inner JOIN dbo.MRP_PlanVersion b ON a.PlanVersion=b.ID INNER JOIN dbo.MRP_PlanName c ON b.PlanName=c.ID 
INNER JOIN etResult d ON b.ID=d.ID
WHERE c.Org=1001708020135665 AND a.DemandDate<DATEADD(DAY,56,GETDATE())

IF EXISTS(SELECT 0 FROM auctus_MRP_DSINFO WHERE RN=@RN)--说明有插入新数据


-- INSERT INTO   Auctus_MRP_DSInfo  SELECT a.*,b.EndTime,@Date FROM dbo.MRP_DSInfo a inner JOIN dbo.MRP_PlanVersion b ON a.PlanVersion=b.ID INNER JOIN dbo.MRP_PlanName c ON b.PlanName=c.ID 
--WHERE c.Org=1001708020135665 AND a.DemandDate<DATEADD(DAY,56,GETDATE())

--END 

--SELECT * FROM auctus_MRP_DSINFO
--DROP TABLE auctus_MRP_DSINFO

