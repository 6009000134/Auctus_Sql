--校验U9完工数量与MES完工数量是否一致
CREATE PROC sp_U9BE_CheckCompleteQty
(
@U9CompleteQty INT,
@WorkOrder VARCHAR(30)
)
AS
BEGIN
--DECLARE @U9CompleteQty INT=1000
--DECLARE @WorkOrder VARCHAR(30)='AMO-30190814060'
DECLARE @WorkOrderID INT
SELECT @WorkOrderID=a.ID FROM dbo.mxqh_plAssemblyPlanDetail a WHERE a.WorkOrder=@WorkOrder
SELECT COUNT(*) FROM 
(
SELECT ROW_NUMBER()OVER(PARTITION BY a.InternalCode ORDER BY b.OrderNum desc)RN,a.InternalCode,b.IsPass 
FROM dbo.opPlanExecutMain a INNER JOIN dbo.opPlanExecutDetail b ON a.ID=b.PlanExecutMainID 
WHERE a.AssemblyPlanDetailID=@WorkOrderID AND b.ExtendOne=0
)t WHERE t.RN=1 AND t.IsPass=1

END 