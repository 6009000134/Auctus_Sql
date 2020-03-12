/*
u9创建完工报告时，通过此存储过程来校验mes完工数量与U9是否一致
*/
ALTER PROC [dbo].[sp_GetCompleteQty]
(
@WorkOrder VARCHAR(30)
)
AS
BEGIN
--DECLARE @WorkOrder VARCHAR(30)='AMO-30190814060'
--DECLARE @WorkOrder VARCHAR(30)='MO-30191113001'
--DECLARE @WorkOrder VARCHAR(30)='HMO-30191217005'
--DECLARE @WorkOrder VARCHAR(30)='AMO-30191120009'
DECLARE @WorkOrderID INT=(SELECT id FROM dbo.mxqh_plAssemblyPlanDetail WHERE WorkOrder=@WorkOrder)
IF EXISTS(SELECT 1 FROM dbo.opPackageMain a INNER JOIN dbo.opPackageDetail b ON a.ID=b.PackMainID INNER JOIN dbo.opPackageChild c ON b.ID=c.PackDetailID
WHERE a.AssemblyPlanDetailID=@WorkOrderID)
BEGIN
	SELECT COUNT(1)CompleteQty FROM dbo.opPackageMain a INNER JOIN dbo.opPackageDetail b ON a.ID=b.PackMainID INNER JOIN dbo.opPackageChild c ON b.ID=c.PackDetailID
	WHERE a.AssemblyPlanDetailID=@WorkOrderID
	RETURN;
END 

--组装工单,取上线最后一个工序通过数量
IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMain a WHERE a.AssemblyPlanDetailID=@WorkOrderID)
BEGIN 
	SELECT ISNULL(COUNT(t.IsPass),0)CompleteQty FROM
	(
	SELECT ROW_NUMBER()OVER(PARTITION BY a.InternalCode ORDER BY c.OrderNum desc)RN,c.IsPass
	FROM dbo.opPlanExecutMain a INNER JOIN dbo.opPlanExecutDetail c ON a.ID=c.PlanExecutMainID
	--INNER JOIN dbo.opPlanExecutChild d ON c.ID=d.PlanExecutDetailID
	WHERE a.AssemblyPlanDetailID=@WorkOrderID AND c.ExtendOne=0
	) t WHERE t.RN=1 AND t.IsPass=1
	RETURN;
END 
--后焊工单完工信息
IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMainHH a WHERE a.AssemblyPlanDetailID=@WorkOrderID)
BEGIN
	SELECT ISNULL(COUNT(t.IsPass),0)CompleteQty FROM
	(
	SELECT ROW_NUMBER()OVER(PARTITION BY a.InternalCode ORDER BY c.OrderNum desc)RN,c.IsPass
	FROM dbo.opPlanExecutMainHH a INNER JOIN dbo.opPlanExecutDetailHH c ON a.ID=c.PlanExecutMainID
	--INNER JOIN dbo.opPlanExecutChild d ON c.ID=d.PlanExecutDetailID
	WHERE a.AssemblyPlanDetailID=@WorkOrderID AND c.ExtendOne=0
	) t WHERE t.RN=1 AND t.IsPass=1
	RETURN;
END 

--完工报告数量
SELECT 	ISNULL(SUM(a.CompleteQty),0)CompleteQty
FROM dbo.mxqh_CompleteRpt a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrderID=b.ID
WHERE a.WorkOrder=@WorkOrder

END 