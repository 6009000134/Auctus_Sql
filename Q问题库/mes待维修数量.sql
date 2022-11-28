
--´ýÎ¬ÐÞÊýÁ¿
;
WITH data1
AS
(
SELECT * FROM dbo.mxqh_MoPlanCount WHERE PlanDate='2020-03-31'
)
SELECT b.InternalCode,b.AssemblyPlanDetailID,a.ProcedureID,a.IsRepair
FROM dbo.opPlanExecutDetail a INNER JOIN dbo.opPlanExecutMain b ON a.PlanExecutMainID=b.ID
INNER JOIN dbo.mxqh_plAssemblyPlanDetail c ON b.AssemblyPlanDetailID=c.ID
INNER JOIN data1 d ON c.WorkOrder=d.WorkOrder
WHERE a.ExtendOne='0'
AND a.IsRepair=1
UNION ALL
SELECT b.InternalCode,b.AssemblyPlanDetailID,a.ProcedureID,a.IsRepair
FROM dbo.opPlanExecutDetailHH a INNER JOIN dbo.opPlanExecutMainHH b ON a.PlanExecutMainID=b.ID
INNER JOIN dbo.mxqh_plAssemblyPlanDetail c ON b.AssemblyPlanDetailID=c.ID
INNER JOIN data1 d ON c.WorkOrder=d.WorkOrder
WHERE a.ExtendOne='0'
AND a.IsRepair=1
UNION ALL
SELECT b.InternalCode,b.AssemblyPlanDetailID,a.ProcedureID,a.IsRepair
FROM dbo.opPlanExecutDetailPK a INNER JOIN dbo.opPlanExecutMainPK b ON a.PlanExecutMainID=b.ID
INNER JOIN dbo.mxqh_plAssemblyPlanDetail c ON b.AssemblyPlanDetailID=c.ID
INNER JOIN data1 d ON c.WorkOrder=d.WorkOrder
WHERE a.ExtendOne='0'
AND a.IsRepair=1


SELECT a.WorOrder,a.BarCode,a.ProcedureID FROM dbo.qlBadAcquisition a
WHERE a.IsNgLog=1
GROUP BY a.WorOrder,a.BarCode,a.ProcedureID
HAVING COUNT(1)>1

SELECT * FROM dbo.qlBadAcquisition a 
WHERE a.WorOrder='4139' AND a.BarCode='2051545ARBS' AND a.ProcedureID=29

